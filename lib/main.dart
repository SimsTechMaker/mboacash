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
import 'screens/categories_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/more_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/ops_screen.dart';
import 'screens/stats_screen.dart';
import 'security.dart';
import 'state.dart';
import 'theme.dart';
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
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: lock),
        ChangeNotifierProvider.value(value: backup),
        ChangeNotifierProvider.value(value: notifier),
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
    _fade.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == index) return;
    setState(() => index = i);
    _fade.forward(from: 0);
  }

  List<(String, String)> _tabs(AppLocalizations l) => [
    ('list', l.tabOps),
    ('wallet', l.tabAccounts),
    ('tags', l.tabCategories),
    ('chart-pie', l.tabStats),
    ('layout-grid', l.tabMore),
  ];

  @override
  void initState() {
    super.initState();
    final lock = context.read<LockService>();
    // Someone who already set a code has used the app before.
    lock.readPref('onboarded').then((v) => mounted ? setState(() => onboarded = v == '1' || lock.hasPin) : null);
  }

  void showOps() => _select(0);

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
    final pages = [const OpsScreen(), AccountsScreen(onShowOps: showOps), CategoriesScreen(onShowOps: showOps), const StatsScreen(), const MoreScreen()];
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(title, key: ValueKey(title)),
        ),
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
      floatingActionButton: ready && index != 4
          ? FloatingActionButton(tooltip: l.newOperation, onPressed: () => openTxSheet(context), child: Icon(appIcon('plus'), size: 26))
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        animationDuration: const Duration(milliseconds: 350),
        onDestinationSelected: _select,
        destinations: [for (final t in _tabs(l)) NavigationDestination(icon: Icon(appIcon(t.$1)), label: t.$2)],
      ),
    );
  }
}
