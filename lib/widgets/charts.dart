import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

class DonutSlice {
  final double value;
  final Color color;
  const DonutSlice(this.value, this.color);
}

class Donut extends StatelessWidget {
  final List<DonutSlice> slices;
  final String centerTop, centerValue;
  final double size;
  const Donut({super.key, required this.slices, required this.centerTop, required this.centerValue, this.size = 170});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(slices, context.c.surface2),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerTop, style: TextStyle(color: context.c.muted, fontSize: 12)),
              Text(centerValue, style: numStyle.copyWith(fontSize: 17, color: context.c.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> slices;
  final Color track;
  _DonutPainter(this.slices, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 26.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * pi, false, p..color = track);
    final total = slices.fold<double>(0, (s, x) => s + x.value);
    if (total <= 0) return;
    var start = -pi / 2;
    const gap = 0.02;
    for (final sl in slices) {
      final sweep = sl.value / total * 2 * pi;
      canvas.drawArc(rect, start, max(sweep - gap, 0.01), false, p..color = sl.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

class BarPair {
  final String label;
  final double a, b; // income, expense
  final bool current;
  const BarPair(this.label, this.a, this.b, this.current);
}

/// Grouped bars (income vs expense) for the last months, drawn to one scale.
class PairBars extends StatelessWidget {
  final List<BarPair> data;
  final String Function(double) axis;
  const PairBars({super.key, required this.data, required this.axis});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 600 / 220,
      child: CustomPaint(painter: _BarsPainter(data, axis, context.c)),
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<BarPair> data;
  final String Function(double) axis;
  final AppColors c;
  _BarsPainter(this.data, this.axis, this.c);

  void _text(Canvas canvas, String s, Offset at, {TextAlign align = TextAlign.left, Color? color, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: 11, color: color ?? c.muted, fontWeight: bold ? FontWeight.w600 : FontWeight.w400),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = align == TextAlign.right
        ? at.dx - tp.width
        : align == TextAlign.center
        ? at.dx - tp.width / 2
        : at.dx;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = data.fold<double>(0, (m, d) => max(m, max(d.a, d.b)));
    if (maxV <= 0) return;
    const left = 44.0, bottom = 22.0, top = 8.0;
    final plotH = size.height - bottom - top;
    double y(double v) => top + plotH - v / maxV * plotH;
    final line = Paint()
      ..color = c.line
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      canvas.drawLine(Offset(left, y(maxV * f)), Offset(size.width, y(maxV * f)), line);
      _text(canvas, f == 0 ? '0' : axis(maxV * f), Offset(left - 6, y(maxV * f)), align: TextAlign.right);
    }
    final slotW = (size.width - left) / data.length;
    final bw = min(22.0, slotW / 3.2);
    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final cx = left + slotW * i + slotW / 2;
      final op = d.current ? 1.0 : 0.55;
      final r = Radius.circular(3);
      if (d.a > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(Rect.fromLTRB(cx - bw - 2, y(d.a), cx - 2, y(0)), topLeft: r, topRight: r),
          Paint()..color = c.income.withValues(alpha: op),
        );
      }
      if (d.b > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(Rect.fromLTRB(cx + 2, y(d.b), cx + 2 + bw, y(0)), topLeft: r, topRight: r),
          Paint()..color = c.expense.withValues(alpha: op),
        );
      }
      _text(canvas, d.label, Offset(cx, size.height - 8), align: TextAlign.center, color: d.current ? c.ink : c.muted, bold: d.current);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => true;
}
