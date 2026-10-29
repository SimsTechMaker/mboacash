import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../icons.dart';
import '../security.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import 'lock_screen.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  static const delays = {0: 'Immédiatement', 30: 'Après 30 secondes', 60: 'Après 1 minute', 300: 'Après 5 minutes', 900: 'Après 15 minutes'};

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LockService>();

    Future<void> enable() async {
      final pin = await askNewPin(context);
      if (pin == null) return;
      await l.setPin(pin);
      if (context.mounted) toast(context, 'Code activé');
    }

    Future<void> change() async {
      final cur = await askPin(context, title: 'Code actuel', subtitle: 'Saisis ton code actuel');
      if (cur == null || !context.mounted) return;
      final pin = await askNewPin(context);
      if (pin == null) return;
      await l.setPin(pin);
      if (context.mounted) toast(context, 'Code modifié. Les prochaines sauvegardes utiliseront le nouveau code.');
    }

    Future<void> disable() async {
      final cur = await askPin(context, title: 'Code actuel', subtitle: 'Saisis ton code pour le retirer');
      if (cur == null) return;
      await l.removePin();
      if (context.mounted) toast(context, 'Code retiré');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sécurité')),
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
                            l.hasPin ? 'App protégée' : 'App non protégée',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.hasPin
                                ? "Code activé${l.biometric && l.biometricAvailable ? ' · empreinte' : ''}. L'app le demande à l'ouverture."
                                : "N'importe qui ayant ton téléphone peut ouvrir l'app.",
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
                    label: const Text('Activer un code'),
                    onPressed: enable,
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroButton(label: 'Changer le code', onPressed: change),
                      _HeroButton(label: 'Retirer le code', onPressed: disable),
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
                    title: const Text('Empreinte ou reconnaissance faciale'),
                    subtitle: Text(
                      l.biometricAvailable
                          ? 'Déverrouille sans taper le code. Le code reste possible.'
                          : "Aucune empreinte ou visage enregistré sur ce téléphone. Ajoute-en dans les réglages d'Android.",
                    ),
                    value: l.biometric && l.biometricAvailable,
                    onChanged: l.biometricAvailable
                        ? (v) async {
                            final ok = await l.setBiometric(v);
                            if (!ok && context.mounted) toast(context, 'Vérification biométrique annulée');
                          }
                        : null,
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(appIcon('timer')),
                    title: const Text('Verrouiller quand je quitte l\'app'),
                    subtitle: Text(delays[l.delaySeconds] ?? 'Après ${l.delaySeconds} s'),
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
                              children: [for (final e in delays.entries) RadioListTile<int>(value: e.key, title: Text(e.value))],
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
                    title: const Text('Verrouiller maintenant'),
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
          Text(
            "Le code n'est jamais enregistré en clair : seule une empreinte chiffrée est gardée dans le coffre sécurisé d'Android. "
            'Après 5 erreurs, la saisie est bloquée un moment, et ce délai double à chaque nouvelle erreur. '
            'Le code sert aussi à chiffrer tes sauvegardes Google Drive.',
            style: TextStyle(color: context.c.muted, fontSize: 13),
          ),
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
