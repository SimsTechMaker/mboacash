import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../icons.dart';
import '../proofs.dart';
import '../security.dart';
import '../theme.dart';

/// Takes a photo or picks one from the gallery, reduced to ~1280 px so a
/// receipt stays readable at around 150 KB. Null if the user backed out.
Future<Uint8List?> pickProof(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(leading: Icon(appIcon('camera')), title: Text(ctx.l.proofCamera), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
        ListTile(leading: Icon(appIcon('image')), title: Text(ctx.l.proofGallery), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        const SizedBox(height: 8),
      ],
    ),
  );
  if (source == null || !context.mounted) return null;
  // The camera and gallery open outside the app: don't lock it meanwhile.
  final picked = await context.read<LockService>().withoutLock(
    () => ImagePicker().pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 70),
  );
  return picked?.readAsBytes();
}

/// The proof row of the movement form: an "add" button, or a thumbnail that
/// opens full screen, with replace and remove.
class ProofField extends StatelessWidget {
  /// Saved proof file name ('' if none) and a newly picked photo, not saved yet.
  final String saved;
  final Uint8List? pending;
  final ValueChanged<Uint8List> onPicked;
  final VoidCallback onRemove;
  const ProofField({super.key, required this.saved, required this.pending, required this.onPicked, required this.onRemove});

  Future<void> _pick(BuildContext context) async {
    final bytes = await pickProof(context);
    if (bytes != null) onPicked(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    if (pending == null && saved.isEmpty) {
      return OutlinedButton.icon(
        onPressed: () => _pick(context),
        icon: Icon(appIcon('paperclip'), size: 18),
        label: Text(l.proofAdd),
        style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
      );
    }
    return Row(
      children: [
        GestureDetector(
          onTap: () => showProof(context, bytes: pending, name: saved),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: ProofImage(bytes: pending, name: saved, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.proofTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(l.proofTapToView, style: TextStyle(color: context.c.muted, fontSize: 12.5)),
            ],
          ),
        ),
        IconButton(tooltip: l.proofReplace, onPressed: () => _pick(context), icon: Icon(appIcon('refresh-cw'), size: 20)),
        IconButton(
          tooltip: l.proofRemove,
          onPressed: onRemove,
          icon: Icon(appIcon('trash-2'), size: 20, color: context.c.expense),
        ),
      ],
    );
  }
}

/// A proof from memory ([bytes]) or from its saved file ([name]).
class ProofImage extends StatelessWidget {
  final Uint8List? bytes;
  final String name;
  final BoxFit fit;
  const ProofImage({super.key, this.bytes, this.name = '', this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    final broken = Center(child: Icon(appIcon('image'), color: context.c.muted));
    if (bytes != null) return Image.memory(bytes!, fit: fit, gaplessPlayback: true);
    if (!Proofs.isValidName(name)) return broken;
    return FutureBuilder<File>(
      future: Proofs.file(name),
      builder: (context, snap) =>
          snap.hasData ? Image.file(snap.data!, fit: fit, gaplessPlayback: true, errorBuilder: (_, _, _) => broken) : const SizedBox.shrink(),
    );
  }
}

/// Full-screen view with pinch to zoom.
Future<void> showProof(BuildContext context, {Uint8List? bytes, String name = ''}) => Navigator.push(
  context,
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (ctx) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(ctx.l.proofTitle)),
      body: InteractiveViewer(
        maxScale: 6,
        child: Center(
          child: ProofImage(bytes: bytes, name: name),
        ),
      ),
    ),
  ),
);
