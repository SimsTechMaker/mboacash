// Renders the app's real screens with made-up data, for the presentation video.
// Run: CAPTURE_OUT=<folder> flutter test docs/video/capture_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:carnet237/db.dart';
import 'package:carnet237/export.dart';
import 'package:carnet237/i18n.dart';
import 'package:carnet237/icons.dart';
import 'package:carnet237/models.dart';
import 'package:carnet237/screens/accounts_screen.dart';
import 'package:carnet237/screens/agenda_screen.dart';
import 'package:carnet237/screens/ops_screen.dart';
import 'package:carnet237/screens/periods_screen.dart';
import 'package:carnet237/screens/stats_screen.dart';
import 'package:carnet237/state.dart';
import 'package:carnet237/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

AppState demo() {
  final now = DateTime.now();
  final s = AppState(Store());
  final open = Period(isoDate(DateTime(now.year, now.month - 1, 25)), isoDate(DateTime(now.year, now.month, 24)));
  s.settings
    ..periodKind = 'month'
    ..periodStart = open.start
    ..periodEnd = open.end
    ..periodAnchor = 25
    ..budget = 220000;
  s.settings.cats.firstWhere((c) => c.id == 'alim').cap = 70000;
  s.settings.cats.firstWhere((c) => c.id == 'transport').cap = 30000;

  final txs = <Tx>[];
  var n = 0;
  void add(TxType type, double amount, DateTime d, String cat, String account, {String note = '', int dir = 1, String goal = '', String to = ''}) {
    if (d.isAfter(now)) return;
    final at = DateTime(d.year, d.month, d.day, 8 + n % 12);
    txs.add(
      Tx(
        id: 't${n++}',
        type: type,
        amount: amount,
        cat: cat,
        account: account,
        to: to,
        dir: dir,
        goal: goal,
        date: isoDate(d),
        note: note,
        created: at.millisecondsSinceEpoch,
      ),
    );
  }

  const week = [
    ('Marché Mokolo', 'alim', 14500.0, 'cash'),
    ('Moto-taxi', 'transport', 1500.0, 'cash'),
    ('Crédit téléphone', 'telephone', 2000.0, 'momo'),
    ('Déjeuner', 'resto', 2500.0, 'cash'),
    ('Taxi', 'transport', 1000.0, 'cash'),
    ('Pharmacie', 'sante', 6500.0, 'momo'),
    ('Sortie entre amis', 'loisirs', 9000.0, 'cash'),
  ];
  for (var m = 3; m >= 0; m--) {
    final start = DateTime(now.year, now.month - 1 - m, 25);
    add(TxType.income, 350000, start, 'salaire', 'bank', note: 'Salaire');
    add(TxType.transfer, 120000, start.add(const Duration(days: 1)), 'transfer', 'bank', to: 'cash', note: 'Retrait');
    add(TxType.transfer, 40000, start.add(const Duration(days: 1)), 'transfer', 'bank', to: 'momo');
    add(TxType.expense, 75000, start.add(const Duration(days: 6)), 'logement', 'bank', note: 'Loyer');
    add(TxType.expense, 18500, start.add(const Duration(days: 9)), 'factures', 'momo', note: 'ENEO');
    add(TxType.save, 40000, start.add(const Duration(days: 2)), 'save', 'bank', dir: -1, goal: 'g1');
    add(TxType.save, 15000, start.add(const Duration(days: 2)), 'save', 'bank', dir: -1, goal: 'g2');
    for (var d = 0; d < 30; d++) {
      final w = week[(d + m) % week.length];
      if (d % 2 == 0 || w.$2 == 'transport') add(TxType.expense, w.$3 + (d % 3) * 500, start.add(Duration(days: d)), w.$2, w.$4, note: w.$1);
    }
  }
  s.txs = txs;
  s.goals = [
    Goal(id: 'g1', name: "Fonds d'urgence", icon: 'shield', color: 'c2', target: 600000, initial: 120000, deadline: isoDate(DateTime(now.year + 1, 6, 1))),
    Goal(id: 'g2', name: 'Voyage à Kribi', icon: 'tree-palm', color: 'c6', target: 150000, initial: 20000),
  ];
  s.debts = [
    Debt(
      id: 'd1',
      owe: false,
      person: 'Moussa',
      amount: 50000,
      date: isoDate(now.subtract(const Duration(days: 40))),
      due: isoDate(now.add(const Duration(days: 20))),
    ),
  ];
  s.scheduled = [
    Scheduled(
      id: 's1',
      type: TxType.expense,
      amount: 75000,
      cat: 'logement',
      account: 'bank',
      note: 'Loyer',
      next: isoDate(now.add(const Duration(days: 26))),
      repeat: 'month',
    ),
    Scheduled(
      id: 's2',
      type: TxType.expense,
      amount: 20000,
      cat: 'telephone',
      account: 'momo',
      note: 'Internet',
      next: isoDate(now.add(const Duration(days: 5))),
      repeat: 'month',
    ),
    Scheduled(
      id: 's3',
      type: TxType.expense,
      amount: 25000,
      cat: 'famille',
      account: 'cash',
      note: 'Tontine',
      next: isoDate(now.add(const Duration(days: 10))),
      repeat: '2weeks',
    ),
  ];
  final past = s.previousPeriod(open);
  s.closed = [s.summarize(s.previousPeriod(past)), s.summarize(past)];
  s.view = open;
  s.ready = true;
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final out = Platform.environment['CAPTURE_OUT'] ?? '.';

  setUpAll(() async {
    await initializeDateFormatting();
    useLang('fr');
    final plex = FontLoader('IBMPlexSans');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      plex.addFont(rootBundle.load('assets/fonts/IBMPlexSans-$w.ttf'));
    }
    await plex.load();
    // Buttons and chips use the default font, a block font in tests.
    for (final family in ['Roboto', 'FlutterTest', 'Ahem']) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/IBMPlexSans-Medium.ttf'))).load();
    }
    await (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'))).load();
    await (FontLoader('Lucide')..addFont(rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'))).load();
  });

  Future<void> shot(WidgetTester tester, String name, Widget screen, {required double height, String? tap}) async {
    tester.view.physicalSize = Size(360 * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: demo(),
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            locale: const Locale('fr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: screen,
          ),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    if (tap != null) {
      await tester.tap(find.text(tap));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
    final box = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await box.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
    await tester.pumpWidget(const SizedBox());
  }

  Widget tab(String title, Widget body, {bool agenda = false}) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [if (agenda) IconButton(onPressed: () {}, icon: Icon(appIcon('calendar')))],
    ),
    body: body,
  );

  testWidgets('home', (t) => shot(t, 'home', tab('Bonjour', const OpsScreen(), agenda: true), height: 1400));
  testWidgets('accounts', (t) => shot(t, 'accounts', tab('Comptes', AccountsScreen(onShowOps: () {})), height: 1300));
  testWidgets('summary', (t) => shot(t, 'summary', tab('Résumé', const StatsScreen()), height: 1300, tap: '3 mois'));
  testWidgets('agenda', (t) => shot(t, 'agenda', const AgendaScreen(), height: 1100));
  testWidgets('periods', (t) => shot(t, 'periods', const PeriodsScreen(), height: 780));

  testWidgets('statement', (t) async {
    final s = demo();
    await t.runAsync(() async {
      final now = DateTime.now();
      final bytes = await buildStatement(s, StatementOptions(from: s.openPeriod.start, to: isoDate(now)));
      File('$out/statement.pdf').writeAsBytesSync(bytes);
    });
  });
}
