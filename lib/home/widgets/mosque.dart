import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  MosqueIllustration – rich, responsive, animated
// ═══════════════════════════════════════════════════════════════════════════════
class MosqueIllustration extends StatefulWidget {
  final Color accentColor;
  final double? height;

  const MosqueIllustration({
    super.key,
    this.accentColor = const Color(0xFF4CAF82),
    this.height,
  });

  @override
  State<MosqueIllustration> createState() => _MosqueIllustrationState();
}

class _MosqueIllustrationState extends State<MosqueIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _sky;
  late final AnimationController _twinkle;

  @override
  void initState() {
    super.initState();
    _sky = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);
    _twinkle = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sky.dispose();
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      final h = widget.height ?? w * 0.62;
      return AnimatedBuilder(
        animation: Listenable.merge([_sky, _twinkle]),
        builder: (_, __) => CustomPaint(
          size: Size(w, h),
          painter: _MosquePainter(
            accent: widget.accentColor,
            t: _sky.value,
            twinkle: _twinkle.value,
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
class _MosquePainter extends CustomPainter {
  final Color accent;
  final double t;       // 0→1 slow sky animation
  final double twinkle; // 0→1 star twinkle

  const _MosquePainter({
    required this.accent,
    required this.t,
    required this.twinkle,
  });

  // ── Paint helpers ────────────────────────────────────────────────────────────
  Paint _fill(Color c) => Paint()..color = c..style = PaintingStyle.fill;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  // ── Derived palette ───────────────────────────────────────────────────────────
  Color get _gold    => accent;
  Color get _goldDim => accent.withOpacity(0.55 + t * 0.20);
  Color get _stone   => const Color(0xFF1B4D35);    // deep green-teal building
  Color get _stoneMid=> const Color(0xFF236B47);    // lighter panels
  Color get _stoneHi => const Color(0xFF2E8A5C);    // highlight edges
  Color get _stoneDark=> const Color(0xFF0D2E1C);   // shadow / recess
  Color get _glow    => accent.withOpacity(0.07 + t * 0.07);
  Color get _starC   => accent.withOpacity(0.45 + twinkle * 0.55);
  Color get _moonC   => accent.withOpacity(0.88 + twinkle * 0.12);

  // ── Sky colours (deep dusk-to-night) ─────────────────────────────────────────
  static const _skyA = Color(0xFF011A0D);
  static const _skyB = Color(0xFF012E18);
  static const _skyC = Color(0xFF013220);

  @override
  void paint(Canvas canvas, Size sz) {
    final w = sz.width;
    final h = sz.height;
    final gY = h * 0.76; // ground line

    _drawSky(canvas, sz);
    _drawStars(canvas, w, gY);
    _drawMoon(canvas, w, h);
    _drawLights(canvas, w, h, gY); // ambient glow

    // ── Building (back → front) ───────────────────────────────────────────────
    _drawMinarets(canvas, w, h, gY);
    _drawWings(canvas, w, h, gY);
    _drawMainBody(canvas, w, h, gY);
    _drawDomes(canvas, w, h, gY);
    _drawFacadeDetail(canvas, w, h, gY);

    _drawPlatform(canvas, w, h, gY);
    _drawReflection(canvas, w, h, gY);
    _drawWindowGlow(canvas, w, h, gY);
  }

  // ── Sky gradient ──────────────────────────────────────────────────────────────
  void _drawSky(Canvas canvas, Size sz) {
    final r = Rect.fromLTWH(0, 0, sz.width, sz.height);
    canvas.drawRect(r,
        _fill(Colors.transparent)
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_skyA, _skyB, _skyC],
            stops: [0.0, 0.5, 1.0],
          ).createShader(r));
  }

  // ── Star field ───────────────────────────────────────────────────────────────
  static const _stars = [
    [0.05, 0.04, 1.1], [0.12, 0.13, 0.7], [0.20, 0.02, 1.3],
    [0.29, 0.08, 0.8], [0.37, 0.01, 1.2], [0.45, 0.15, 0.6],
    [0.54, 0.04, 1.0], [0.62, 0.10, 1.4], [0.71, 0.03, 0.9],
    [0.78, 0.17, 0.7], [0.87, 0.06, 1.2], [0.94, 0.12, 0.8],
    [0.08, 0.23, 0.6], [0.24, 0.27, 0.9], [0.48, 0.20, 0.7],
    [0.65, 0.25, 1.1], [0.82, 0.22, 0.8], [0.96, 0.29, 0.6],
    [0.16, 0.34, 0.5], [0.90, 0.37, 0.7], [0.33, 0.18, 0.9],
    [0.57, 0.31, 0.6], [0.74, 0.08, 1.0], [0.42, 0.28, 0.7],
  ];

  void _drawStars(Canvas canvas, double w, double gY) {
    for (int i = 0; i < _stars.length; i++) {
      final x = _stars[i][0] * w;
      final y = _stars[i][1] * gY;
      final r = _stars[i][2] * (w / 380);
      final tw = (math.sin(twinkle * math.pi * 2 + i * 1.1) * 0.35 + 0.65);
      final paint = _fill(_starC.withOpacity(_starC.opacity * tw));
      // Cross sparkle for brighter stars
      if (_stars[i][2] > 1.0) {
        canvas.drawLine(Offset(x - r * 2.5, y), Offset(x + r * 2.5, y),
            _stroke(_starC.withOpacity(0.25 * tw), r * 0.4));
        canvas.drawLine(Offset(x, y - r * 2.5), Offset(x, y + r * 2.5),
            _stroke(_starC.withOpacity(0.25 * tw), r * 0.4));
      }
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  // ── Crescent moon ──────────────────────────────────────────────────────────────
  void _drawMoon(Canvas canvas, double w, double h) {
    final cx = w * 0.82;
    final cy = h * 0.10;
    final r  = w * 0.050;
    // Glow
    canvas.drawCircle(Offset(cx, cy), r * 2.0,
        _fill(_moonC.withOpacity(0.05 + twinkle * 0.04))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8));
    canvas.drawCircle(Offset(cx, cy), r * 1.4,
        _fill(_moonC.withOpacity(0.04))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4));
    // Crescent
    final outer = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    final cut = Path()..addOval(
        Rect.fromCircle(center: Offset(cx + r * 0.52, cy - r * 0.08), radius: r * 0.80));
    final crescent = Path.combine(PathOperation.difference, outer, cut);
    canvas.drawPath(crescent,
        _fill(_moonC.withOpacity(0.30))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5));
    canvas.drawPath(crescent, _fill(_moonC));
    // Star near moon
    final sx = cx + r * 1.55;
    final sy = cy - r * 0.95;
    final sr = r * 0.14;
    canvas.drawCircle(Offset(sx, sy), sr,
        _fill(_moonC.withOpacity(0.80 + twinkle * 0.20)));
  }

  // ── Ambient glow ──────────────────────────────────────────────────────────────
  void _drawLights(Canvas canvas, double w, double h, double gY) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, gY + h * 0.02),
          width: w * 0.80, height: h * 0.14),
      _fill(_glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.07),
    );
  }

  // ── Minarets ──────────────────────────────────────────────────────────────────
  void _drawMinarets(Canvas canvas, double w, double h, double gY) {
    for (final side in [-1.0, 1.0]) {
      final cx  = w * 0.5 + side * w * 0.345;
      final mW  = w * 0.040;
      final topY = h * 0.035;

      // Shadow fill on inner side
      final shPath = Path()
        ..moveTo(cx + side * mW * 0.5, topY + mW * 2.8)
        ..lineTo(cx + side * mW * 0.65, topY + mW * 2.8)
        ..lineTo(cx + side * mW * 0.68, gY)
        ..lineTo(cx + side * mW * 0.5, gY)
        ..close();
      canvas.drawPath(shPath, _fill(_stoneDark));

      // Main shaft (tapered)
      final shaft = Path()
        ..moveTo(cx - mW * 0.58, gY)
        ..lineTo(cx - mW * 0.38, topY + mW * 2.8)
        ..lineTo(cx + mW * 0.38, topY + mW * 2.8)
        ..lineTo(cx + mW * 0.58, gY)
        ..close();
      canvas.drawPath(shaft, _fill(_stone));
      canvas.drawPath(shaft, _stroke(_stoneHi.withOpacity(0.3), w * 0.008));

      // Vertical grooves
      for (final xf in [-0.14, 0.14]) {
        canvas.drawLine(
          Offset(cx + xf * mW * 2, topY + mW * 3.0),
          Offset(cx + xf * mW * 2, gY - mW * 0.3),
          _stroke(_stoneDark.withOpacity(0.55), w * 0.005),
        );
      }

      // Decorative rings
      for (final frac in [0.28, 0.48, 0.66]) {
        final by = topY + mW * 2.8 + (gY - topY - mW * 2.8) * frac;
        final bw = mW * (0.52 + frac * 0.08);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, by), width: bw * 2, height: mW * 0.32),
            const Radius.circular(2),
          ),
          _fill(_stoneDark),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, by), width: bw * 2, height: mW * 0.32),
            const Radius.circular(2),
          ),
          _stroke(_goldDim.withOpacity(0.45), w * 0.005),
        );
      }

      // Lower balcony
      _balcony(canvas, cx, topY + mW * 2.8, mW, w);

      // Upper narrow shaft
      final upper = Path()
        ..moveTo(cx - mW * 0.30, topY + mW * 2.8)
        ..lineTo(cx - mW * 0.22, topY + mW * 0.9)
        ..lineTo(cx + mW * 0.22, topY + mW * 0.9)
        ..lineTo(cx + mW * 0.30, topY + mW * 2.8)
        ..close();
      canvas.drawPath(upper, _fill(_stoneMid));
      canvas.drawPath(upper, _stroke(_stoneHi.withOpacity(0.3), w * 0.005));

      // Upper balcony
      _balcony(canvas, cx, topY + mW * 0.9, mW * 0.72, w);

      // Pointed finial cap
      _minaretCap(canvas, cx, topY, mW, w);

      // Gold crescent on top
      _smallCrescent(canvas, Offset(cx, topY - mW * 0.38), mW * 0.30);
    }
  }

  void _balcony(Canvas canvas, double cx, double y, double mW, double sw) {
    // Corbels
    for (final side in [-1.0, 1.0]) {
      final p = Path()
        ..moveTo(cx + side * mW * 0.26, y)
        ..lineTo(cx + side * mW * 1.08, y)
        ..lineTo(cx + side * mW * 0.85, y + mW * 0.38)
        ..lineTo(cx + side * mW * 0.26, y + mW * 0.38)
        ..close();
      canvas.drawPath(p, _fill(_stoneDark));
    }
    // Slab
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, y), width: mW * 2.5, height: mW * 0.30),
        const Radius.circular(2),
      ),
      _fill(_stoneHi),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, y), width: mW * 2.5, height: mW * 0.30),
        const Radius.circular(2),
      ),
      _stroke(_goldDim.withOpacity(0.5), sw * 0.006),
    );
    // Railing
    canvas.drawLine(Offset(cx - mW * 1.15, y - mW * 0.38),
        Offset(cx + mW * 1.15, y - mW * 0.38),
        _stroke(_gold.withOpacity(0.50), sw * 0.006));
    for (final xf in [-0.75, -0.38, 0.0, 0.38, 0.75]) {
      canvas.drawLine(
        Offset(cx + xf * mW, y - mW * 0.38),
        Offset(cx + xf * mW, y - mW * 0.05),
        _stroke(_gold.withOpacity(0.35), sw * 0.004),
      );
    }
  }

  void _minaretCap(Canvas canvas, double cx, double topY, double mW, double sw) {
    final cap = Path()
      ..moveTo(cx - mW * 0.22, topY + mW * 0.9)
      ..cubicTo(
          cx - mW * 0.30, topY + mW * 0.55,
          cx - mW * 0.16, topY + mW * 0.18,
          cx, topY)
      ..cubicTo(
          cx + mW * 0.16, topY + mW * 0.18,
          cx + mW * 0.30, topY + mW * 0.55,
          cx + mW * 0.22, topY + mW * 0.9)
      ..close();
    canvas.drawPath(cap, _fill(_stoneMid));
    canvas.drawPath(cap, _fill(_gold.withOpacity(0.12)));
    canvas.drawPath(cap, _stroke(_goldDim.withOpacity(0.60), sw * 0.007));
  }

  // ── Side wings ────────────────────────────────────────────────────────────────
  void _drawWings(Canvas canvas, double w, double h, double gY) {
    for (final side in [-1.0, 1.0]) {
      final wL = w * 0.5 + side * w * 0.155;
      final wR = w * 0.5 + side * w * 0.310;
      final left  = math.min(wL, wR);
      final right = math.max(wL, wR);
      final wingH = h * 0.175;
      final topY  = gY - wingH;

      // Wall
      canvas.drawRect(Rect.fromLTRB(left, topY, right, gY), _fill(_stone));
      // Shadow stripe
      canvas.drawRect(
        Rect.fromLTRB(
          side > 0 ? right - w * 0.014 : left,
          topY, side > 0 ? right : left + w * 0.014, gY,
        ),
        _fill(_stoneDark),
      );

      // Cornice
      canvas.drawRect(
        Rect.fromLTRB(left - w * 0.003, topY - h * 0.014,
            right + w * 0.003, topY + h * 0.010),
        _fill(_stoneHi),
      );
      canvas.drawRect(
        Rect.fromLTRB(left - w * 0.003, topY - h * 0.014,
            right + w * 0.003, topY + h * 0.010),
        _stroke(_goldDim.withOpacity(0.45), w * 0.006),
      );

      // Arched window on wing
      final wx = (left + right) / 2;
      final ww = (right - left) * 0.38;
      final wh = wingH * 0.52;
      final wy = gY - wh - wingH * 0.14;
      _arch(canvas, wx, wy, ww, wh, w, small: true);

      // Wing dome
      final domeR = (right - left) * 0.40;
      _onionDome(canvas, Offset(wx, topY), domeR, w, main: false);
      _smallCrescent(canvas, Offset(wx, topY - domeR * 1.06), domeR * 0.24);
    }
  }

  // ── Main body ─────────────────────────────────────────────────────────────────
  void _drawMainBody(Canvas canvas, double w, double h, double gY) {
    final bW = w * 0.31;
    final bH = h * 0.32;
    final left = w * 0.5 - bW / 2;
    final topY = gY - bH;

    // Wall
    canvas.drawRect(Rect.fromLTRB(left, topY, left + bW, gY), _fill(_stone));

    // Right shadow
    canvas.drawRect(
      Rect.fromLTRB(left + bW - w * 0.014, topY, left + bW, gY),
      _fill(_stoneDark),
    );

    // Cornice
    canvas.drawRect(
      Rect.fromLTRB(left - w * 0.005, topY - h * 0.017,
          left + bW + w * 0.005, topY + h * 0.012),
      _fill(_stoneHi),
    );
    canvas.drawRect(
      Rect.fromLTRB(left - w * 0.005, topY - h * 0.017,
          left + bW + w * 0.005, topY + h * 0.012),
      _stroke(_gold.withOpacity(0.45), w * 0.008),
    );

    // Gold border
    canvas.drawRect(
      Rect.fromLTRB(left, topY, left + bW, gY),
      _stroke(_gold.withOpacity(0.28), w * 0.009),
    );

    // Muqarnas row
    _muqarnas(canvas, left, topY + bH * 0.14, bW, h * 0.030, w);

    // Grand doorway
    _grandDoor(canvas, w * 0.5, gY, bW * 0.44, bH * 0.76, gY, w);

    // Side windows
    for (final xf in [0.26, 0.74]) {
      final wx = left + bW * xf;
      final ww = bW * 0.17;
      final wh = bH * 0.38;
      final wy = gY - wh - bH * 0.13;
      _arch(canvas, wx, wy, ww, wh, w, small: false);
    }
  }

  void _muqarnas(Canvas canvas, double left, double y,
      double totalW, double cellH, double sw) {
    const count = 10;
    final cellW = totalW / count;
    for (int i = 0; i < count; i++) {
      final x = left + i * cellW + cellW / 2;
      final p = Path()
        ..moveTo(x - cellW * 0.5, y + cellH)
        ..lineTo(x - cellW * 0.5, y + cellH * 0.40)
        ..quadraticBezierTo(x, y - cellH * 0.06, x + cellW * 0.5, y + cellH * 0.40)
        ..lineTo(x + cellW * 0.5, y + cellH)
        ..close();
      canvas.drawPath(p, _fill(i.isEven ? _stone : _stoneDark));
      canvas.drawPath(p, _stroke(_gold.withOpacity(0.28), sw * 0.005));
    }
  }

  void _grandDoor(Canvas canvas, double cx, double baseY,
      double dW, double dH, double gY, double sw) {
    final left = cx - dW / 2;
    final top  = baseY - dH;

    // Door recess
    final door = Path()
      ..moveTo(left, baseY)
      ..lineTo(left, top + dW * 0.5)
      ..arcTo(Rect.fromLTRB(left, top, left + dW, top + dW),
          math.pi, math.pi, false)
      ..lineTo(left + dW, baseY)
      ..close();
    canvas.drawPath(door, _fill(_stoneDark.withOpacity(0.85)));
    canvas.drawPath(door, _stroke(_gold.withOpacity(0.55), sw * 0.011));

    // Iwan pointed arch
    final arch = Path()
      ..moveTo(left + dW * 0.08, top + dW * 0.50)
      ..cubicTo(left + dW * 0.08, top + dW * 0.10,
          cx - dW * 0.03, top - dW * 0.12, cx, top - dW * 0.40)
      ..cubicTo(cx + dW * 0.03, top - dW * 0.12,
          left + dW * 0.92, top + dW * 0.10, left + dW * 0.92, top + dW * 0.50);
    canvas.drawPath(arch, _stroke(_gold.withOpacity(0.70), sw * 0.010));

    // Inner glow
    canvas.drawRect(
      Rect.fromLTRB(left + dW * 0.20, top + dW * 0.50, left + dW * 0.80, baseY),
      _fill(_gold.withOpacity(0.04 + t * 0.05)),
    );

    // Door panels
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 2; col++) {
        final px = left + dW * (0.18 + col * 0.36);
        final py = baseY - dH * (0.18 + row * 0.20);
        canvas.drawRect(
          Rect.fromCenter(center: Offset(px, py),
              width: dW * 0.28, height: dH * 0.13),
          _stroke(_gold.withOpacity(0.22), sw * 0.005),
        );
      }
    }

    // Steps
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTRB(left - i * dW * 0.04, baseY + i * dW * 0.052,
            left + dW + i * dW * 0.04, baseY + (i + 1) * dW * 0.052),
        _fill(Color.lerp(_stone, _gold, 0.04)!),
      );
    }
  }

  void _arch(Canvas canvas, double cx, double topY,
      double aW, double aH, double sw, {required bool small}) {
    final left = cx - aW / 2;
    final p = Path()
      ..moveTo(left, topY + aW / 2)
      ..arcTo(Rect.fromLTRB(left, topY, left + aW, topY + aW),
          math.pi, math.pi, false)
      ..lineTo(left + aW, topY + aH)
      ..lineTo(left, topY + aH)
      ..close();
    canvas.drawPath(p, _fill(_stoneDark.withOpacity(small ? 0.72 : 0.90)));
    canvas.drawPath(p,
        _stroke(_gold.withOpacity(small ? 0.35 : 0.52),
            sw * (small ? 0.006 : 0.009)));
    // Grill lines
    if (!small) {
      for (int i = 1; i <= 3; i++) {
        canvas.drawLine(
          Offset(left + aW * i / 4, topY + aW * 0.5),
          Offset(left + aW * i / 4, topY + aH),
          _stroke(_gold.withOpacity(0.14), sw * 0.004),
        );
      }
    }
  }

  // ── Domes ─────────────────────────────────────────────────────────────────────
  void _drawDomes(Canvas canvas, double w, double h, double gY) {
    final mainBase = Offset(w * 0.5, gY - h * 0.32);
    final mainR = w * 0.162;
    _onionDome(canvas, mainBase, mainR, w, main: true);
    _smallCrescent(canvas, Offset(w * 0.5, mainBase.dy - mainR * 1.12), mainR * 0.42);
  }

  void _onionDome(Canvas canvas, Offset base, double r, double sw,
      {required bool main}) {
    final drumH = r * 0.30;
    final drumW = r * (main ? 1.65 : 1.55);

    // Drum
    canvas.drawRect(
      Rect.fromCenter(center: Offset(base.dx, base.dy + drumH / 2),
          width: drumW, height: drumH),
      _fill(_stone),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(base.dx, base.dy + drumH / 2),
          width: drumW, height: drumH),
      _stroke(_gold.withOpacity(main ? 0.48 : 0.32), sw * 0.007),
    );

    // Dome shape
    final dome = Path();
    dome.moveTo(base.dx - drumW / 2, base.dy);
    dome.cubicTo(
      base.dx - r * 1.05, base.dy - r * 0.28,
      base.dx - r * 0.95, base.dy - r * 0.90,
      base.dx, base.dy - r * (main ? 1.08 : 1.02),
    );
    dome.cubicTo(
      base.dx + r * 0.95, base.dy - r * 0.90,
      base.dx + r * 1.05, base.dy - r * 0.28,
      base.dx + drumW / 2, base.dy,
    );
    dome.close();

    // Shadow half
    final shadow = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(base.dx + r * 0.08, base.dy - r * 0.28,
          base.dx + r * 0.95, base.dy - r * 0.90,
          base.dx, base.dy - r * (main ? 1.08 : 1.02))
      ..cubicTo(base.dx + r * 0.95, base.dy - r * 0.90,
          base.dx + r * 1.05, base.dy - r * 0.28,
          base.dx + drumW / 2, base.dy)
      ..close();

    canvas.drawPath(dome, _fill(_stone));
    canvas.drawPath(shadow, _fill(_stoneDark.withOpacity(0.28)));
    canvas.drawPath(dome, _fill(_gold.withOpacity(0.06 + t * 0.04)));
    canvas.drawPath(dome,
        _stroke(_gold.withOpacity(main ? 0.55 : 0.38),
            sw * (main ? 0.011 : 0.007)));

    // Rib lines
    final panelCount = main ? 12 : 8;
    for (int i = 0; i < panelCount; i++) {
      final angle = (i / panelCount) * math.pi;
      final rx = base.dx + r * math.cos(angle) * 0.88;
      final ryTop = base.dy - r * (main ? 0.90 : 0.84);
      canvas.drawLine(
        Offset(base.dx, ryTop),
        Offset(rx, base.dy),
        _stroke(_stoneDark.withOpacity(0.30),
            sw * (main ? 0.004 : 0.003)),
      );
    }

    // Highlight
    final hl = Path()
      ..moveTo(base.dx - r * 0.48, base.dy - r * 0.38)
      ..cubicTo(base.dx - r * 0.40, base.dy - r * 0.72,
          base.dx - r * 0.16, base.dy - r * 0.92,
          base.dx, base.dy - r * (main ? 1.08 : 1.02));
    canvas.drawPath(hl,
        _stroke(_stoneHi.withOpacity(0.55),
            sw * (main ? 0.007 : 0.004)));

    // Finial sphere
    canvas.drawCircle(
      Offset(base.dx, base.dy - r * (main ? 1.09 : 1.03)),
      r * (main ? 0.065 : 0.050),
      _fill(_gold),
    );
  }

  // ── Facade detail ─────────────────────────────────────────────────────────────
  void _drawFacadeDetail(Canvas canvas, double w, double h, double gY) {
    final bW = w * 0.31;
    final bH = h * 0.32;
    final left = w * 0.5 - bW / 2;
    final bandY = gY - bH + h * 0.030;

    canvas.drawRect(
        Rect.fromLTRB(left, bandY, left + bW, bandY + h * 0.020),
        _fill(_gold.withOpacity(0.10)));
    canvas.drawRect(
        Rect.fromLTRB(left, bandY, left + bW, bandY + h * 0.020),
        _stroke(_gold.withOpacity(0.42), w * 0.006));

    for (int i = 0; i < 8; i++) {
      final x = left + bW * (i + 0.5) / 8;
      canvas.drawLine(
        Offset(x, bandY + h * 0.003),
        Offset(x, bandY + h * 0.017),
        _stroke(_gold.withOpacity(0.25), w * 0.004),
      );
    }
  }

  // ── Ground platform ───────────────────────────────────────────────────────────
  void _drawPlatform(Canvas canvas, double w, double h, double gY) {
    // Main slab
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.03, gY, w * 0.97, gY + h * 0.024),
        const Radius.circular(2),
      ),
      _fill(_stone),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.03, gY, w * 0.97, gY + h * 0.024),
        const Radius.circular(2),
      ),
      _stroke(_gold.withOpacity(0.38), w * 0.006),
    );
    // Paving lines
    for (int i = 1; i < 9; i++) {
      canvas.drawLine(
        Offset(w * 0.03 + (w * 0.94) * i / 9, gY),
        Offset(w * 0.03 + (w * 0.94) * i / 9, gY + h * 0.024),
        _stroke(_stoneDark.withOpacity(0.4), w * 0.003),
      );
    }
    // Descending steps
    for (int i = 1; i <= 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            w * (0.03 + i * 0.022), gY + h * 0.024 * i,
            w * (0.97 - i * 0.022), gY + h * 0.024 * (i + 1),
          ),
          const Radius.circular(2),
        ),
        _fill(Color.lerp(_stone, _gold, 0.04)!),
      );
    }
  }

  // ── Water reflection ──────────────────────────────────────────────────────────
  void _drawReflection(Canvas canvas, double w, double h, double gY) {
    final waterY = gY + h * 0.098;
    if (waterY >= h) return;
    final rect = Rect.fromLTRB(0, waterY, w, h);
    canvas.drawRect(rect,
        _fill(_skyC)
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_gold.withOpacity(0.05), _skyA.withOpacity(0.02)],
          ).createShader(rect));

    // Ripple lines
    for (int i = 0; i < 5; i++) {
      final y  = waterY + (h - waterY) * (0.12 + i * 0.17);
      final xo = (t - 0.5) * w * 0.030 * (i.isEven ? 1 : -1);
      canvas.drawLine(
        Offset(w * 0.10 + xo, y), Offset(w * 0.90 + xo, y),
        _stroke(_gold.withOpacity(0.045 - i * 0.006), w * 0.006),
      );
    }

    // Blurred dome reflection
    canvas.save();
    canvas.translate(w / 2, waterY);
    canvas.scale(1, -0.50);
    canvas.translate(-w / 2, -(gY - waterY));
    final mainBase = Offset(w * 0.5, gY - h * 0.32);
    final mainR = w * 0.162;
    final ref = Path()
      ..moveTo(mainBase.dx - mainR * 1.0, mainBase.dy)
      ..cubicTo(mainBase.dx - mainR * 1.05, mainBase.dy - mainR * 0.28,
          mainBase.dx - mainR * 0.95, mainBase.dy - mainR * 0.90,
          mainBase.dx, mainBase.dy - mainR * 1.08)
      ..cubicTo(mainBase.dx + mainR * 0.95, mainBase.dy - mainR * 0.90,
          mainBase.dx + mainR * 1.05, mainBase.dy - mainR * 0.28,
          mainBase.dx + mainR * 1.0, mainBase.dy)
      ..close();
    canvas.drawPath(ref,
        _fill(_gold.withOpacity(0.07))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.restore();
  }

  // ── Window glow ───────────────────────────────────────────────────────────────
  void _drawWindowGlow(Canvas canvas, double w, double h, double gY) {
    final bW = w * 0.31;
    final bH = h * 0.32;
    final left = w * 0.5 - bW / 2;

    for (final xf in [0.26, 0.74]) {
      final wx = left + bW * xf;
      final wh = bH * 0.38;
      final wy = gY - wh - bH * 0.13;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(wx, wy + wh * 0.5),
            width: bW * 0.20, height: wh * 0.65),
        _fill(_gold.withOpacity(0.08 + t * 0.06))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.022),
      );
    }
    // Door glow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, gY - bH * 0.36),
          width: bW * 0.40, height: bH * 0.52),
      _fill(_gold.withOpacity(0.05 + t * 0.04))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.036),
    );
  }

  // ── Small crescent helper ─────────────────────────────────────────────────────
  void _smallCrescent(Canvas canvas, Offset center, double r) {
    if (r <= 0) return;
    final outer = Path()..addOval(Rect.fromCircle(center: center, radius: r));
    final cut = Path()..addOval(Rect.fromCircle(
        center: center.translate(r * 0.50, -r * 0.06), radius: r * 0.78));
    final cres = Path.combine(PathOperation.difference, outer, cut);
    canvas.drawPath(cres,
        _fill(_gold.withOpacity(0.35))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.25));
    canvas.drawPath(cres, _fill(_gold));
    // Star dot
    canvas.drawCircle(
      center.translate(r * 0.95, -r * 0.68), r * 0.20,
      _fill(_gold.withOpacity(0.88)),
    );
  }

  @override
  bool shouldRepaint(_MosquePainter old) =>
      old.t != t || old.twinkle != twinkle || old.accent != accent;
}