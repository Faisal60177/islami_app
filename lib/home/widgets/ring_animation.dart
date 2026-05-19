import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class PrayerRingWidget extends StatefulWidget {
  final String   topLabel;      // "Now Maghrib", "Sun Rise", etc.
  final String   bottomLabel;   // "ends in"
  final DateTime periodStart;
  final DateTime periodEnd;     // countdown target — ring fills toward this
  final bool     isProhibited;  // true → red ring
  final double   size;

  const PrayerRingWidget({
    super.key,
    required this.topLabel,
    required this.bottomLabel,
    required this.periodStart,
    required this.periodEnd,
    required this.isProhibited,
    this.size = 220,
  });

  @override
  State<PrayerRingWidget> createState() => _PrayerRingWidgetState();
}

class _PrayerRingWidgetState extends State<PrayerRingWidget>
    with SingleTickerProviderStateMixin {

  Timer? _ticker;
  late AnimationController _pulse;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scheduleTick();
  }

  // ── Always re-sync to the next UTC second boundary ─────────────────────────
  void _scheduleTick() {
    _ticker?.cancel();

    // Lock to device wall-clock second using raw ms — no UTC conversion needed.
    final msUntilNextSecond = 1000 - (DateTime.now().millisecondsSinceEpoch % 1000);

    _ticker = Timer(Duration(milliseconds: msUntilNextSecond), () {
      if (!mounted) return;
      setState(_updateRemaining);
      _scheduleTick();
    });
  }

  void _updateRemaining() {
    // Truncate BOTH sides to whole seconds so the displayed digit
    // always flips at exactly the same moment as the device clock.
    final nowSec = DateTime.now().copyWith(millisecond: 0, microsecond: 0);
    final endSec = widget.periodEnd.copyWith(millisecond: 0, microsecond: 0);

    var diff = endSec.difference(nowSec);
    if (diff.isNegative) diff += const Duration(hours: 24);
    _remaining = diff;
  }

  @override
  void didUpdateWidget(PrayerRingWidget old) {
    super.didUpdateWidget(old);
    if (old.periodEnd != widget.periodEnd ||
        old.periodStart != widget.periodStart) {
      setState(_updateRemaining);
      _scheduleTick(); // re-sync when period changes
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  // ── HH:MM:SS countdown ─────────────────────────────────────────────────────
  String _formatCountdown() {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  // ── Arc fill: elapsed / total for the current period ───────────────────────
  double _progress() {
    // Raw ms — no timezone conversion at all.
    final startMs   = widget.periodStart.millisecondsSinceEpoch;
    final endMs     = widget.periodEnd.millisecondsSinceEpoch;
    final nowMs     = DateTime.now().millisecondsSinceEpoch;

    final totalMs   = endMs - startMs;
    if (totalMs <= 0) return 0;
    final elapsedMs = nowMs - startMs;
    return (elapsedMs / totalMs).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final sz       = widget.size;
    final progress = _progress();

    // Ring color: red for prohibited, white-glow for normal
    final arcColor = widget.isProhibited
        ? const Color(0xFFFF4444)
        : Colors.white;
    final trackColor = widget.isProhibited
        ? Colors.red.withOpacity(0.20)
        : Colors.white.withOpacity(0.18);

    return SizedBox(
      width: sz, height: sz,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => CustomPaint(
          painter: _RingPainter(
            progress:     progress,
            pulseOpacity: _pulse.value,
            arcColor:     arcColor,
            trackColor:   trackColor,
            isProhibited: widget.isProhibited,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top label: "Now Maghrib" / "Sun Rise" ──────────────────
                Text(
                  widget.topLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.isProhibited
                        ? const Color(0xFFFF7070)
                        : Colors.white,
                    fontSize:      sz * 0.095,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 0.3,
                    height:        1.1,
                  ),
                ),
                SizedBox(height: sz * 0.018),
                // ── "ends in" label ────────────────────────────────────────
                Text(
                  widget.bottomLabel,
                  style: TextStyle(
                    color:    Colors.white.withOpacity(0.65),
                    fontSize: sz * 0.058,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: sz * 0.012),
                // ── Countdown HH:MM:SS ─────────────────────────────────────
                Text(
                  _formatCountdown(),
                  style: TextStyle(
                    color: widget.isProhibited
                        ? const Color(0xFFFF7070)
                        : Colors.white,
                    fontSize:      sz * 0.118,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 1.8,
                    fontFeatures:  const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Painter ──────────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final double pulseOpacity;
  final Color  arcColor;
  final Color  trackColor;
  final bool   isProhibited;

  _RingPainter({
    required this.progress,
    required this.pulseOpacity,
    required this.arcColor,
    required this.trackColor,
    required this.isProhibited,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width  / 2;
    final cy     = size.height / 2;
    final radius = size.width  * 0.42;
    const stroke = 6.0;
    final rect   = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // ── Outer glow pulse ─────────────────────────────────────────────────────
    final glowColor = isProhibited
        ? Colors.red.withOpacity(0.06 + 0.04 * pulseOpacity)
        : Colors.white.withOpacity(0.04 + 0.03 * pulseOpacity);

    canvas.drawCircle(
      Offset(cx, cy), radius + 8,
      Paint()
        ..color       = glowColor
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 16,
    );

    // ── Track ────────────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy), radius,
      Paint()
        ..color       = trackColor
        ..style       = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // ── Progress arc ─────────────────────────────────────────────────────────
    if (progress > 0) {
      final arcEnd = -math.pi / 2 + 2 * math.pi * progress;

      // Gradient: slightly dimmer start → full color end
      final arcPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle:   arcEnd,
          colors: [
            arcColor.withOpacity(0.55),
            arcColor,
          ],
        ).createShader(rect)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap   = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );

      // Dot at arc tip
      final dotX = cx + radius * math.cos(arcEnd);
      final dotY = cy + radius * math.sin(arcEnd);
      canvas.drawCircle(
        Offset(dotX, dotY),
        stroke * 1.5,
        Paint()..color = arcColor,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress     != progress     ||
          old.pulseOpacity != pulseOpacity ||
          old.arcColor     != arcColor     ||
          old.isProhibited != isProhibited;
}