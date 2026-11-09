import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'backup.dart';
import 'db.dart';
import 'export.dart';
import 'i18n.dart';
import 'icons.dart';
import 'notify.dart';
import 'screens/accounts_screen.dart';
import 'screens/agenda_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/more_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/ops_screen.dart';
import 'security.dart';
import 'shortcuts.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets/quick_sheet.dart';
import 'widgets/sheets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  // The phone's language until the saved choice is read by state.load().
  useLang(resolveLang('auto'));
  // The lock state is read before the first frame so data never flashes on screen.
  final lock = LockService();
  await lock.load();
  final state = AppState(Store());
  final backup = DriveBackup(state, lock);
  final notifier = Notifier(state, backup, lock);
  final shortcuts = AppShortcuts(state, lock);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: lock),
        ChangeNotifierProvider.value(value: backup),
        ChangeNotifierProvider.value(value: notifier),
        Provider.value(value: shortcuts),
      ],
      child: const CarnetApp(),
    ),
  );
  // Everything below is local: no network access at startup.
  await state.load();
  await backup.init();
  // Reminders are optional: a failure here must not stop the rest of startup.
  try {
    await notifier.init();
    if (!lock.locked) unawaited(notifier.askPermissionOnce());
  } catch (e, st) {
    debugPrint('carnet237 notifications disabled: $e\n$st');
  }
  unawaited(shortcuts.init());
  unawaited(cleanExportFiles());
}

/// Covers the whole app (every route) with the lock screen while locked, and
/// tracks background/foreground to re-lock after the chosen delay.
class LockGate extends StatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});
  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  late final LockService lock = context.read<LockService>();
  bool wasLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    wasLocked = lock.locked;
    lock.addListener(_onLock);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    lock.removeListener(_onLock);
    super.dispose();
  }

  void _onLock() {
    // Ask for the notification permission once, when the app is first usable.
    if (!lock.locked && wasLocked != lock.locked) unawaited(context.read<Notifier>().askPermissionOnce());
    wasLocked = lock.locked;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) lock.onPaused();
    if (s == AppLifecycleState.resumed) {
      lock.onResumed();
      // Roll the 14-day reminder window forward; local only.
      unawaited(context.read<Notifier>().reschedule());
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = context.select<LockService, bool>((l) => l.locked);
    return Stack(
      children: [
        // Offstage while locked: the app is neither painted nor exposed to
        // accessibility services behind the lock screen.
        Offstage(offstage: locked, child: widget.child),
        if (locked)
          // Its own navigator, so the lock screen can open dialogs above the
          // app's routes. HeroControllerScope.none: MaterialApp's hero
          // controller belongs to the app's navigator; sharing it with this one
          // broke every later Navigator.push once the lock screen went away.
          Positioned.fill(
            child: HeroControllerScope.none(
              child: Navigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const LockScreen())),
            ),
          ),
      ],
    );
  }
}

class CarnetApp extends StatelessWidget {
  const CarnetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.select<AppState, String>((s) => s.settings.theme);
    final language = context.select<AppState, String>((s) => s.settings.language);
    return MaterialApp(
      onGenerateTitle: (context) => context.l.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      // AppState has already switched `tr` and the intl locale to match.
      locale: Locale(resolveLang(language)),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => LockGate(child: child!),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  int index = 0;
  bool? onboarded;
  // Fades the newly selected tab in without rebuilding the others.
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 220), value: 1);

  @override
  void dispose() {
    _shortcut?.cancel();
    _lock.removeListener(_openPending);
    _state.removeListener(_openPending);
    _fade.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == index) return;
    setState(() => index = i);
    _fade.forward(from: 0);
  }

  // Pages of the bottom bar; the "+" in its middle is an action, not a page.
  List<(String, String)> _tabs(AppLocalizations l) => [('house', l.tabHome), ('list', l.tabJournal), ('chart-pie', l.tabBudget), ('wallet', l.tabAccounts)];

  StreamSubscription<String>? _shortcut;
  late final LockService _lock = context.read<LockService>();
  late final AppState _state = context.read<AppState>();

  /// Quick entry asked for from the launcher shortcut or the widget: opened
  /// once the app is ready, onboarded and unlocked.
  void _openPending() {
    final shortcuts = context.read<AppShortcuts>();
    if (shortcuts.waiting == null || _lock.locked || onboarded != true || !_state.ready) return;
    shortcuts.take();
    _select(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) openQuickEntry(context);
    });
  }

  @override
  void initState() {
    super.initState();
    final lock = context.read<LockService>();
    _shortcut = context.read<AppShortcuts>().pending.stream.listen((_) => _openPending());
    _lock.addListener(_openPending);
    _state.addListener(_openPending);
    // Someone who already set a code has used the app before.
    lock.readPref('onboarded').then((v) {
      if (!mounted) return;
      setState(() => onboarded = v == '1' || lock.hasPin);
      _openPending();
    });
  }

  void showOps() => _select(1);

  String _title(AppLocalizations l) {
    if (index != 0) return _tabs(l)[index].$2;
    final h = DateTime.now().hour;
    return h >= 18 || h < 4 ? l.greetingEvening : l.greetingDay;
  }

  @override
  Widget build(BuildContext context) {
    final ready = context.select<AppState, bool>((s) => s.ready);
    final l = context.l;
    final title = _title(l);
    if (onboarded == null) return Scaffold(backgroundColor: context.c.bg);
    if (onboarded == false) {
      return OnboardingScreen(
        onDone: () {
          context.read<LockService>().writePref('onboarded', '1');
          setState(() => onboarded = true);
        },
      );
    }
    final pages = [HomeScreen(onShowJournal: showOps), const OpsScreen(), BudgetScreen(onShowOps: showOps), AccountsScreen(onShowOps: showOps)];
    final tabs = _tabs(l);
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(title, key: ValueKey(title)),
        ),
        actions: [
          if (index == 0)
            IconButton(
              tooltip: l.agendaTitle,
              icon: Icon(appIcon('calendar')),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgendaScreen())),
            ),
          // Savings, debts, periods, data, security and settings.
          IconButton(
            tooltip: l.tabMore,
            icon: Icon(appIcon('layout-grid')),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => Scaffold(
                  appBar: AppBar(title: Text(ctx.l.tabMore)),
                  body: const MoreScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ready
          // The pages stay alive in the IndexedStack (scroll positions kept);
          // the controller replays a short fade + slide on each tab change.
          ? FadeTransition(
              opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic)),
                child: IndexedStack(index: index, children: pages),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 2 ? index : index + 1,
        animationDuration: const Duration(milliseconds: 350),
        onDestinationSelected: (i) => i == 2 ? (ready ? openTxSheet(context) : null) : _select(i < 2 ? i : i - 1),
        destinations: [
          for (final t in tabs.take(2)) NavigationDestination(icon: Icon(appIcon(t.$1)), label: t.$2),
          // Adding a movement, always one tap away in the middle of the bar.
          NavigationDestination(
            icon: Container(
              width: 48,
              height: 40,
              decoration: BoxDecoration(color: context.c.accent, borderRadius: BorderRadius.circular(14)),
              child: Icon(appIcon('plus'), color: context.c.accentInk, size: 24),
            ),
            label: l.add,
            tooltip: l.newOperation,
          ),
          for (final t in tabs.skip(2)) NavigationDestination(icon: Icon(appIcon(t.$1)), label: t.$2),
        ],
      ),
    );
  }
}
