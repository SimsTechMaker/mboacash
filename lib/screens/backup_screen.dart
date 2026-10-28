import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../backup.dart';
import '../icons.dart';
import '../security.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'lock_screen.dart';
import 'security_screen.dart';

/// Every button here is the only way the app goes online; opening the screen
/// itself makes no network request.
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  static String when(DateTime d) => DateFormat("d MMM yyyy 'à' HH:mm", 'fr_FR').format(d);

  @override
  Widget build(BuildContext context) {
    final b = context.watch<DriveBackup>();
    final l = context.watch<LockService>();

    Future<void> guard(Future<void> Function() f, [String? done]) async {
      try {
        await f();
        if (done != null && context.mounted) toast(context, done);
      } on BackupException catch (e) {
        if (context.mounted) toast(context, e.message);
      }
    }

    final children = <Widget>[];
    if (!b.configured) {
      children.add(
        const Panel(
          child: EmptyState(icon: 'cloud-off', text: "La synchronisation Google Drive n'est pas configurée dans cette version de l'app."),
        ),
      );
    } else if (!b.connected) {
      children.add(
        Panel(
          child: EmptyState(
            icon: 'cloud',
            text:
                'Connecte ton compte Google pour enregistrer une copie chiffrée de tes données dans un espace privé de ton propre Drive. '
                'Tu pourras la restaurer sur un autre téléphone.',
            action: FilledButton.icon(
              icon: Icon(appIcon('log-in')),
              label: const Text('Se connecter avec Google'),
              onPressed: b.busy ? null : () => guard(b.connect, 'Compte Google connecté'),
            ),
          ),
        ),
      );
    } else {
      children.addAll([
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconBadge(icon: 'cloud', color: context.c.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.email!, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          b.lastBackup == null ? 'Jamais synchronisé depuis ce téléphone' : 'Dernière synchronisation : ${when(b.lastBackup!)}',
                          style: TextStyle(color: context.c.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!l.hasPin) ...[
                Text('Active un code de verrouillage : il sert à chiffrer tes sauvegardes.', style: TextStyle(color: context.c.warn)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
                  child: const Text('Activer un code'),
                ),
              ] else
                FilledButton.icon(
                  icon: Icon(appIcon('cloud-upload')),
                  label: const Text('Synchroniser maintenant'),
                  onPressed: b.busy ? null : () => guard(b.backupNow, 'Sauvegarde envoyée sur ton Google Drive'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text('Sauvegardes sur Drive', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              icon: Icon(appIcon('refresh-cw'), size: 18),
              label: Text(b.files == null ? 'Afficher' : 'Actualiser'),
              onPressed: b.busy ? null : () => guard(b.refresh),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (b.files == null)
          Text('Touche « Afficher » pour voir les sauvegardes de ce compte (connexion internet nécessaire).', style: TextStyle(color: context.c.muted))
        else if (b.files!.isEmpty)
          Text('Aucune sauvegarde pour ce compte.', style: TextStyle(color: context.c.muted))
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < b.files!.length; i++) ...[
                  if (i > 0) const Divider(),
                  ListTile(
                    leading: Icon(appIcon('archive'), color: context.c.accent),
                    title: Text(when(b.files![i].created)),
                    subtitle: Text('${(b.files![i].size / 1024).toStringAsFixed(1)} Ko${i == 0 ? ' · la plus récente' : ''}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => v == 'restore' ? _restore(context, b, b.files![i]) : guard(() => b.delete(b.files![i]), 'Sauvegarde supprimée'),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'restore', child: Text('Restaurer')),
                        PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 14),
        Text(
          "L'app ne se connecte à internet que quand tu touches un de ces boutons. Les ${DriveBackup.keep} dernières sauvegardes sont gardées, "
          'chiffrées avec ton code, dans un dossier caché de ton Drive que seule carnet237 peut lire.',
          style: TextStyle(color: context.c.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: b.busy ? null : () => guard(b.disconnect, 'Compte Google déconnecté de l\'app'),
            child: const Text('Déconnecter le compte Google'),
          ),
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Synchronisation')),
      body: Stack(
        children: [
          ListView(padding: const EdgeInsets.all(16), children: children),
          if (b.busy) const Positioned(left: 0, right: 0, top: 0, child: LinearProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _restore(BuildContext context, DriveBackup b, BackupFile f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer cette sauvegarde ?'),
        content: Text(
          'Toutes les données actuelles de ce téléphone seront remplacées par celles du ${when(f.created)}. '
          "Synchronise d'abord si tu veux garder l'état actuel.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurer')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final code = await askPin(
      context,
      title: 'Code de la sauvegarde',
      subtitle: 'Le code de verrouillage qui était actif quand cette sauvegarde a été faite',
      check: false,
    );
    if (code == null || !context.mounted) return;
    try {
      await b.restore(f, code);
      if (context.mounted) toast(context, 'Sauvegarde restaurée');
    } on BackupException catch (e) {
      if (context.mounted) toast(context, e.message);
    }
  }
}
