import 'dart:math';

import 'package:flutter/material.dart';

import '../icons.dart';
import '../theme.dart';
import 'common.dart';

/// Shared visual building blocks so every page follows the home screen's look:
/// a gradient summary card on top, titled sections, soft cards below.

enum HeroTone { green, blue, amber, plum }

List<Color> heroColors(BuildContext context, HeroTone tone) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (tone) {
    HeroTone.green => dark ? const [Color(0xFF1F5E4D), Color(0xFF123B30)] : const [Color(0xFF1D6A56), Color(0xFF124A3C)],
    HeroTone.blue => dark ? const [Color(0xFF2C5C8A), Color(0xFF1A3A5C)] : const [Color(0xFF3A78B5), Color(0xFF224E7D)],
    HeroTone.amber => dark ? const [Color(0xFF8A5A1E), Color(0xFF5C3A12)] : const [Color(0xFFC07A24), Color(0xFF8A5216)],
    HeroTone.plum => dark ? const [Color(0xFF5C467F), Color(0xFF3A2C52)] : const [Color(0xFF7A5BB0), Color(0xFF51397D)],
  };
}

/// Gradient card with white content, used at the top of a page.
class GradientCard extends StatelessWidget {
  final Widget child;
  final HeroTone tone;
  final EdgeInsets padding;
  const GradientCard({super.key, required this.child, this.tone = HeroTone.green, this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 16)});

  @override
  Widget build(BuildContext context) {
    final c = heroColors(context, tone);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c),
        boxShadow: dark ? null : [BoxShadow(color: c.first.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    );
  }
}

const heroSoft = Color(0xB8FFFFFF);

class HeroLabel extends StatelessWidget {
  final String text;
  const HeroLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(color: heroSoft, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600),
  );
}

/// Small icon + label + animated amount, for the rows inside a hero card.
class HeroStat extends StatelessWidget {
  final String label, icon;
  final double value;
  final bool signed;
  const HeroStat({super.key, required this.label, required this.icon, required this.value, this.signed = false});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(9)),
        child: Icon(appIcon(icon), size: 16, color: Colors.white),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: heroSoft, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            FittedBox(
              alignment: Alignment.centerLeft,
              child: AnimatedMoney(value, size: 15, color: Colors.white, signed: signed),
            ),
          ],
        ),
      ),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  final String icon, text;
  final Widget? trailing;
  const SectionTitle({super.key, required this.icon, required this.text, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 8),
    child: Row(
      children: [
        Icon(appIcon(icon), size: 18, color: context.c.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Circular progress that animates to [value] (0..1), with optional content.
class RingProgress extends StatelessWidget {
  final double value;
  final Color color;
  final double size, stroke;
  final Widget? child;
  const RingProgress({super.key, required this.value, required this.color, this.size = 52, this.stroke = 6, this.child});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => CustomPaint(painter: _RingPainter(v, color, context.c.surface2, stroke), child: child),
      child: Center(child: child),
    ),
  );
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color color, track;
  final double stroke;
  _RingPainter(this.v, this.color, this.track, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, p..color = track);
    if (v > 0) canvas.drawArc(rect, -pi / 2, 2 * pi * v, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v || old.color != color || old.track != track;
}

/// Fades and lifts a list item in; later [index]es arrive a little later.
class FadeIn extends StatelessWidget {
  final int index;
  final Widget child;
  const FadeIn({super.key, this.index = 0, required this.child});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 280 + min(index, 8) * 45),
    curve: Curves.easeOutCubic,
    builder: (_, v, child) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: child),
    ),
    child: child,
  );
}

/// Rounded card with an optional tap, used for list items across pages.
class SoftCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  const SoftCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// Compact pill button with an icon, for actions at the bottom of a card.
class ActionChipButton extends StatelessWidget {
  final String icon, label;
  final VoidCallback? onPressed;
  final bool primary;
  const ActionChipButton({super.key, required this.icon, required this.label, this.onPressed, this.primary = false});

  @override
  Widget build(BuildContext context) {
    final fg = primary ? context.c.accentInk : context.c.ink;
    final bg = primary ? context.c.accent : context.c.surface2;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(appIcon(icon), size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
