import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../icons.dart';
import '../security.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import 'lock_screen.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  static const delayChoices = [0, 30, 60, 300, 900];

  static String delayLabel(AppLocalizations l, int s) {
    if (s == 0) return l.securityDelayNow;
    if (s < 60) return l.securityDelaySeconds(s);
    if (s % 60 == 0) return l.securityDelayMinutes(s ~/ 60);
    return l.securityDelayShort(s);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LockService>();

    Future<void> enable() async {
      final pin = await askNewPin(context);
      if (pin == null) return;
      await l.setPin(pin);
      if (context.mounted) toast(context, context.l.securityCodeOn);
    }

    Future<void> change() async {
      final cur = await askPin(context, title: context.l.securityCurrentCode, subtitle: context.l.securityEnterCurrent);
      if (cur == null || !context.mounted) return;
      final pin = await askNewPin(context);
      if (pin == null) return;
      await l.setPin(pin);
      if (context.mounted) toast(context, context.l.securityCodeChanged);
    }

    Future<void> disable() async {
      final cur = await askPin(context, title: context.l.securityCurrentCode, subtitle: context.l.securityEnterToRemove);
      if (cur == null) return;
      await l.removePin();
      if (context.mounted) toast(context, context.l.securityCodeRemoved);
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l.securityTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientCard(
            tone: l.hasPin ? HeroTone.green : HeroTone.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(15)),
                      child: Icon(appIcon(l.hasPin ? 'shield-check' : 'shield'), color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.hasPin ? context.l.securityProtected : context.l.securityUnprotected,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.hasPin
                                ? (l.biometric && l.biometricAvailable ? context.l.securityProtectedDescBio : context.l.securityProtectedDesc)
                                : context.l.securityUnprotectedDesc,
                            style: const TextStyle(color: heroSoft, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!l.hasPin)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF8A5216)),
                    icon: Icon(appIcon('lock')),
                    label: Text(context.l.securityEnable),
                    onPressed: enable,
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroButton(label: context.l.securityChange, onPressed: change),
                      _HeroButton(label: context.l.securityRemove, onPressed: disable),
                    ],
                  ),
              ],
            ),
          ),
          if (l.hasPin) ...[
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(appIcon('fingerprint')),
                    title: Text(context.l.securityBioTitle),
                    subtitle: Text(l.biometricAvailable ? context.l.securityBioOn : context.l.securityBioNone),
                    value: l.biometric && l.biometricAvailable,
                    onChanged: l.biometricAvailable
                        ? (v) async {
                            final ok = await l.setBiometric(v);
                            if (!ok && context.mounted) toast(context, context.l.securityBioCancelled);
                          }
                        : null,
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(appIcon('timer')),
                    title: Text(context.l.securityLockOnLeave),
                    subtitle: Text(delayLabel(context.l, l.delaySeconds)),
                    trailing: Icon(appIcon('chevron-right')),
                    onTap: () async {
                      final v = await showModalBottomSheet<int>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: RadioGroup<int>(
                            groupValue: l.delaySeconds,
                            onChanged: (v) => Navigator.pop(ctx, v),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [for (final d in delayChoices) RadioListTile<int>(value: d, title: Text(delayLabel(ctx.l, d)))],
                            ),
                          ),
                        ),
                      );
                      if (v != null) await l.setDelay(v);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(appIcon('lock')),
                    title: Text(context.l.securityLockNow),
                    onTap: () {
                      Navigator.pop(context);
                      l.lockNow();
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(context.l.securityFootnote, style: TextStyle(color: context.c.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Outlined white button for use on a gradient card.
class _HeroButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _HeroButton({required this.label, required this.onPressed});
  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Color(0x80FFFFFF)),
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}
