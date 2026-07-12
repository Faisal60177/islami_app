import 'package:flutter/material.dart';
import 'dart:math' as math;

class MosqueHeroWidget extends StatelessWidget {
  final double height;
  final String currentPrayer;

  const MosqueHeroWidget({
    super.key,
    required this.height,
    this.currentPrayer = '',
  });

  List<Color> _skyColors() {
    switch (currentPrayer) {
      case 'Fajr':
        return [const Color(0xFF0D0628), const Color(0xFF1A0A4A), const Color(0xFF3D1C6E), const Color(0xFF6B3A9E)];
      case 'Dhuhr':
        return [const Color(0xFF0D47A1), const Color(0xFF1565C0), const Color(0xFF5B8FD4), const Color(0xFF90B8E8)];
      case 'Asr':
        return [const Color(0xFFBF360C), const Color(0xFFE64A19), const Color(0xFFFF7043), const Color(0xFFFFB74D)];
      case 'Maghrib':
        return [const Color(0xFF311B92), const Color(0xFF6A1B9A), const Color(0xFFC62828), const Color(0xFFFF8F00)];
      case 'Isha':
        return [const Color(0xFF050510), const Color(0xFF0A0F2E), const Color(0xFF0D1B4A), const Color(0xFF1A2560)];
      default:
        return [const Color(0xFF0D0A2E), const Color(0xFF1A1060), const Color(0xFF2D1B8E), const Color(0xFF3D2A7A)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _MosquePainter(skyColors: _skyColors(), prayer: currentPrayer),
      ),
    );
  }
}

class _MosquePainter extends CustomPainter {
  final List<Color> skyColors;
  final String prayer;
  _MosquePainter({required this.skyColors, required this.prayer});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: skyColors,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // NOTE: anchors moved from h*0.13 -> h*0.17 so moon/sun clear the
    // status bar area (hero sits behind AppBar via extendBodyBehindAppBar).
    if (prayer == 'Isha' || prayer == 'Fajr' || prayer == '') {
      final rng = math.Random(99);
      for (int i = 0; i < 60; i++) {
        canvas.drawCircle(
          Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.52),
          rng.nextDouble() * 1.1 + 0.25,
          Paint()..color = Colors.white.withOpacity(rng.nextDouble() * 0.5 + 0.3),
        );
      }
      _drawCrescent(canvas, Offset(w * 0.10, h * 0.25), h * 0.056, skyColors[1]);
    } else if (prayer == 'Dhuhr') {
      _drawGlowingSun(canvas, Offset(w * 0.90, h * 0.25), h * 0.052, bright: true);
    } else if (prayer == 'Asr') {
      _drawGlowingSun(canvas, Offset(w * 0.76, h * 0.52), h * 0.090, bright: false);
    } else if (prayer == 'Maghrib') {
      _drawGlowingSun(canvas, Offset(w * 0.72, h * 0.58), h * 0.085, bright: false);
    }

    _hillLayer(canvas, w, h, h * 0.56, skyColors.last.withOpacity(0.30),
        [0.0, 0.15, 0.32, 0.50, 0.68, 0.85, 1.0],
        [0.02, 0.07, 0.03, 0.08, 0.04, 0.09, 0.02]);
    _hillLayer(canvas, w, h, h * 0.63, skyColors.last.withOpacity(0.52),
        [0.0, 0.12, 0.28, 0.48, 0.66, 0.82, 1.0],
        [0.03, 0.09, 0.04, 0.10, 0.05, 0.11, 0.03]);
    _hillLayer(canvas, w, h, h * 0.70, skyColors.last.withOpacity(0.72),
        [0.0, 0.10, 0.25, 0.45, 0.62, 0.80, 1.0],
        [0.04, 0.08, 0.03, 0.09, 0.04, 0.10, 0.04]);

    _drawMosque(canvas, size);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.60)],
          stops: const [0.60, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  void _drawCrescent(Canvas canvas, Offset c, double r, Color bg) {
    canvas.drawCircle(c, r, Paint()..color = Colors.white.withOpacity(0.92));
    canvas.drawCircle(
      Offset(c.dx + r * 0.40, c.dy - r * 0.06),
      r * 0.80,
      Paint()..color = bg,
    );
  }

  void _drawGlowingSun(Canvas canvas, Offset c, double r, {required bool bright}) {
    for (int i = 4; i >= 1; i--) {
      canvas.drawCircle(c, r * (1 + i * 0.38),
          Paint()..color = (bright ? Colors.white : const Color(0xFFFFD54F)).withOpacity(0.035 * i));
    }
    final paint = bright
        ? (Paint()..color = Colors.white.withOpacity(0.95))
        : (Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, const Color(0xFFFFD54F), const Color(0xFFFF6F00)],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(c, r, paint);
  }

  void _hillLayer(Canvas canvas, double w, double h,
      double yBase, Color color, List<double> xs, List<double> hs) {
    final path = Path()..moveTo(0, h);
    path.lineTo(0, yBase - hs[0] * h);
    for (int i = 0; i < xs.length - 1; i++) {
      final x2 = xs[i + 1] * w;
      final y2 = yBase - hs[i + 1] * h;
      final mx = (xs[i] * w + x2) / 2;
      final my = ((yBase - hs[i] * h) + y2) / 2 - h * 0.025;
      path.quadraticBezierTo(mx, my, x2, y2);
    }
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawMosque(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = _mosqueColor();
    final path  = Path();

    final groundY = h * 0.91;
    final baseY   = h * 0.68;
    final cx      = w * 0.50;

    final mw = w * 0.30;
    final mh = h * 0.23;
    path.addRect(Rect.fromLTWH(cx - mw / 2, baseY, mw, mh));

    _ogivalDome(path, cx, baseY, mw * 0.36, h * 0.155);
    _finial(path, cx, baseY - h * 0.155, h * 0.048, w * 0.010);

    final lwW = w * 0.115; final lwH = h * 0.115;
    final lwX = cx - mw / 2 - lwW;
    final lwY = baseY + mh - lwH;
    path.addRect(Rect.fromLTWH(lwX, lwY, lwW, lwH));
    _ogivalDome(path, lwX + lwW / 2, lwY, lwW * 0.42, lwH * 0.68);
    _finial(path, lwX + lwW / 2, lwY - lwH * 0.68, h * 0.026, w * 0.007);

    final rwX = cx + mw / 2;
    path.addRect(Rect.fromLTWH(rwX, lwY, lwW, lwH));
    _ogivalDome(path, rwX + lwW / 2, lwY, lwW * 0.42, lwH * 0.68);
    _finial(path, rwX + lwW / 2, lwY - lwH * 0.68, h * 0.026, w * 0.007);

    // Outer minarets shortened + moved down slightly so their shafts/finials
    // stay clear of the ring above and the status bar at the very top.
    final lmCX = cx - mw / 2 - lwW - w * 0.075;
    _minaret(path, lmCX, h * 0.32, h * 0.55, w * 0.021, groundY);
    final rmCX = cx + mw / 2 + lwW + w * 0.075;
    _minaret(path, rmCX, h * 0.32, h * 0.55, w * 0.021, groundY);

    final liCX = cx - mw * 0.48;
    _minaret(path, liCX, h * 0.38, h * 0.53, w * 0.014, groundY);
    final riCX = cx + mw * 0.48;
    _minaret(path, riCX, h * 0.38, h * 0.53, w * 0.014, groundY);

    _building(path, w * 0.03,  h * 0.73, w * 0.065, groundY);
    _building(path, w * 0.115, h * 0.76, w * 0.050, groundY);
    _building(path, w * 0.845, h * 0.75, w * 0.055, groundY);
    _building(path, w * 0.910, h * 0.72, w * 0.070, groundY);

    path.addRect(Rect.fromLTWH(0, groundY, w, h - groundY));

    canvas.drawPath(path, paint);
  }

  Color _mosqueColor() {
    switch (prayer) {
      case 'Dhuhr':   return const Color(0xFF062040).withOpacity(0.88);
      case 'Asr':     return const Color(0xFF3B0E00).withOpacity(0.88);
      case 'Maghrib': return const Color(0xFF1A0030).withOpacity(0.90);
      default:        return const Color(0xFF06060E).withOpacity(0.93);
    }
  }

  void _ogivalDome(Path path, double cx, double baseY, double halfW, double dh) {
    path.moveTo(cx - halfW, baseY);
    path.cubicTo(cx - halfW, baseY - dh * 0.38, cx - halfW * 0.28, baseY - dh * 0.88, cx, baseY - dh);
    path.cubicTo(cx + halfW * 0.28, baseY - dh * 0.88, cx + halfW, baseY - dh * 0.38, cx + halfW, baseY);
    path.close();
  }

  void _finial(Path path, double cx, double baseY, double len, double hw) {
    path.addRect(Rect.fromLTWH(cx - hw * 0.45, baseY - len, hw * 0.9, len));
    path.addOval(Rect.fromCircle(center: Offset(cx, baseY - len - hw), radius: hw));
  }

  void _minaret(Path path, double cx, double topY, double totalH,
      double hw, double groundY) {
    final shaftH = totalH * 0.76;
    path.addRect(Rect.fromLTWH(cx - hw, topY, hw * 2, shaftH));
    path.addRect(Rect.fromLTWH(cx - hw * 1.85, topY + shaftH * 0.58, hw * 3.70, hw * 0.75));
    path.addRect(Rect.fromLTWH(cx - hw * 1.55, topY + shaftH * 0.76, hw * 3.10, hw * 0.55));
    _ogivalDome(path, cx, topY, hw * 1.25, totalH * 0.24);
    path.addOval(Rect.fromCircle(
      center: Offset(cx, topY - totalH * 0.24 - hw * 0.9),
      radius: hw * 0.75,
    ));
  }

  void _building(Path path, double x, double y, double bw, double groundY) {
    path.addRect(Rect.fromLTWH(x, y, bw, groundY - y));
    path.addOval(Rect.fromCircle(center: Offset(x + bw / 2, y), radius: bw * 0.32));
  }

  @override
  bool shouldRepaint(_MosquePainter old) => old.prayer != prayer;
}