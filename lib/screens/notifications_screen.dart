import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../icons.dart';
import '../notify.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool? allowed;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final ok = await context.read<Notifier>().enabledInSystem;
    if (mounted) setState(() => allowed = ok);
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<Notifier>();
    final l = context.l;
    final time = l.notificationsTimeValue(n.hour.toString().padLeft(2, '0'), n.minute.toString().padLeft(2, '0'));
    return Scaffold(
      appBar: AppBar(title: Text(l.notificationsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (allowed == false) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: context.c.warn.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.notificationsBlocked,
                    style: TextStyle(color: context.c.ink, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(l.notificationsBlockedHelp),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await n.requestPermission();
                      await _refresh();
                    },
                    child: Text(l.notificationsAllow),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(appIcon('bell')),
                  title: Text(l.notifyChDaily),
                  subtitle: Text(l.notificationsDailyDesc),
                  value: n.daily,
                  onChanged: (v) => n.set(daily: v),
                ),
                ListTile(
                  enabled: n.daily,
                  leading: Icon(appIcon('clock')),
                  title: Text(l.notificationsTime),
                  trailing: Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: n.hour, minute: n.minute),
                    );
                    if (t != null) await n.set(hour: t.hour, minute: t.minute);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  secondary: Icon(appIcon('gauge')),
                  title: Text(l.notifyChBudget),
                  subtitle: Text(l.notificationsBudgetDesc),
                  value: n.budget,
                  onChanged: (v) => n.set(budget: v),
                ),
                const Divider(),
                SwitchListTile(
                  secondary: Icon(appIcon('handshake')),
                  title: Text(l.notifyChDebts),
                  subtitle: Text(l.notificationsDebtsDesc),
                  value: n.debts,
                  onChanged: (v) => n.set(debts: v),
                ),
                const Divider(),
                SwitchListTile(
                  secondary: Icon(appIcon('cloud')),
                  title: Text(l.notifyChSync),
                  subtitle: Text(l.notificationsSyncDesc),
                  value: n.sync,
                  onChanged: (v) => n.set(sync: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(l.notificationsFooter, style: TextStyle(color: context.c.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
