import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:home_widget/home_widget.dart';
import 'package:quick_actions/quick_actions.dart';

import 'format.dart';
import 'i18n.dart';
import 'security.dart';
import 'state.dart';

/// Ways into quick entry from outside the app: the launcher shortcut (long
/// press on the icon) and the home screen widget. Both are local: nothing
/// here touches the network.
class AppShortcuts {
  final AppState state;
  final LockService lock;
  AppShortcuts(this.state, this.lock);

  /// Set when the user asked for quick entry; the home screen opens it once
  /// the app is ready and unlocked.
  final pending = StreamController<String>.broadcast();
  String? waiting;

  static const _widget = 'com.ndi.carnet237.QuickWidgetProvider';

  Future<void> init() async {
    try {
      const actions = QuickActions();
      await actions.initialize(_ask);
      await actions.setShortcutItems([ShortcutItem(type: 'quick', localizedTitle: tr.quickTitle)]);
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri?.host == 'quick') _ask('quick');
      HomeWidget.widgetClicked.listen((uri) {
        if (uri?.host == 'quick') _ask('quick');
      });
    } catch (e) {
      debugPrint('my-nkap shortcuts unavailable: $e');
    }
    state.addListener(_refresh);
    lock.addListener(_refresh);
    await _refresh();
  }

  void _ask(String type) {
    waiting = type;
    pending.add(type);
  }

  /// Takes the waiting request, if any.
  String? take() {
    final w = waiting;
    waiting = null;
    return w;
  }

  String _shown = '';

  /// Writes the widget's texts. With a lock code, the amount stays hidden:
  /// the home screen is visible to anyone holding the phone.
  Future<void> _refresh() async {
    if (!state.ready) return;
    final amount = lock.hasPin ? '•••••' : Fmt(state.settings.currency).money(state.spendable);
    final key = '${tr.localeName}|$amount';
    if (key == _shown) return;
    _shown = key;
    try {
      await HomeWidget.saveWidgetData('label', tr.periodAvailable);
      await HomeWidget.saveWidgetData('amount', amount);
      await HomeWidget.saveWidgetData('add', '+ ${tr.typeExpense}');
      await HomeWidget.updateWidget(qualifiedAndroidName: _widget);
    } catch (e) {
      debugPrint('my-nkap widget not updated: $e');
    }
  }
}
