import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../icons.dart';
import '../security.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Number pad with dots for 4–6 digit codes.
class PinPad extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? error;
  final int minLength;
  final bool autoSubmit; // submit as soon as [autoSubmitLength] digits are typed
  final int autoSubmitLength;
  final Future<void> Function(String pin) onSubmit;
  final Widget? extra; // e.g. biometric button
  final bool enabled;
  const PinPad({
    super.key,
    required this.title,
    this.subtitle,
    this.error,
    this.minLength = 4,
    this.autoSubmit = false,
    this.autoSubmitLength = 6,
    required this.onSubmit,
    this.extra,
    this.enabled = true,
  });
  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String pin = '';
  bool busy = false;

  Future<void> submit() async {
    if (busy || pin.length < widget.minLength) return;
    setState(() => busy = true);
    final value = pin;
    await widget.onSubmit(value);
    if (mounted) {
      setState(() {
        busy = false;
        pin = '';
      });
    }
  }

  void tap(String d) {
    if (!widget.enabled || busy || pin.length >= 6) return;
    HapticFeedback.selectionClick();
    setState(() => pin += d);
    if (widget.autoSubmit && pin.length == widget.autoSubmitLength) submit();
  }

  @override
  Widget build(BuildContext context) {
    Widget key(String d) => _Key(label: d, onTap: () => tap(d));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.c.muted),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 6; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 7),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < pin.length ? context.c.accent : Colors.transparent,
                  border: Border.all(color: i < widget.minLength || i < pin.length ? context.c.accent : context.c.line, width: 2),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 36,
          child: Center(
            child: busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    widget.error ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.c.expense),
                  ),
          ),
        ),
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final d in row) key(d)]),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 84, height: 72, child: Center(child: widget.extra)),
            key('0'),
            SizedBox(
              width: 84,
              height: 72,
              child: Center(
                child: pin.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer',
                        icon: Icon(appIcon('delete'), size: 26),
                        onPressed: () => setState(() => pin = pin.substring(0, pin.length - 1)),
                      ),
              ),
            ),
          ],
        ),
        if (!widget.autoSubmit) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: 252,
            child: FilledButton(onPressed: widget.enabled && pin.length >= widget.minLength && !busy ? submit : null, child: const Text('Valider')),
          ),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Key({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(6),
    child: Material(
      color: context.c.surface2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 60,
          child: Center(
            child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    ),
  );
}

/// Full-screen lock shown over the app while [LockService.locked] is true.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String? error;
  Timer? ticker;

  @override
  void initState() {
    super.initState();
    // Offer biometrics straight away, once the screen is up.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && context.read<LockService>().blockedUntil != null) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  Future<void> _bio() async {
    final l = context.read<LockService>();
    if (l.biometric && l.biometricAvailable && !l.isBlocked) await l.unlockWithBiometric();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LockService>();
    final blocked = l.isBlocked;
    final wait = blocked ? l.blockedUntil!.difference(DateTime.now()).inSeconds + 1 : 0;
    return Scaffold(
      backgroundColor: context.c.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: context.c.accent, borderRadius: BorderRadius.circular(16)),
                  child: Icon(appIcon('lock'), color: context.c.accentInk, size: 28),
                ),
                const SizedBox(height: 18),
                PinPad(
                  title: 'carnet237 est verrouillé',
                  subtitle: 'Saisis ton code pour continuer',
                  error: blocked ? 'Trop d\'essais. Réessaie dans $wait s.' : error,
                  enabled: !blocked,
                  onSubmit: (pin) async {
                    final ok = await l.unlockWithPin(pin);
                    if (!ok && mounted) {
                      setState(
                        () => error = l.failures >= LockService.maxTries
                            ? 'Code incorrect.'
                            : 'Code incorrect. ${LockService.maxTries - l.failures} essai${LockService.maxTries - l.failures > 1 ? 's' : ''} avant une pause.',
                      );
                    }
                  },
                  extra: l.biometric && l.biometricAvailable
                      ? IconButton(
                          tooltip: 'Empreinte ou visage',
                          iconSize: 30,
                          icon: Icon(appIcon('fingerprint'), color: context.c.accent),
                          onPressed: blocked ? null : _bio,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: () => _forgot(context), child: const Text('Code oublié ?')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _forgot(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Code oublié'),
        content: const Text(
          "Le code ne peut pas être récupéré. La seule solution est d'effacer toutes les données de l'app sur ce téléphone et de retirer le code.\n\n"
          'Si tu as une sauvegarde Google Drive, tu pourras la restaurer ensuite, mais il faudra le code utilisé au moment de cette sauvegarde.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.c.expense, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final s = context.read<AppState>();
    final l = context.read<LockService>();
    await s.wipeAll();
    await l.removePin();
    if (context.mounted) toast(context, 'Données effacées et code retiré');
  }
}

/// Asks for a new code twice. Returns the code, or null if cancelled.
Future<String?> askNewPin(BuildContext context) {
  return Navigator.push<String>(context, MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _NewPinPage()));
}

class _NewPinPage extends StatefulWidget {
  const _NewPinPage();
  @override
  State<_NewPinPage> createState() => _NewPinPageState();
}

class _NewPinPageState extends State<_NewPinPage> {
  String? first;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Code de verrouillage')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: PinPad(
            key: ValueKey(first == null),
            title: first == null ? 'Choisis un code' : 'Confirme le code',
            subtitle: first == null ? 'De 4 à 6 chiffres' : 'Saisis-le une deuxième fois',
            error: error,
            onSubmit: (pin) async {
              if (first == null) {
                setState(() {
                  first = pin;
                  error = null;
                });
              } else if (pin == first) {
                Navigator.pop(context, pin);
              } else {
                setState(() {
                  first = null;
                  error = 'Les deux codes sont différents. Recommence.';
                });
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Asks for the current code (or any code, with [check] = false).
Future<String?> askPin(BuildContext context, {required String title, String? subtitle, bool check = true}) {
  return Navigator.push<String>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _AskPinPage(title: title, subtitle: subtitle, check: check),
    ),
  );
}

class _AskPinPage extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool check;
  const _AskPinPage({required this.title, this.subtitle, required this.check});
  @override
  State<_AskPinPage> createState() => _AskPinPageState();
}

class _AskPinPageState extends State<_AskPinPage> {
  String? error;
  @override
  Widget build(BuildContext context) {
    final l = context.watch<LockService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Code')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: PinPad(
            title: widget.title,
            subtitle: widget.subtitle,
            error: widget.check && l.isBlocked ? "Trop d'essais. Réessaie plus tard." : error,
            enabled: !(widget.check && l.isBlocked),
            onSubmit: (pin) async {
              if (!widget.check || await l.check(pin)) {
                if (context.mounted) Navigator.pop(context, pin);
              } else {
                setState(() => error = 'Code incorrect.');
              }
            },
          ),
        ),
      ),
    );
  }
}
