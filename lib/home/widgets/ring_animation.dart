import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:async';

// ─── Prayer Ring Entry ────────────────────────────────────────────────────────
class PrayerRingEntry {
  final String name;
  final DateTime start;
  final DateTime end;
  const PrayerRingEntry(
      {required this.name, required this.start, required this.end});
}

// ─── Prayer Progress Ring ─────────────────────────────────────────────────────
class PrayerProgressRing extends StatefulWidget {
  final List<PrayerRingEntry> entries;
  final double size;
  final Duration tzOffset; // ✅ NEW: offset of the prayer location timezone

  const PrayerProgressRing({
    super.key,
    required this.entries,
    required this.tzOffset, // ✅ NEW
    this.size = 260,
  });

  @override
  State<PrayerProgressRing> createState() => _PrayerProgressRingState();
}

class _PrayerProgressRingState extends State<PrayerProgressRing>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _timer;
  DateTime _now = DateTime.now().toUtc(); // ✅ always track UTC internally

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Sync to next exact second boundary — no drift, no delay
    final msUntilNextSecond = 1000 - DateTime.now().millisecond;
    _timer = Timer(Duration(milliseconds: msUntilNextSecond), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now().toUtc());
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now().toUtc());
      });
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ✅ Convert UTC _now to the prayer location's local time
  DateTime get _nowInTz => _now.add(widget.tzOffset);

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

  int _activeIndex() {
    for (int i = 0; i < widget.entries.length; i++) {
      final e        = widget.entries[i];
      final startUtc = e.start.toUtc();
      final endUtc   = e.end.toUtc();

      if (endUtc.isAfter(startUtc)) {
        if (!_now.isBefore(startUtc) && _now.isBefore(endUtc)) return i;
      } else {
        if (!_now.isBefore(startUtc) || _now.isBefore(endUtc)) return i;
      }
    }
    return -1;
  }

  String _formatTime(DateTime dt) {
    final h  = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  String _clockStr(DateTime dt) {
    final h  = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m  = dt.minute.toString().padLeft(2, '0');
    final s  = dt.second.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m:$s $ap';
  }

  String _remainingStr(PrayerRingEntry entry) {
    // Truncate UTC to second — same truncation point as the clock
    final nowUtcTrunc = DateTime.utc(
      _now.year, _now.month, _now.day,
      _now.hour, _now.minute, _now.second,
    );

    final startUtc = entry.start.toUtc();
    var   endUtc   = entry.end.toUtc();

    if (!endUtc.isAfter(startUtc)) {
      endUtc = endUtc.add(const Duration(days: 1));
    }

    var effectiveNow = nowUtcTrunc;
    if (effectiveNow.isBefore(startUtc)) {
      effectiveNow = effectiveNow.add(const Duration(days: 1));
    }

    final diff = endUtc.difference(effectiveNow);
    if (diff.isNegative || diff == Duration.zero) return '';

    final hh = diff.inHours;
    final mm = diff.inMinutes.remainder(60);
    final ss = diff.inSeconds.remainder(60);

    if (hh > 0) return '${hh}h ${mm}m left';
    if (mm > 0) return '${mm}m ${ss}s left';
    return '${ss}s left';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final nowInTz = _nowInTz; // location-local, has sub-second from UTC

        // ✅ Truncate to second for ALL text displays — clock and countdown
        // flip at exactly the same millisecond this way
        final nowInTzTrunc = DateTime(
          nowInTz.year, nowInTz.month, nowInTz.day,
          nowInTz.hour, nowInTz.minute, nowInTz.second,
        );

        final active      = _activeIndex(); // uses _now (UTC) internally
        final activeEntry = active >= 0 ? widget.entries[active] : null;
        final activeColor  = active >= 0
            ? _colorFor(widget.entries[active].name)
            : const Color(0xFF4CAF82);
        final isProhibited = active >= 0
            ? _prohibitedNames.contains(widget.entries[active].name)
            : false;

        final size   = widget.size;
        final innerD = size * 0.58;

        return SizedBox(
          width:  size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  entries:     widget.entries,
                  colorMap:    _prayerColors,
                  activeIndex: active,
                  nowLocal:    nowInTz,  // ✅ local for hand
                  nowUtc:      _now,     // ✅ true UTC for progress
                  pulse:       _pulse.value,
                ),
              ),

              ClipOval(
                child: SizedBox(
                  width:  innerD,
                  height: innerD,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.012),
                      child: Column(
                        mainAxisSize:       MainAxisSize.min,
                        mainAxisAlignment:  MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          // Live clock — shows location timezone time
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _clockStr(nowInTz), // ✅ location-local clock
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:         Colors.white,
                                fontSize:      size * 0.088,
                                fontWeight:    FontWeight.w300,
                                letterSpacing: 0.5,
                                height:        1.1,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: size * 0.014),

                          if (active >= 0 && activeEntry != null) ...[

                            Container(
                              constraints: BoxConstraints(
                                  maxWidth: innerD - size * 0.06),
                              padding: EdgeInsets.symmetric(
                                  horizontal: size * 0.036,
                                  vertical:   size * 0.010),
                              decoration: BoxDecoration(
                                color: activeColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(size),
                                border: Border.all(
                                    color: activeColor.withOpacity(0.55),
                                    width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize:      MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width:  size * 0.020,
                                    height: size * 0.020,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isProhibited
                                          ? const Color(0xFFFF0000)
                                          : const Color(0xFF66BB6A),
                                    ),
                                  ),
                                  SizedBox(width: size * 0.012),
                                  Flexible(
                                    child: Text(
                                      widget.entries[active].name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:         activeColor,
                                        fontSize:      size * 0.042,
                                        fontWeight:    FontWeight.w600,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: size * 0.010),

                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${_formatTime(activeEntry.start)} – ${_formatTime(activeEntry.end)}',
                                textAlign: TextAlign.center,
                                maxLines:  1,
                                style: TextStyle(
                                  color:         Colors.white70,
                                  fontSize:      size * 0.040,
                                  fontWeight:    FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),

                            SizedBox(height: size * 0.006),

                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _remainingStr(activeEntry), // ✅ no longer needs nowInTz param
                                textAlign: TextAlign.center,
                                maxLines:  1,
                                style: TextStyle(
                                  color:      activeColor.withOpacity(0.80),
                                  fontSize:   size * 0.036,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),

                            if (isProhibited) ...[
                              SizedBox(height: size * 0.006),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: size * 0.030,
                                      vertical:   size * 0.006),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE57373)
                                        .withOpacity(0.15),
                                    borderRadius:
                                    BorderRadius.circular(size),
                                  ),
                                  child: Text(
                                    'Prohibited time',
                                    maxLines: 1,
                                    style: TextStyle(
                                      color:      const Color(0xFFFF0000),
                                      fontSize:   size * 0.034,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                          ] else ...[
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'No active period',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color:    Colors.white38,
                                    fontSize: size * 0.042),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Ring Painter — unchanged, already receives nowInTz ──────────────────────
class _RingPainter extends CustomPainter {
  final List<PrayerRingEntry> entries;
  final Map<String, Color> colorMap;
  final int activeIndex;
  final DateTime nowLocal; // location-local — for hand angle & shouldRepaint
  final DateTime nowUtc;   // true UTC     — for progress elapsed calculation
  final double pulse;

  static const _prohibitedNames = {'SunRise', 'Noon', 'SunSet'};

  _RingPainter({
    required this.entries,
    required this.colorMap,
    required this.activeIndex,
    required this.nowLocal,
    required this.nowUtc,
    required this.pulse,
  });

  Color _colorFor(String name) =>
      colorMap[name] ?? const Color(0xFF4CAF82);

  double _toAngle(DateTime dt) {
    final mins = dt.hour * 60.0 + dt.minute + dt.second / 60.0;
    return (mins / 1440) * 2 * math.pi - math.pi / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ... all your existing paint code unchanged ...
    final cx     = size.width / 2;
    final cy     = size.height / 2;
    final center = Offset(cx, cy);
    final outerR = cx * 0.92;
    final innerR = cx * 0.67;
    final trackR = (outerR + innerR) / 2;
    final trackW = outerR - innerR;

    canvas.drawCircle(center, outerR + 2,
        Paint()
          ..color = const Color(0xFF0A1F13).withOpacity(0.5)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(center, trackR,
        Paint()
          ..color       = Colors.white.withOpacity(0.05)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = trackW + 2);
    canvas.drawCircle(center, innerR - 2,
        Paint()
          ..color = const Color(0xFF012618).withOpacity(0.5)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(center, outerR + 1,
        Paint()
          ..color       = const Color(0xFF4CAF82).withOpacity(0.15)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    for (int i = 0; i < entries.length; i++) {
      final e            = entries[i];
      final color        = _colorFor(e.name);
      final isProhibited = _prohibitedNames.contains(e.name);
      final sAngle       = _toAngle(e.start);
      final eAngle       = _toAngle(e.end);
      var   sweep        = eAngle - sAngle;
      if (sweep <= 0) sweep += 2 * math.pi;

      final isActive = i == activeIndex;
      const gap      = 0.018;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackR),
        sAngle + gap, sweep - gap * 2, false,
        Paint()
          ..style       = PaintingStyle.stroke
          ..strokeWidth = trackW * (isActive ? 1.0 : 0.68)
          ..color       = isProhibited
              ? color.withOpacity(isActive ? 0.80 : 0.18)
              : color.withOpacity(isActive ? 0.82 : 0.22)
          ..strokeCap   = StrokeCap.butt,
      );

      if (isActive) {
        final startUtc = e.start.toUtc();
        var   endUtc   = e.end.toUtc();
        if (!endUtc.isAfter(startUtc)) {
          endUtc = endUtc.add(const Duration(days: 1));
        }

        // ✅ nowUtc is real UTC — no .toUtc() needed, no double-offset
        final total         = endUtc.difference(startUtc).inSeconds.toDouble();
        final elapsed       = nowUtc.difference(startUtc).inSeconds
            .toDouble().clamp(0.0, total);
        final progress      = (elapsed / total).clamp(0.0, 1.0);
        final progressSweep = (sweep - gap * 2) * progress;

        if (progressSweep > 0.001) {
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: trackR),
            sAngle + gap, progressSweep, false,
            Paint()
              ..style       = PaintingStyle.stroke
              ..strokeWidth = trackW * 1.6
              ..color       = color.withOpacity(0.10 + pulse * 0.07)
              ..strokeCap   = StrokeCap.round
              ..maskFilter  = MaskFilter.blur(BlurStyle.normal, trackW * 0.6),
          );

          final double gradStart = sAngle + gap;
          final double gradEnd   = sAngle + gap + progressSweep;
          final Paint progressPaint;

          if ((gradEnd - gradStart).abs() > 0.001) {
            progressPaint = Paint()
              ..style       = PaintingStyle.stroke
              ..strokeWidth = trackW
              ..strokeCap   = StrokeCap.round
              ..shader      = SweepGradient(
                center:     Alignment.center,
                startAngle: gradStart,
                endAngle:   gradEnd,
                colors: [
                  color.withOpacity(0.55),
                  color,
                  color.withOpacity(0.9),
                ],
                stops: const [0.0, 0.6, 1.0],
              ).createShader(Rect.fromCircle(center: center, radius: trackR));
          } else {
            progressPaint = Paint()
              ..style       = PaintingStyle.stroke
              ..strokeWidth = trackW
              ..strokeCap   = StrokeCap.round
              ..color       = color.withOpacity(0.82);
          }

          canvas.drawArc(
            Rect.fromCircle(center: center, radius: trackR),
            sAngle + gap, progressSweep, false, progressPaint,
          );

          final dotAngle = sAngle + gap + progressSweep;
          final dotPos   = Offset(
            center.dx + trackR * math.cos(dotAngle),
            center.dy + trackR * math.sin(dotAngle),
          );
          canvas.drawCircle(dotPos, trackW * 0.56,
              Paint()
                ..color      = color.withOpacity(0.3 + pulse * 0.2)
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, trackW * 0.4));
          canvas.drawCircle(dotPos, trackW * 0.40, Paint()..color = color);
          canvas.drawCircle(dotPos, trackW * 0.40,
              Paint()
                ..color       = Colors.white.withOpacity(0.85)
                ..style       = PaintingStyle.stroke
                ..strokeWidth = 1.8);
          canvas.drawCircle(dotPos, trackW * 0.16,
              Paint()..color = Colors.white.withOpacity(0.95));
        }
      }

      final dotMarkPos = Offset(
        center.dx + trackR * math.cos(sAngle + 0.005),
        center.dy + trackR * math.sin(sAngle + 0.005),
      );
      canvas.drawCircle(dotMarkPos, isActive ? 3.5 : 2.5,
          Paint()..color = isActive ? color : color.withOpacity(0.5));

      final midAngle = sAngle + sweep / 2;
      final labelR   = outerR + cx * 0.11;
      final lx       = center.dx + labelR * math.cos(midAngle);
      final ly       = center.dy + labelR * math.sin(midAngle);

      final tp = TextPainter(
        text: TextSpan(
          text: _shortName(e.name),
          style: TextStyle(
            color:         isActive ? color : color.withOpacity(0.55),
            fontSize:      cx * 0.085,
            fontWeight:    isActive ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
        textAlign:     TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }

    for (int h = 0; h < 24; h++) {
      final angle   = (h / 24) * 2 * math.pi - math.pi / 2;
      final isMajor = h % 6 == 0;
      final isMinor = h % 3 == 0;
      final r2      = outerR - 1;
      final r1      = r2 + (isMajor ? cx * 0.05 : isMinor ? cx * 0.03 : cx * 0.018);
      canvas.drawLine(
        Offset(center.dx + r2 * math.cos(angle), center.dy + r2 * math.sin(angle)),
        Offset(center.dx + r1 * math.cos(angle), center.dy + r1 * math.sin(angle)),
        Paint()
          ..color       = Colors.white.withOpacity(isMajor ? 0.40 : isMinor ? 0.20 : 0.09)
          ..strokeWidth = isMajor ? 1.8 : 1.0,
      );
      if (isMajor) {
        final labelR2 = outerR + cx * 0.062;
        final tx      = center.dx + labelR2 * math.cos(angle);
        final ty      = center.dy + labelR2 * math.sin(angle);
        final hr      = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        final suffix  = h < 12 ? 'a' : 'p';
        final tp2 = TextPainter(
          text: TextSpan(
            text: '$hr$suffix',
            style: TextStyle(
                color:      Colors.white.withOpacity(0.28),
                fontSize:   cx * 0.068,
                fontWeight: FontWeight.w400),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp2.paint(canvas, Offset(tx - tp2.width / 2, ty - tp2.height / 2));
      }
    }

    final nowAngle = _toAngle(nowLocal); // hand position uses local time
    final handOuter = Offset(
      center.dx + (outerR + cx * 0.055) * math.cos(nowAngle),
      center.dy + (outerR + cx * 0.055) * math.sin(nowAngle),
    );
    final handInner = Offset(
      center.dx + innerR * 0.45 * math.cos(nowAngle + math.pi),
      center.dy + innerR * 0.45 * math.sin(nowAngle + math.pi),
    );
    canvas.drawLine(handInner, handOuter,
        Paint()
          ..color       = Colors.white.withOpacity(0.3)
          ..strokeWidth = 5
          ..strokeCap   = StrokeCap.round
          ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawLine(handInner, handOuter,
        Paint()
          ..color       = Colors.white.withOpacity(0.85)
          ..strokeWidth = 1.8
          ..strokeCap   = StrokeCap.round);
    canvas.drawCircle(center, cx * 0.030, Paint()..color = Colors.white.withOpacity(0.9));
    canvas.drawCircle(center, cx * 0.018, Paint()..color = const Color(0xFF012618));
    canvas.drawCircle(center, cx * 0.010, Paint()..color = Colors.white.withOpacity(0.9));
  }

  String _shortName(String name) {
    const abbr = {'SunRise': 'Rise', 'SunSet': 'Set', 'Ishraq': 'Ishrq'};
    return abbr[name] ?? name;
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.nowUtc.second  != nowUtc.second  ||
          old.nowUtc.minute  != nowUtc.minute  ||
          old.pulse          != pulse          ||
          old.activeIndex    != activeIndex;
}