import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';

class RingPainter extends CustomPainter{
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - strokeWidth) / 2;
    const start = -1.5707963267948966;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), r, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.progress != progress ||
  old.progressColor != progressColor ||
  old.trackColor != trackColor;
}