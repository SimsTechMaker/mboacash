import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'backup.dart';
import 'db.dart';
import 'export.dart';
import 'icons.dart';
import 'notify.dart';
import 'screens/accounts_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/more_screen.dart';
import 'screens/ops_screen.dart';
import 'screens/stats_screen.dart';
import 'security.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets/sheets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
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
  await notifier.init();
  if (!lock.locked) unawaited(notifier.askPermissionOnce());
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
          // Its own navigator, so the lock screen can open dialogs above the app's routes.
          Positioned.fill(
            child: Navigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const LockScreen())),
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
    return MaterialApp(
      title: 'carnet237',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
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

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  static const _tabs = [('list', 'Opérations'), ('wallet', 'Comptes'), ('tags', 'Catégories'), ('chart-pie', 'Statistiques'), ('layout-grid', 'Plus')];

  void showOps() => setState(() => index = 0);

  @override
  Widget build(BuildContext context) {
    final ready = context.select<AppState, bool>((s) => s.ready);
    final pages = [const OpsScreen(), AccountsScreen(onShowOps: showOps), CategoriesScreen(onShowOps: showOps), const StatsScreen(), const MoreScreen()];
    return Scaffold(
      appBar: AppBar(title: Text(_tabs[index].$2)),
      body: ready ? IndexedStack(index: index, children: pages) : const Center(child: CircularProgressIndicator()),
      floatingActionButton: ready && index != 4
          ? FloatingActionButton(tooltip: 'Nouvelle opération', onPressed: () => openTxSheet(context), child: Icon(appIcon('plus'), size: 26))
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [for (final t in _tabs) NavigationDestination(icon: Icon(appIcon(t.$1)), label: t.$2)],
      ),
    );
  }
}
