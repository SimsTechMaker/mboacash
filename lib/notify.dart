import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'backup.dart';
import 'format.dart';
import 'i18n.dart';
import 'models.dart';
import 'security.dart';
import 'state.dart';

/// Local notifications only: nothing is sent to or from a server.
///
/// Reminders are scheduled ahead on the phone (Android's alarm service) and
/// rebuilt whenever the data changes or the app comes back to the foreground,
/// so no background task is needed:
/// - daily reminder for the next 14 days, skipping today once something was entered;
/// - debt due dates: 3 days before and on the day, at 9:00;
/// - sync reminder 7 days after the last Google Drive backup, if connected.
/// Budget alerts are immediate, when an expense crosses 80 % or 100 %.
class Notifier extends ChangeNotifier {
  static const _dailyBase = 1000, _debtBase = 2000, _syncId = 3000, _alertBase = 4000;
  static const _accent = Color(0xFF1D6A56);

  final AppState state;
  final DriveBackup backup;
  final LockService prefs;
  Notifier(this.state, this.backup, this.prefs);

  final _plugin = FlutterLocalNotificationsPlugin();
  bool daily = true, budget = true, debts = true, sync = true;
  int hour = 20, minute = 0;
  bool ready = false;

  int _rev = -1;
  Timer? _debounce;
  Set<String> _sent = {};

  Future<void> init() async {
    tzdata.initializeTimeZones();
    String id = '';
    try {
      id = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      // Unknown: fall back to the phone's current offset below.
    }
    tz.setLocalLocation(_location(id));
    await _plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_carnet')));

    daily = await prefs.readPref('n_daily') != '0';
    budget = await prefs.readPref('n_budget') != '0';
    debts = await prefs.readPref('n_debts') != '0';
    sync = await prefs.readPref('n_sync') != '0';
    final t = (await prefs.readPref('n_time'))?.split(':');
    if (t != null && t.length == 2) {
      hour = int.tryParse(t[0]) ?? 20;
      minute = int.tryParse(t[1]) ?? 0;
    }
    try {
      _sent = Set<String>.from(jsonDecode(await prefs.readPref('n_sent') ?? '[]') as List);
    } catch (_) {
      _sent = {};
    }

    _rev = state.rev;
    state.addListener(_onData);
    backup.onBackup = (_) => reschedule();
    ready = true;
    notifyListeners();
    await reschedule();
  }

  /// The compact time zone database leaves out alias zones, and many African
  /// capitals are aliases (Africa/Douala is Africa/Lagos): map them to their
  /// canonical zone, then fall back to a fixed offset from the phone's clock.
  static const _aliases = {
    'Lagos': ['Douala', 'Libreville', 'Malabo', 'Bangui', 'Brazzaville', 'Kinshasa', 'Luanda', 'Porto-Novo', 'Niamey'],
    'Abidjan': ['Dakar', 'Bamako', 'Conakry', 'Lome', 'Ouagadougou', 'Banjul', 'Freetown', 'Nouakchott', 'Accra', 'Timbuktu'],
    'Maputo': ['Kigali', 'Bujumbura', 'Lubumbashi', 'Blantyre', 'Gaborone', 'Harare', 'Lusaka'],
    'Nairobi': ['Addis_Ababa', 'Asmara', 'Dar_es_Salaam', 'Djibouti', 'Kampala', 'Mogadishu'],
  };

  static tz.Location _location(String id) {
    final city = id.startsWith('Africa/') ? id.substring(7) : '';
    final canonical = [
      for (final e in _aliases.entries)
        if (e.value.contains(city)) 'Africa/${e.key}',
    ];
    final h = DateTime.now().timeZoneOffset.inHours;
    final fixed = h == 0 ? 'Etc/UTC' : 'Etc/GMT${h > 0 ? '-' : '+'}${h.abs()}'; // Etc signs are inverted
    for (final name in [id, ...canonical, fixed]) {
      try {
        if (name.isNotEmpty) return tz.getLocation(name);
      } catch (_) {
        // Try the next candidate.
      }
    }
    return tz.UTC;
  }

  /// Asks Android 13+ for the permission, once, after the first unlock.
  Future<void> askPermissionOnce() async {
    if (await prefs.readPref('n_asked') == '1') return;
    await prefs.writePref('n_asked', '1');
    await prefs.withoutLock(() async => _android?.requestNotificationsPermission());
  }

  Future<bool> get enabledInSystem async => await _android?.areNotificationsEnabled() ?? true;
  Future<void> requestPermission() => prefs.withoutLock(() async => _android?.requestNotificationsPermission());

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  void _onData() {
    if (state.rev == _rev) return; // month or filter change, not data
    _rev = state.rev;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () async {
      await _checkBudget();
      await reschedule();
    });
  }

  // ---------- settings ----------

  Future<void> set({bool? daily, bool? budget, bool? debts, bool? sync, int? hour, int? minute}) async {
    this.daily = daily ?? this.daily;
    this.budget = budget ?? this.budget;
    this.debts = debts ?? this.debts;
    this.sync = sync ?? this.sync;
    this.hour = hour ?? this.hour;
    this.minute = minute ?? this.minute;
    await prefs.writePref('n_daily', this.daily ? null : '0');
    await prefs.writePref('n_budget', this.budget ? null : '0');
    await prefs.writePref('n_debts', this.debts ? null : '0');
    await prefs.writePref('n_sync', this.sync ? null : '0');
    await prefs.writePref('n_time', '${this.hour}:${this.minute}');
    notifyListeners();
    await reschedule();
  }

  // ---------- scheduling ----------

  NotificationDetails _details(String channel, String name, {bool high = false}) => NotificationDetails(
    android: AndroidNotificationDetails(
      channel,
      name,
      importance: high ? Importance.high : Importance.defaultImportance,
      priority: high ? Priority.high : Priority.defaultPriority,
      color: _accent,
      // Amounts stay hidden on a locked screen.
      visibility: NotificationVisibility.private,
    ),
  );

  Future<void> _at(int id, DateTime when, String title, String body, NotificationDetails d) async {
    final at = tz.TZDateTime(tz.local, when.year, when.month, when.day, when.hour, when.minute);
    if (!at.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: at,
      notificationDetails: d,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
    );
  }

  Future<void> reschedule() async {
    if (!ready || !state.ready) return;
    try {
      for (final p in await _plugin.pendingNotificationRequests()) {
        await _plugin.cancel(id: p.id);
      }
      final now = DateTime.now();
      final f = Fmt(state.settings.currency);

      if (daily) {
        final d = _details('daily', tr.notifyChDaily);
        final enteredToday = state.txs.any((t) => t.date == isoDate(now));
        for (var i = 0; i < 14; i++) {
          if (i == 0 && enteredToday) continue;
          final day = DateTime(now.year, now.month, now.day + i, hour, minute);
          await _at(_dailyBase + i, day, tr.appTitle, _dailyText[(day.day) % _dailyText.length], d);
        }
      }

      if (debts) {
        final d = _details('debts', tr.notifyChDebts, high: true);
        var i = 0;
        for (final x in state.debts) {
          final left = state.debtLeft(x);
          if (x.due.isEmpty || left <= 0) continue;
          final due = parseIso(x.due);
          for (final (k, days, label) in [(0, 3, tr.notifyIn3Days), (1, 0, tr.notifyToday)]) {
            final body = x.owe ? tr.notifyDebtIOwe(f.money(left), x.person, label) : tr.notifyDebtOwedToMe(x.person, f.money(left), label);
            await _at(_debtBase + i * 2 + k, DateTime(due.year, due.month, due.day - days, 9), tr.notifyDebtTitle(x.person), body, d);
          }
          if (++i >= 400) break;
        }
      }

      if (sync && backup.connected) {
        final base = backup.lastBackup ?? now;
        var at = DateTime(base.year, base.month, base.day + 7, 10);
        if (!at.isAfter(now)) at = DateTime(now.year, now.month, now.day + 1, 10);
        await _at(_syncId, at, tr.notifySyncTitle, backup.lastBackup == null ? tr.notifySyncNever : tr.notifySyncOld, _details('sync', tr.notifyChSync));
      }
    } catch (_) {
      // Permission refused or alarms unavailable: the app works without reminders.
    }
  }

  static List<String> get _dailyText => [tr.notifyDaily1, tr.notifyDaily2, tr.notifyDaily3, tr.notifyDaily4];

  // ---------- budget alerts ----------

  Future<void> _checkBudget() async {
    if (!budget) return;
    final month = monthKey(DateTime.now());
    final list = state.monthTxs(month).where((t) => t.type == TxType.expense);
    final f = Fmt(state.settings.currency);
    final d = _details('budget', tr.notifyChBudget, high: true);
    var changed = false;
    var n = 0;

    Future<void> check(String key, String name, double spent, double cap) async {
      if (cap <= 0) return;
      final level = spent >= cap ? 100 : (spent >= cap * 0.8 ? 80 : 0);
      if (level == 0 || _sent.contains('$month:$key:$level')) return;
      _sent.add('$month:$key:$level');
      if (level == 100) _sent.add('$month:$key:80');
      changed = true;
      final title = level == 100 ? tr.notifyOverTitle(name) : tr.notifyNearTitle(name);
      final body = level == 100 ? tr.notifyOverBody(f.money(spent), f.money(cap)) : tr.notifyNearBody(f.money(spent), f.money(cap), f.money(cap - spent));
      await _plugin.show(id: _alertBase + (n++ % 100), title: title, body: body, notificationDetails: d);
    }

    try {
      await check('budget', tr.notifyMonthBudget, list.fold(0.0, (s, t) => s + t.amount), state.settings.budget);
      for (final c in state.settings.cats.where((c) => !c.income && c.cap > 0)) {
        await check('cat:${c.id}', c.name, list.where((t) => t.cat == c.id).fold(0.0, (s, t) => s + t.amount), c.cap);
      }
    } catch (_) {
      // Notifications disabled: nothing to do.
    }
    if (changed) {
      _sent.removeWhere((k) => !k.startsWith(month));
      await prefs.writePref('n_sent', jsonEncode(_sent.toList()));
    }
  }
}
