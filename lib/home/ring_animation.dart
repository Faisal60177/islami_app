import 'dart:math' as math;
import 'package:flutter/material.dart';
// ─────────────────────────────────────────────────────────────────────────────
// 2. PRAYER PROGRESS RING

class PrayerRingEntry {
  final String name;
  final DateTime start;
  final DateTime end;
  const PrayerRingEntry({required this.name, required this.start, required this.end});
}

class PrayerProgressRing extends StatefulWidget {
  final List<PrayerRingEntry> entries;
  final double size; // diameter

  const PrayerProgressRing({
    super.key,
    required this.entries,
    this.size = 220,
  });

  @override
  State<PrayerProgressRing> createState() => _PrayerProgressRingState();
}

class _PrayerProgressRingState extends State<PrayerProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  // Prayer-specific colors
  static const _prayerColors = [
    Color(0xFF5B8DEF), // Fajr    – dawn blue
    Colors.red, // SunRise    – dawn blue
    Color(0xFF5B8DEF), // Ishraq    – dawn blue
    Colors.red, // Noon    – dawn blue
    Color(0xFFD4A843), // Dhuhr   – noon gold
    Color(0xFFE07B39), // Asr     – amber
    Colors.red, // SunSet    – dawn blue
    Color(0xFFCF4B3B), // Maghrib – dusk red
    Color(0xFF7B6DC2), // Isha    – indigo
  ];

  int _activeIndex(DateTime now) {
    for (int i = 0; i < widget.entries.length; i++) {
      final e = widget.entries[i];
      if (now.isAfter(e.start) && now.isBefore(e.end)) return i;
    }
    return -1;
  }

  double _segmentProgress(int index, DateTime now) {
    final e = widget.entries[index];
    final total = e.end.difference(e.start).inSeconds.toDouble();
    final elapsed = now.difference(e.start).inSeconds.toDouble();
    return (elapsed / total).clamp(0.0, 1.0);
  }

  // map DateTime to angle (0 = top = midnight)
  double _toAngle(DateTime dt) {
    final mins = dt.hour * 60.0 + dt.minute;
    return (mins / 1440) * 2 * math.pi - math.pi / 2;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final now = DateTime.now();
        final active = _activeIndex(now);
        final activeColor = active >= 0
            ? _prayerColors[active % _prayerColors.length]
            : const Color(0xFFD4A843);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ring painter
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  entries: widget.entries,
                  colors: _prayerColors,
                  activeIndex: active,
                  now: now,
                  pulse: _pulse.value,
                ),
              ),
              // Centre info
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clock
                  Text(
                    _clock(now),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.size * 0.115,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: widget.size * 0.020),
                  // Active prayer name
                  if (active >= 0) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: widget.size * 0.06,
                          vertical: widget.size * 0.018),
                      decoration: BoxDecoration(
                        color: activeColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(widget.size),
                        border: Border.all(
                            color: activeColor.withOpacity(0.50), width: 1),
                      ),
                      child: Text(
                        widget.entries[active].name,
                        style: TextStyle(
                          color: activeColor,
                          fontSize: widget.size * 0.072,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: widget.size * 0.018),
                    Text(
                      'ends ${_formatTime(widget.entries[active].end)}',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: widget.size * 0.052,
                      ),
                    ),
                  ] else
                    Text('No active prayer',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: widget.size * 0.055)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _clock(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $ampm";
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $ampm";
  }
}

class _RingPainter extends CustomPainter {
  final List<PrayerRingEntry> entries;
  final List<Color> colors;
  final int activeIndex;
  final DateTime now;
  final double pulse;

  _RingPainter({
    required this.entries,
    required this.colors,
    required this.activeIndex,
    required this.now,
    required this.pulse,
  });

  double _toAngle(DateTime dt) {
    final mins = dt.hour * 60.0 + dt.minute;
    return (mins / 1440) * 2 * math.pi - math.pi / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final outerR = cx * 0.90;
    final innerR = cx * 0.68;
    final trackR = (outerR + innerR) / 2;
    final trackW = outerR - innerR;

    // ── Background track ──────────────────────────────────────────────────────
    canvas.drawCircle(center, outerR,
        Paint()
          ..color = Colors.white.withOpacity(0.04)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(center, outerR,
        Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.drawCircle(center, innerR,
        Paint()
          ..color = const Color(0xFF013220)
          ..style = PaintingStyle.fill);

    // ── Segments (one per prayer window) ─────────────────────────────────────
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final color = colors[i % colors.length];
      final sAngle = _toAngle(e.start);
      final eAngle = _toAngle(e.end);
      var sweep = eAngle - sAngle;
      if (sweep < 0) sweep += 2 * math.pi;

      final isActive = i == activeIndex;

      // Filled segment (dimmed if not active)
      final segPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackW * (isActive ? 1.0 : 0.72)
        ..color = isActive
            ? color.withOpacity(0.85)
            : color.withOpacity(0.22)
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackR),
        sAngle + 0.025, sweep - 0.05, false, segPaint,
      );

      // Progress fill for active segment
      if (isActive) {
        final total = e.end
            .difference(e.start)
            .inSeconds
            .toDouble();
        final elapsed = now
            .difference(e.start)
            .inSeconds
            .toDouble();
        final progress = (elapsed / total).clamp(0.0, 1.0);

        // Glow layer
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: trackR),
          sAngle + 0.025, (sweep - 0.05) * progress, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = trackW * 1.35
            ..color = color.withOpacity(0.15 + pulse * 0.08)
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, trackW * 0.55),
        );

        // Progress arc
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: trackR),
          sAngle + 0.025, (sweep - 0.05) * progress, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = trackW
            ..strokeCap = StrokeCap.round
            ..shader = SweepGradient(
              center: Alignment.center,
              startAngle: sAngle + 0.025,
              endAngle: sAngle + 0.025 + (sweep - 0.05) * progress,
              colors: [color.withOpacity(0.6), color],
            ).createShader(Rect.fromCircle(center: center, radius: trackR)),
        );

        // Leading dot
        final dotAngle = sAngle + 0.025 + (sweep - 0.05) * progress;
        final dotPos = Offset(
          center.dx + trackR * math.cos(dotAngle),
          center.dy + trackR * math.sin(dotAngle),
        );
        canvas.drawCircle(dotPos, trackW * 0.52,
            Paint()
              ..color = color
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, trackW * 0.3));
        canvas.drawCircle(dotPos, trackW * 0.38, Paint()
          ..color = color);
        canvas.drawCircle(dotPos, trackW * 0.38,
            Paint()
              ..color = Colors.white.withOpacity(0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }

      // Prayer name & time label on ring
      final midAngle = sAngle + sweep / 2;
      final labelR = outerR + cx * 0.095;
      final labelPos = Offset(
        center.dx + labelR * math.cos(midAngle),
        center.dy + labelR * math.sin(midAngle),
      );

      // Dot marker at segment start
      final dotMarkPos = Offset(
        center.dx + trackR * math.cos(sAngle + 0.015),
        center.dy + trackR * math.sin(sAngle + 0.015),
      );
      canvas.drawCircle(dotMarkPos, isActive ? 4.5 : 3.0,
          Paint()
            ..color = isActive ? color : color.withOpacity(0.45));
    }

    // ── Hour tick marks ───────────────────────────────────────────────────────
    for (int h = 0; h < 24; h++) {
      final angle = (h / 24) * 2 * math.pi - math.pi / 2;
      final isMajor = h % 6 == 0;
      final r1 = outerR + (isMajor ? cx * 0.04 : cx * 0.02);
      final r2 = outerR + cx * 0.005;
      canvas.drawLine(
        Offset(
            center.dx + r2 * math.cos(angle), center.dy + r2 * math.sin(angle)),
        Offset(
            center.dx + r1 * math.cos(angle), center.dy + r1 * math.sin(angle)),
        Paint()
          ..color = Colors.white.withOpacity(isMajor ? 0.35 : 0.12)
          ..strokeWidth = isMajor ? 1.8 : 0.9,
      );
    }

    // ── Now hand (thin needle) ────────────────────────────────────────────────
    final nowAngle = _toAngle(now);
    final handEnd = Offset(
      center.dx + (outerR + cx * 0.045) * math.cos(nowAngle),
      center.dy + (outerR + cx * 0.045) * math.sin(nowAngle),
    );
    final handStart = Offset(
      center.dx + innerR * 0.55 * math.cos(nowAngle + math.pi),
      center.dy + innerR * 0.55 * math.sin(nowAngle + math.pi),
    );
    canvas.drawLine(handStart, handEnd,
        Paint()
          ..color = Colors.white.withOpacity(0.75)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(center, cx * 0.028, Paint()
      ..color = Colors.white.withOpacity(0.9));
    canvas.drawCircle(center, cx * 0.018, Paint()
      ..color = const Color(0xFF013220));
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.now != now || old.pulse != pulse || old.activeIndex != activeIndex;
}