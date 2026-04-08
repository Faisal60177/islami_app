import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── Prayer Ring Entry ────────────────────────────────────────────────────────
class PrayerRingEntry {
  final String name;
  final DateTime start;
  final DateTime end;
  const PrayerRingEntry({required this.name, required this.start, required this.end});
}

// ─── Prayer Progress Ring ─────────────────────────────────────────────────────
class PrayerProgressRing extends StatefulWidget {
  final List<PrayerRingEntry> entries;
  final double size;

  const PrayerProgressRing({
    super.key,
    required this.entries,
    this.size = 260,
  });

  @override
  State<PrayerProgressRing> createState() => _PrayerProgressRingState();
}

class _PrayerProgressRingState extends State<PrayerProgressRing>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    // Rebuild every second for live clock
    _clock = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _clock.dispose();
    super.dispose();
  }

  // ── Prayer colors ────────────────────────────────────────────────────────
  static const _prayerColors = <String, Color>{
    'Fajr':    Color(0xFFF0F8FF),
    'SunRise': Colors.red,
    'Ishraq':  Color(0xFF72A0C1),
    'Noon':    Colors.red,
    'Dhuhr':   Color(0xFF87CEEB),
    'Asr':     Color(0xFFFFB74D),
    'SunSet':  Colors.red,
    'Maghrib': Color(0xFFEF9A9A),
    'Isha':    Color(0xFFB39DDB),
  };

  static const _prohibitedNames = {'SunRise', 'Noon', 'SunSet'};

  Color _colorFor(String name) =>
      _prayerColors[name] ?? const Color(0xFF4CAF82);


  int _activeIndex(DateTime now) {
    for (int i = 0; i < widget.entries.length; i++) {
      final e = widget.entries[i];

      if (e.end.isAfter(e.start)) {
        // Normal range — same day
        if (now.isAfter(e.start) && now.isBefore(e.end)) return i;
      } else {
        // Crosses midnight — active if after start OR before end
        if (now.isAfter(e.start) || now.isBefore(e.end)) return i;
      }
    }
    return -1;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  String _Clock(DateTime dt) {
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m:$s $ap';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _clock]),
      builder: (_, __) {
        final now = DateTime.now();
        final active = _activeIndex(now);
        final activeEntry = active >= 0 ? widget.entries[active] : null;
        final activeColor = active >= 0
            ? _colorFor(widget.entries[active].name)
            : const Color(0xFF4CAF82);
        final isProhibited = active >= 0
            ? _prohibitedNames.contains(widget.entries[active].name)
            : false;

        // Remaining time
        String remaining = '';
        if (activeEntry != null) {
          final diff = activeEntry.end.difference(now);
          final hh = diff.inHours;
          final mm = diff.inMinutes.remainder(60);
          final ss = diff.inSeconds.remainder(60);
          if (hh > 0) {
            remaining = '${hh}h ${mm}m left';
          } else if (mm > 0) {
            remaining = '${mm}m ${ss}s left';
          } else {
            remaining = '${ss}s left';
          }
        }

        final size = widget.size;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Ring painter ──────────────────────────────────────────────
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  entries: widget.entries,
                  colorMap: _prayerColors,
                  activeIndex: active,
                  now: now,
                  pulse: _pulse.value,
                ),
              ),

              // ── Centre content ────────────────────────────────────────────
              SizedBox(
                width: size * 0.62,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live clock
                    Text(
                      _Clock(now),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.08,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                        height: 1.1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    SizedBox(height: size * 0.025),

                    if (active >= 0) ...[
                      // Prayer name pill
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: size * 0.05, vertical: size * 0.016),
                        decoration: BoxDecoration(
                          color: activeColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(size),
                          border: Border.all(
                              color: activeColor.withOpacity(0.55), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: size * 0.025,
                              height: size * 0.025,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isProhibited
                                    ? const Color(0xFFFF0000)
                                    : const Color(0xFF66BB6A),
                              ),
                            ),
                            SizedBox(width: size * 0.018),
                            Text(
                              widget.entries[active].name,
                              style: TextStyle(
                                color: activeColor,
                                fontSize: size * 0.05,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: size * 0.016),

                      // Start – End time  (same format as prayer cards)
                      Text(
                        '${_formatTime(widget.entries[active].start)} – ${_formatTime(widget.entries[active].end)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: size * 0.05,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: size * 0.010),

                      // Remaining time
                      Text(
                        remaining,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: activeColor.withOpacity(0.75),
                          fontSize: size * 0.043,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      // Prohibited label
                      if (isProhibited) ...[
                        SizedBox(height: size * 0.010),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: size * 0.04, vertical: size * 0.010),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE57373).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(size),
                          ),
                          child: Text(
                            'Prohibited time',
                            style: TextStyle(
                              color: const Color(0xFFFF0000),
                              fontSize: size * 0.042,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      Text(
                        'No active period',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white38, fontSize: size * 0.05),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final List<PrayerRingEntry> entries;
  final Map<String, Color> colorMap;
  final int activeIndex;
  final DateTime now;
  final double pulse;

  static const _prohibitedNames = {'SunRise', 'Noon', 'SunSet'};

  _RingPainter({
    required this.entries,
    required this.colorMap,
    required this.activeIndex,
    required this.now,
    required this.pulse,
  });

  Color _colorFor(String name) =>
      colorMap[name] ?? const Color(0xFF4CAF82);

  // Map DateTime → angle (top = midnight = -π/2)
  double _toAngle(DateTime dt) {
    final mins = dt.hour * 60.0 + dt.minute + dt.second / 60.0;
    return (mins / 1440) * 2 * math.pi - math.pi / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final outerR = cx * 0.92;
    final innerR = cx * 0.67;
    final trackR = (outerR + innerR) / 2;
    final trackW = outerR - innerR;

    // ── Dark glass background ────────────────────────────────────────────────
    canvas.drawCircle(center, outerR + 2,
        Paint()
          ..color = const Color(0xFF0A1F13).withOpacity(0.5)
          ..style = PaintingStyle.fill);

    // ── Track ring ───────────────────────────────────────────────────────────
    canvas.drawCircle(center, trackR,
        Paint()
          ..color = Colors.white.withOpacity(0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackW + 2);

    // ── Inner circle fill (dark) ─────────────────────────────────────────────
    canvas.drawCircle(center, innerR - 2,
        Paint()
          ..color = const Color(0xFF012618).withOpacity(0.5)
          ..style = PaintingStyle.fill);

    // ── Outer subtle border ───────────────────────────────────────────────────
    canvas.drawCircle(center, outerR + 1,
        Paint()
          ..color = const Color(0xFF4CAF82).withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    // ── Segments ─────────────────────────────────────────────────────────────
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final color = _colorFor(e.name);
      final isProhibited = _prohibitedNames.contains(e.name);
      final sAngle = _toAngle(e.start);
      final eAngle = _toAngle(e.end);
      var sweep = eAngle - sAngle;
      if (sweep <= 0) sweep += 2 * math.pi;

      final isActive = i == activeIndex;
      final gap = 0.018;

      // Dim base segment
      final basePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackW * (isActive ? 1.0 : 0.68)
        ..color = isProhibited
            ? color.withOpacity(isActive ? 0.80 : 0.18)
            : color.withOpacity(isActive ? 0.82 : 0.22)
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackR),
        sAngle + gap, sweep - gap * 2, false, basePaint,
      );

      if (isActive) {
        // ── Active: progress fill ─────────────────────────────────────────
        final total = e.end.difference(e.start).inSeconds.toDouble();
        final elapsed = now.difference(e.start).inSeconds.toDouble();
        final progress = (elapsed / total).clamp(0.0, 1.0);
        final progressSweep = (sweep - gap * 2) * progress;

        // Glow halo
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: trackR),
          sAngle + gap, progressSweep, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = trackW * 1.6
            ..color = color.withOpacity(0.10 + pulse * 0.07)
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, trackW * 0.6),
        );

        // Progress arc with sweep gradient
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: trackR),
          sAngle + gap, progressSweep, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = trackW
            ..strokeCap = StrokeCap.round
            ..shader = SweepGradient(
              center: Alignment.center,
              startAngle: sAngle + gap,
              endAngle: sAngle + gap + progressSweep,
              colors: [color.withOpacity(0.55), color, color.withOpacity(0.9)],
              stops: const [0.0, 0.6, 1.0],
            ).createShader(Rect.fromCircle(center: center, radius: trackR)),
        );

        // Leading dot
        if (progressSweep > 0.01) {
          final dotAngle = sAngle + gap + progressSweep;
          final dotPos = Offset(
            center.dx + trackR * math.cos(dotAngle),
            center.dy + trackR * math.sin(dotAngle),
          );
          // Outer glow
          canvas.drawCircle(dotPos, trackW * 0.56,
              Paint()
                ..color = color.withOpacity(0.3 + pulse * 0.2)
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, trackW * 0.4));
          // Dot fill
          canvas.drawCircle(dotPos, trackW * 0.40, Paint()..color = color);
          // White ring
          canvas.drawCircle(
              dotPos, trackW * 0.40,
              Paint()
                ..color = Colors.white.withOpacity(0.85)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.8);
          // Inner dot
          canvas.drawCircle(dotPos, trackW * 0.16,
              Paint()..color = Colors.white.withOpacity(0.95));
        }
      }

      // ── Segment divider dot at start ──────────────────────────────────────
      final dotMarkPos = Offset(
        center.dx + trackR * math.cos(sAngle + 0.005),
        center.dy + trackR * math.sin(sAngle + 0.005),
      );
      canvas.drawCircle(
          dotMarkPos,
          isActive ? 3.5 : 2.5,
          Paint()..color = isActive ? color : color.withOpacity(0.5));

      // ── Label outside ring ────────────────────────────────────────────────
      final midAngle = sAngle + sweep / 2;
      final labelR = outerR + cx * 0.11;
      final lx = center.dx + labelR * math.cos(midAngle);
      final ly = center.dy + labelR * math.sin(midAngle);
      final fontSize = cx * 0.085;

      final tp = TextPainter(
        text: TextSpan(
          text: _shortName(e.name),
          style: TextStyle(
            color: isActive ? color : color.withOpacity(0.55),
            fontSize: fontSize,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }

    // ── Hour tick marks ───────────────────────────────────────────────────────
    for (int h = 0; h < 24; h++) {
      final angle = (h / 24) * 2 * math.pi - math.pi / 2;
      final isMajor = h % 6 == 0;
      final isMinor = h % 3 == 0;
      final r2 = outerR - 1;
      final r1 = r2 + (isMajor ? cx * 0.05 : isMinor ? cx * 0.03 : cx * 0.018);
      canvas.drawLine(
        Offset(center.dx + r2 * math.cos(angle), center.dy + r2 * math.sin(angle)),
        Offset(center.dx + r1 * math.cos(angle), center.dy + r1 * math.sin(angle)),
        Paint()
          ..color = Colors.white.withOpacity(isMajor ? 0.40 : isMinor ? 0.20 : 0.09)
          ..strokeWidth = isMajor ? 1.8 : 1.0,
      );
      // Hour number for major ticks
      if (isMajor) {
        final labelR2 = outerR + cx * 0.062;
        final tx = center.dx + labelR2 * math.cos(angle);
        final ty = center.dy + labelR2 * math.sin(angle);
        final hr = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        final suffix = h < 12 ? 'a' : 'p';
        final tp = TextPainter(
          text: TextSpan(
            text: '$hr$suffix',
            style: TextStyle(
                color: Colors.white.withOpacity(0.28),
                fontSize: cx * 0.068,
                fontWeight: FontWeight.w400),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(tx - tp.width / 2, ty - tp.height / 2));
      }
    }

    // ── Now hand ─────────────────────────────────────────────────────────────
    final nowAngle = _toAngle(now);
    final handOuter = Offset(
      center.dx + (outerR + cx * 0.055) * math.cos(nowAngle),
      center.dy + (outerR + cx * 0.055) * math.sin(nowAngle),
    );
    final handInner = Offset(
      center.dx + innerR * 0.45 * math.cos(nowAngle + math.pi),
      center.dy + innerR * 0.45 * math.sin(nowAngle + math.pi),
    );
    // Glow on hand
    canvas.drawLine(handInner, handOuter,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // Hand line
    canvas.drawLine(handInner, handOuter,
        Paint()
          ..color = Colors.white.withOpacity(0.85)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round);
    // Center pivot
    canvas.drawCircle(center, cx * 0.030, Paint()..color = Colors.white.withOpacity(0.9));
    canvas.drawCircle(center, cx * 0.018,
        Paint()..color = const Color(0xFF012618));
    canvas.drawCircle(center, cx * 0.010,
        Paint()..color = Colors.white.withOpacity(0.9));
  }

  String _shortName(String name) {
    const abbr = {
      'SunRise': 'Rise',
      'SunSet': 'Set',
      'Ishraq': 'Ishrq,Chast',
    };
    return abbr[name] ?? name;
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.now.second != now.second ||
          old.pulse != pulse ||
          old.activeIndex != activeIndex;
}