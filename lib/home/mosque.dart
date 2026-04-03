import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═════════════════════════════════════════════════════════════════════════════
class MosqueIllustration extends StatefulWidget {
  final Color accentColor;
  final double? height;
  const MosqueIllustration({
    super.key,
    this.accentColor = const Color(0xFFC0FF00),
    this.height,
  });
  @override
  State<MosqueIllustration> createState() => _MosqueIllustrationState();
}

class _MosqueIllustrationState extends State<MosqueIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      final h = widget.height ?? w * 0.58;
      return AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => CustomPaint(
          size: Size(w, h),
          painter: _MosquePainter(accent: widget.accentColor, t: _anim.value),
        ),
      );
    });
  }
}

class _MosquePainter extends CustomPainter {
  final Color accent;
  final double t; // 0→1 animation tick

  _MosquePainter({required this.accent, required this.t});

  // ── sky palette (always dark-green themed, matching app bg) ────────────────
  static const _skyTop    = Color(0xFF808000);
  static const _skyMid    = Color(0xFF808000);
  static const _skyGround = Color(0xFF808000);

  // stone colour for building – warm off-white with a tint of accent
  Color get _stone => Color.lerp(const Color(0xFF808000), accent.withOpacity(1), 0.08)!;
  Color get _stoneDark => Color.lerp(const Color(0xFF0E2218), accent.withOpacity(1), 0.05)!;
  Color get _stoneLight => Color.lerp(const Color(0xFF50C878), accent, 0.18)!;
  Color get _accentGold  => accent;
  Color get _accentDim   => accent.withOpacity(0.55 + t * 0.25);
  Color get _glowColor   => accent.withOpacity(0.06 + t * 0.08);
  Color get _starColor   => accent.withOpacity(0.50 + t * 0.50);
  Color get _moonColor   => accent.withOpacity(0.85 + t * 0.15);

  // handy paint factories
  Paint _fill(Color c) => Paint()..color = c..style = PaintingStyle.fill;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c..style = PaintingStyle.stroke..strokeWidth = w
    ..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gY = h * 0.80; // ground line

    _drawSky(canvas, size);
    _drawStarField(canvas, size, gY);
    _drawMoon(canvas, w, h);
    _drawAmbientGlow(canvas, w, h, gY);

    // building (back-to-front order)
    _drawMinarets(canvas, w, h, gY);
    _drawWings(canvas, w, h, gY);
    _drawMainFacade(canvas, w, h, gY);
    _drawDomes(canvas, w, h, gY);
    _drawFacadeDetails(canvas, w, h, gY);

    _drawPlatform(canvas, w, h, gY);
    _drawWaterReflection(canvas, w, h, gY);
    _drawLighting(canvas, w, h, gY);
  }

  // ── Sky ────────────────────────────────────────────────────────────────────
  void _drawSky(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(r, _fill(Colors.transparent)
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [_skyTop, _skyMid, _skyGround],
        stops: [0.0, 0.55, 1.0],
      ).createShader(r));
  }

  // ── Stars ──────────────────────────────────────────────────────────────────
  void _drawStarField(Canvas canvas, Size size, double gY) {
    final rng = [
      [0.04,0.05,1.3],[0.11,0.14,0.8],[0.19,0.03,1.1],[0.28,0.09,0.7],
      [0.36,0.02,1.4],[0.44,0.16,0.9],[0.53,0.05,0.6],[0.61,0.11,1.2],
      [0.70,0.04,0.8],[0.77,0.18,1.0],[0.86,0.07,1.3],[0.93,0.13,0.7],
      [0.07,0.24,0.6],[0.23,0.28,0.9],[0.47,0.21,0.7],[0.64,0.26,1.1],
      [0.81,0.23,0.8],[0.95,0.30,0.6],[0.15,0.35,0.5],[0.89,0.38,0.7],
    ];
    for (int i = 0; i < rng.length; i++) {
      final x = rng[i][0] * size.width;
      final y = rng[i][1] * gY;
      final r = rng[i][2] * (size.width / 400);
      final twinkle = (math.sin(t * math.pi * 2 + i * 0.9) * 0.3 + 0.7);
      canvas.drawCircle(Offset(x, y),
          r, _fill(_starColor.withOpacity(_starColor.opacity * twinkle)));
    }
  }

  // ── Crescent moon ──────────────────────────────────────────────────────────
  void _drawMoon(Canvas canvas, double w, double h) {
    final cx = w * 0.15;
    final cy = h * 0.13;
    final r  = w * 0.048;
    // glow
    canvas.drawCircle(Offset(cx, cy), r * 1.6,
        _fill(_moonColor.withOpacity(0.06 + t * 0.04)));
    // crescent
    final outer = Path()..addOval(Rect.fromCircle(center: Offset(cx,cy), radius: r));
    final cut   = Path()..addOval(Rect.fromCircle(
        center: Offset(cx + r*0.5, cy - r*0.1), radius: r*0.78));
    final cres  = Path.combine(PathOperation.difference, outer, cut);
    canvas.drawPath(cres, _fill(_moonColor.withOpacity(0.3 + t*0.05))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r*0.4));
    canvas.drawPath(cres, _fill(_moonColor));
  }

  // ── Ambient glow below building ────────────────────────────────────────────
  void _drawAmbientGlow(Canvas canvas, double w, double h, double gY) {
    final center = Offset(w * 0.5, gY);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w * 0.85, height: h * 0.18),
      _fill(_glowColor)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.08),
    );
  }

  // ── Minarets (tall, tapered, realistic) ───────────────────────────────────
  void _drawMinarets(Canvas canvas, double w, double h, double gY) {
    for (final side in [-1.0, 1.0]) {
      final cx   = w * 0.5 + side * w * 0.34;
      final mW   = w * 0.038;
      final topY = h * 0.04;

      // Shadow on inner side
      final shadowX = cx + side * mW * 0.5;
      final shadowPath = Path()
        ..moveTo(shadowX, topY + mW * 3)
        ..lineTo(shadowX + side * mW * 0.6, topY + mW * 3)
        ..lineTo(shadowX + side * mW * 0.6, gY)
        ..lineTo(shadowX, gY)
        ..close();
      canvas.drawPath(shadowPath, _fill(_stoneDark));

      // Main shaft – slightly tapered
      final shaftPath = Path()
        ..moveTo(cx - mW * 0.55, gY)
        ..lineTo(cx - mW * 0.38, topY + mW * 3.2)
        ..lineTo(cx + mW * 0.38, topY + mW * 3.2)
        ..lineTo(cx + mW * 0.55, gY)
        ..close();
      canvas.drawPath(shaftPath, _fill(_stone));
      canvas.drawPath(shaftPath, _stroke(_accentDim.withOpacity(0.3), w*0.008));

      // Panel lines on shaft (vertical grooves)
      for (final xf in [-0.12, 0.12]) {
        canvas.drawLine(
          Offset(cx + xf * mW * 2, topY + mW * 3.5),
          Offset(cx + xf * mW * 2, gY - mW * 0.2),
          _stroke(_stoneDark.withOpacity(0.6), w * 0.006),
        );
      }

      // Horizontal decorative rings
      for (final yFrac in [0.30, 0.50, 0.68]) {
        final by = topY + mW * 3.2 + (gY - topY - mW * 3.2) * yFrac;
        final bw = mW * (0.52 + yFrac * 0.06);
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, by), width: bw * 2, height: mW * 0.3),
          _fill(_stoneDark),
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, by), width: bw * 2, height: mW * 0.3),
          _stroke(_accentDim.withOpacity(0.4), w * 0.005),
        );
      }

      // Balcony (muezzin gallery)
      final balcY = topY + mW * 3.0;
      _drawBalcony(canvas, cx, balcY, mW, w);

      // Upper shaft (narrow) above balcony
      final upperPath = Path()
        ..moveTo(cx - mW * 0.28, balcY)
        ..lineTo(cx - mW * 0.22, topY + mW * 1.0)
        ..lineTo(cx + mW * 0.22, topY + mW * 1.0)
        ..lineTo(cx + mW * 0.28, balcY)
        ..close();
      canvas.drawPath(upperPath, _fill(_stoneLight));
      canvas.drawPath(upperPath, _stroke(_accentDim.withOpacity(0.3), w*0.006));

      // Second (mini) balcony
      _drawBalcony(canvas, cx, topY + mW * 1.0, mW * 0.7, w);

      // Pointed finial cap
      _drawMinaretCap(canvas, cx, topY, mW, w);

      // Gold crescent on very top
      _drawSmallCrescent(canvas, Offset(cx, topY - mW * 0.45), mW * 0.32);
    }
  }

  void _drawBalcony(Canvas canvas, double cx, double y, double mW, double w) {
    // Bracket corbels
    for (final side in [-1.0, 1.0]) {
      final bPath = Path()
        ..moveTo(cx + side * mW * 0.25, y)
        ..lineTo(cx + side * mW * 1.05, y)
        ..lineTo(cx + side * mW * 0.80, y + mW * 0.35)
        ..lineTo(cx + side * mW * 0.25, y + mW * 0.35)
        ..close();
      canvas.drawPath(bPath, _fill(_stoneDark));
    }
    // Floor slab
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, y), width: mW * 2.4, height: mW * 0.28),
        Radius.circular(mW * 0.05),
      ),
      _fill(_stoneLight),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, y), width: mW * 2.4, height: mW * 0.28),
        Radius.circular(mW * 0.05),
      ),
      _stroke(_accentDim.withOpacity(0.5), w * 0.008),
    );
    // Railing
    canvas.drawLine(
      Offset(cx - mW * 1.1, y - mW * 0.35),
      Offset(cx + mW * 1.1, y - mW * 0.35),
      _stroke(_accentGold.withOpacity(0.55), w * 0.007),
    );
    // Railing posts
    for (final xf in [-0.7, -0.35, 0.0, 0.35, 0.7]) {
      canvas.drawLine(
        Offset(cx + xf * mW, y - mW * 0.35),
        Offset(cx + xf * mW, y - mW * 0.08),
        _stroke(_accentGold.withOpacity(0.40), w * 0.005),
      );
    }
  }

  void _drawMinaretCap(Canvas canvas, double cx, double topY, double mW, double w) {
    // Ribbed onion-dome cap
    final capPath = Path()
      ..moveTo(cx - mW * 0.22, topY + mW * 1.0)
      ..cubicTo(
        cx - mW * 0.32, topY + mW * 0.6,
        cx - mW * 0.18, topY + mW * 0.2,
        cx, topY,
      )
      ..cubicTo(
        cx + mW * 0.18, topY + mW * 0.2,
        cx + mW * 0.32, topY + mW * 0.6,
        cx + mW * 0.22, topY + mW * 1.0,
      )
      ..close();
    canvas.drawPath(capPath, _fill(_stoneLight));
    canvas.drawPath(capPath, _fill(_accentGold.withOpacity(0.12)));
    canvas.drawPath(capPath, _stroke(_accentDim.withOpacity(0.6), w * 0.008));
  }

  // ── Side wings of mosque ───────────────────────────────────────────────────
  void _drawWings(Canvas canvas, double w, double h, double gY) {
    for (final side in [-1.0, 1.0]) {
      final wingL = w * 0.5 + side * w * 0.14;
      final wingR = w * 0.5 + side * w * 0.305;
      final left  = math.min(wingL, wingR);
      final right = math.max(wingL, wingR);
      final wingH = h * 0.17;
      final topY  = gY - wingH;

      // Wall with shadow
      canvas.drawRect(Rect.fromLTRB(left, topY, right, gY), _fill(_stone));
      // Shadow on one side
      canvas.drawRect(
        Rect.fromLTRB(side > 0 ? right - w*0.012 : left,
            topY, side > 0 ? right : left + w*0.012, gY),
        _fill(_stoneDark),
      );
      canvas.drawRect(
        Rect.fromLTRB(left, topY, right, gY),
        _stroke(_accentDim.withOpacity(0.2), w * 0.007),
      );

      // Decorative top cornice
      canvas.drawRect(
        Rect.fromLTRB(left - w*0.003, topY - h*0.012, right + w*0.003, topY + h*0.008),
        _fill(_stoneLight),
      );
      canvas.drawRect(
        Rect.fromLTRB(left - w*0.003, topY - h*0.012, right + w*0.003, topY + h*0.008),
        _stroke(_accentDim.withOpacity(0.4), w*0.006),
      );

      // Small arched window on wing
      final wx = (left + right) / 2;
      final wW = (right - left) * 0.35;
      final wH = wingH * 0.50;
      final wY = gY - wH - wingH * 0.15;
      _drawArch(canvas, wx, wY, wW, wH, gY, w, isSmall: true);

      // Wing dome
      final domeC = Offset(wx, topY);
      final domeR = (right - left) * 0.38;
      _drawOnionDome(canvas, domeC, domeR, w, isMain: false);
      _drawSmallCrescent(canvas, Offset(wx, topY - domeR * 1.05), domeR * 0.22);
    }
  }

  // ── Main facade ────────────────────────────────────────────────────────────
  void _drawMainFacade(Canvas canvas, double w, double h, double gY) {
    final bW   = w * 0.30;
    final bH   = h * 0.30;
    final left = w * 0.5 - bW / 2;
    final topY = gY - bH;

    // Main wall
    canvas.drawRect(Rect.fromLTRB(left, topY, left + bW, gY), _fill(_stone));
    // Right-side shadow
    canvas.drawRect(
      Rect.fromLTRB(left + bW - w*0.012, topY, left + bW, gY),
      _fill(_stoneDark),
    );

    // Horizontal cornice
    canvas.drawRect(
      Rect.fromLTRB(left - w*0.004, topY - h*0.016, left+bW+w*0.004, topY+h*0.010),
      _fill(_stoneLight),
    );
    canvas.drawRect(
      Rect.fromLTRB(left - w*0.004, topY - h*0.016, left+bW+w*0.004, topY+h*0.010),
      _stroke(_accentGold.withOpacity(0.45), w*0.008),
    );

    // Gold accent border on facade
    canvas.drawRect(
      Rect.fromLTRB(left, topY, left + bW, gY),
      _stroke(_accentGold.withOpacity(0.30), w * 0.010),
    );

    // Muqarnas band (decorative row of small pointed arches)
    _drawMuqarnas(canvas, left, topY + bH * 0.13, bW, h * 0.028, w);

    // Main grand arch doorway
    _drawGrandDoor(canvas, w * 0.5, gY, bW * 0.42, bH * 0.78, gY, w);

    // Two side arched windows
    for (final xf in [0.27, 0.73]) {
      final wx = left + bW * xf;
      final wW = bW * 0.16;
      final wH = bH * 0.38;
      final wY = gY - wH - bH * 0.12;
      _drawArch(canvas, wx, wY, wW, wH, gY, w, isSmall: false);
    }
  }

  void _drawMuqarnas(Canvas canvas, double left, double y, double totalW,
      double h, double sw) {
    final count = 9;
    final cellW = totalW / count;
    for (int i = 0; i < count; i++) {
      final x = left + i * cellW + cellW / 2;
      final archPath = Path()
        ..moveTo(x - cellW * 0.5, y + h)
        ..lineTo(x - cellW * 0.5, y + h * 0.45)
        ..quadraticBezierTo(x, y - h * 0.05, x + cellW * 0.5, y + h * 0.45)
        ..lineTo(x + cellW * 0.5, y + h)
        ..close();
      canvas.drawPath(archPath, _fill(i.isEven ? _stone : _stoneDark));
      canvas.drawPath(archPath, _stroke(_accentGold.withOpacity(0.30), sw*0.006));
    }
  }

  void _drawGrandDoor(Canvas canvas, double cx, double baseY, double dW,
      double dH, double gY, double sw) {
    final left = cx - dW / 2;
    final top  = baseY - dH;

    // Door recess (darker)
    final doorPath = Path()
      ..moveTo(left, baseY)
      ..lineTo(left, top + dW * 0.5)
      ..arcTo(Rect.fromLTRB(left, top, left + dW, top + dW),
          math.pi, math.pi, false)
      ..lineTo(left + dW, baseY)
      ..close();
    canvas.drawPath(doorPath, _fill(_stoneDark.withOpacity(0.8)));
    canvas.drawPath(doorPath, _stroke(_accentGold.withOpacity(0.5), sw * 0.012));

    // Pointed arch overlay (iwan style)
    final archH = dW * 0.55;
    final archPath = Path()
      ..moveTo(left + dW * 0.08, top + dW * 0.5)
      ..cubicTo(
        left + dW * 0.08, top + dW * 0.15,
        cx - dW * 0.02,  top - archH * 0.1,
        cx,              top - archH * 0.35,
      )
      ..cubicTo(
        cx + dW * 0.02,  top - archH * 0.1,
        left + dW * 0.92, top + dW * 0.15,
        left + dW * 0.92, top + dW * 0.5,
      );
    canvas.drawPath(archPath, _stroke(_accentGold.withOpacity(0.65), sw * 0.011));

    // Inner glow from door light
    final innerRect = Rect.fromLTRB(left + dW*0.18, top + dW*0.5, left+dW*0.82, baseY);
    canvas.drawRect(innerRect,
        _fill(_accentGold.withOpacity(0.05 + t * 0.04)));

    // Door panels
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 2; col++) {
        final px = left + dW * (0.18 + col * 0.36);
        final py = baseY - dH * (0.18 + row * 0.20);
        canvas.drawRect(
          Rect.fromCenter(center: Offset(px, py), width: dW*0.28, height: dH*0.14),
          _stroke(_accentGold.withOpacity(0.25), sw * 0.006),
        );
      }
    }

    // Steps
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTRB(
          left - i * dW * 0.04, baseY + i * dW * 0.055,
          left + dW + i * dW * 0.04, baseY + (i + 1) * dW * 0.055,
        ),
        _fill(Color.lerp(_stone, _accentGold, 0.05)!),
      );
    }
  }

  void _drawArch(Canvas canvas, double cx, double topY, double aW, double aH,
      double gY, double sw, {required bool isSmall}) {
    final left = cx - aW / 2;
    final archPath = Path()
      ..moveTo(left, topY + aW / 2)
      ..arcTo(Rect.fromLTRB(left, topY, left + aW, topY + aW),
          math.pi, math.pi, false)
      ..lineTo(left + aW, topY + aH)
      ..lineTo(left, topY + aH)
      ..close();
    canvas.drawPath(archPath, _fill(_stoneDark.withOpacity(isSmall ? 0.7 : 0.9)));
    canvas.drawPath(archPath,
        _stroke(_accentGold.withOpacity(isSmall ? 0.35 : 0.50), sw * (isSmall ? 0.007 : 0.010)));
    // Inner grill lines
    if (!isSmall) {
      for (int i = 1; i <= 3; i++) {
        canvas.drawLine(
          Offset(left + aW * i / 4, topY + aW * 0.5),
          Offset(left + aW * i / 4, topY + aH),
          _stroke(_accentGold.withOpacity(0.15), sw * 0.005),
        );
      }
    }
  }

  // ── Domes ─────────────────────────────────────────────────────────────────
  void _drawDomes(Canvas canvas, double w, double h, double gY) {
    // Already drawn wing domes inside _drawWings; main dome here
    final mainC = Offset(w * 0.5, gY - h * 0.30 - h * 0.006);
    final mainR = w * 0.155;
    _drawOnionDome(canvas, mainC, mainR, w, isMain: true);
    _drawSmallCrescent(canvas, Offset(w * 0.5, mainC.dy - mainR * 1.10), mainR * 0.40);
  }

  void _drawOnionDome(Canvas canvas, Offset base, double r, double sw,
      {required bool isMain}) {
    // Drum (cylindrical base)
    final drumH = r * 0.28;
    final drumW = r * (isMain ? 1.60 : 1.50);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(base.dx, base.dy + drumH/2),
          width: drumW, height: drumH),
      _fill(_stone),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(base.dx, base.dy + drumH/2),
          width: drumW, height: drumH),
      _stroke(_accentGold.withOpacity(isMain ? 0.45 : 0.30), sw * 0.007),
    );

    // Dome ribs (realistic panel lines)
    final panelCount = isMain ? 12 : 8;
    for (int i = 0; i < panelCount; i++) {
      final angle = (i / panelCount) * math.pi;
      final ribX = base.dx + r * math.cos(angle) * (isMain ? 0.88 : 0.84);
      final ribTopY = base.dy - r * (isMain ? 0.88 : 0.82);
      canvas.drawLine(
        Offset(base.dx, ribTopY),
        Offset(ribX, base.dy),
        _stroke(_stoneDark.withOpacity(0.35), sw * (isMain ? 0.005 : 0.004)),
      );
    }

    // Onion dome shape (characteristic bulge)
    final domePath = Path();
    domePath.moveTo(base.dx - drumW / 2, base.dy);
    domePath.cubicTo(
      base.dx - r * 1.02, base.dy - r * 0.30,
      base.dx - r * 0.92, base.dy - r * 0.88,
      base.dx, base.dy - r * (isMain ? 1.05 : 1.00),
    );
    domePath.cubicTo(
      base.dx + r * 0.92, base.dy - r * 0.88,
      base.dx + r * 1.02, base.dy - r * 0.30,
      base.dx + drumW / 2, base.dy,
    );
    domePath.close();

    // Shadow half
    final shadowPath = Path();
    shadowPath.moveTo(base.dx, base.dy);
    shadowPath.cubicTo(
      base.dx + r * 0.1, base.dy - r * 0.30,
      base.dx + r * 0.92, base.dy - r * 0.88,
      base.dx, base.dy - r * (isMain ? 1.05 : 1.00),
    );
    shadowPath.cubicTo(
      base.dx + r * 0.92, base.dy - r * 0.88,
      base.dx + r * 1.02, base.dy - r * 0.30,
      base.dx + drumW / 2, base.dy,
    );
    shadowPath.close();

    canvas.drawPath(domePath, _fill(_stone));
    canvas.drawPath(shadowPath, _fill(_stoneDark.withOpacity(0.30)));
    canvas.drawPath(domePath, _fill(_accentGold.withOpacity(0.07 + t * 0.04)));
    canvas.drawPath(domePath,
        _stroke(_accentGold.withOpacity(isMain ? 0.50 : 0.35),
            sw * (isMain ? 0.012 : 0.008)));

    // Highlight line (light reflection on dome surface)
    final hlPath = Path()
      ..moveTo(base.dx - r * 0.45, base.dy - r * 0.40)
      ..cubicTo(
        base.dx - r * 0.38, base.dy - r * 0.70,
        base.dx - r * 0.15, base.dy - r * 0.90,
        base.dx, base.dy - r * (isMain ? 1.05 : 1.00),
      );
    canvas.drawPath(hlPath,
        _stroke(_stoneLight.withOpacity(0.55), sw * (isMain ? 0.007 : 0.005)));

    // Finial sphere
    canvas.drawCircle(
      Offset(base.dx, base.dy - r * (isMain ? 1.06 : 1.01)),
      r * (isMain ? 0.06 : 0.05),
      _fill(_accentGold),
    );
  }

  // ── Facade details (after domes so they render on top) ────────────────────
  void _drawFacadeDetails(Canvas canvas, double w, double h, double gY) {
    // Calligraphy band above door (abstract gold line work)
    final bandY = gY - h * 0.30 + h * 0.028;
    final bandL = w * 0.5 - w * 0.13;
    final bandR = w * 0.5 + w * 0.13;
    canvas.drawRect(
      Rect.fromLTRB(bandL, bandY, bandR, bandY + h * 0.018),
      _fill(_accentGold.withOpacity(0.10)),
    );
    canvas.drawRect(
      Rect.fromLTRB(bandL, bandY, bandR, bandY + h * 0.018),
      _stroke(_accentGold.withOpacity(0.40), w * 0.006),
    );
    // Arabic arch motif (simplified) inside band
    for (int i = 0; i < 7; i++) {
      final x = bandL + (bandR - bandL) * (i + 0.5) / 7;
      canvas.drawLine(
        Offset(x, bandY + h * 0.002),
        Offset(x, bandY + h * 0.016),
        _stroke(_accentGold.withOpacity(0.28), w * 0.005),
      );
    }
  }

  // ── Ground platform ────────────────────────────────────────────────────────
  void _drawPlatform(Canvas canvas, double w, double h, double gY) {
    // Main platform
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.04, gY, w * 0.96, gY + h * 0.022),
        const Radius.circular(2),
      ),
      _fill(_stone),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.04, gY, w * 0.96, gY + h * 0.022),
        const Radius.circular(2),
      ),
      _stroke(_accentGold.withOpacity(0.35), w * 0.007),
    );
    // Paving pattern
    for (int i = 1; i < 8; i++) {
      canvas.drawLine(
        Offset(w * 0.04 + (w * 0.92) * i / 8, gY),
        Offset(w * 0.04 + (w * 0.92) * i / 8, gY + h * 0.022),
        _stroke(_stoneDark.withOpacity(0.4), w * 0.004),
      );
    }
    // Steps
    for (int i = 1; i <= 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            w * (0.04 + i * 0.025), gY + h * 0.022 * i,
            w * (0.96 - i * 0.025), gY + h * 0.022 * (i + 1),
          ),
          const Radius.circular(2),
        ),
        _fill(Color.lerp(_stone, _accentGold, 0.04)!),
      );
    }
  }

  // ── Water reflection ───────────────────────────────────────────────────────
  void _drawWaterReflection(Canvas canvas, double w, double h, double gY) {
    final waterY = gY + h * 0.092;
    if (waterY >= h) return;
    final rect = Rect.fromLTRB(0, waterY, w, h);
    canvas.drawRect(rect,
        _fill(_skyGround)
          ..shader = LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [_accentGold.withOpacity(0.04), _skyTop.withOpacity(0.02)],
          ).createShader(rect));

    // Ripples
    for (int i = 0; i < 5; i++) {
      final y  = waterY + (h - waterY) * (0.15 + i * 0.18);
      final xo = (t - 0.5) * w * 0.035 * (i.isEven ? 1 : -1);
      canvas.drawLine(
        Offset(w * 0.12 + xo, y), Offset(w * 0.88 + xo, y),
        _stroke(_accentGold.withOpacity(0.055 - i * 0.008), w * 0.007),
      );
    }

    // Blurred dome reflection
    canvas.save();
    canvas.translate(w / 2, waterY);
    canvas.scale(1, -0.55);
    canvas.translate(-w / 2, -(gY - waterY));
    final mainC = Offset(w * 0.5, gY - h * 0.30 - h * 0.006);
    final mainR = w * 0.155;
    final refPath = Path()
      ..moveTo(mainC.dx - mainR * 1.0, mainC.dy)
      ..cubicTo(
        mainC.dx - mainR * 1.02, mainC.dy - mainR * 0.30,
        mainC.dx - mainR * 0.92, mainC.dy - mainR * 0.88,
        mainC.dx, mainC.dy - mainR * 1.05,
      )
      ..cubicTo(
        mainC.dx + mainR * 0.92, mainC.dy - mainR * 0.88,
        mainC.dx + mainR * 1.02, mainC.dy - mainR * 0.30,
        mainC.dx + mainR * 1.0,  mainC.dy,
      )
      ..close();
    canvas.drawPath(refPath,
        _fill(_accentGold.withOpacity(0.06))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.restore();
  }

  // ── Lighting (windows glow) ────────────────────────────────────────────────
  void _drawLighting(Canvas canvas, double w, double h, double gY) {
    // Warm golden light from windows (pulsing gently)
    final bW = w * 0.30;
    final bH = h * 0.30;
    final left = w * 0.5 - bW / 2;
    final gY2  = gY - bH;

    for (final xf in [0.27, 0.73]) {
      final wx = left + bW * xf;
      final wH = bH * 0.38;
      final wY = gY - wH - bH * 0.12;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(wx, wY + wH * 0.5), width: bW*0.18, height: wH*0.7),
        _fill(_accentGold.withOpacity(0.07 + t * 0.06))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.025),
      );
    }
    // Door glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w*0.5, gY - bH * 0.35),
          width: bW*0.38, height: bH*0.55),
      _fill(_accentGold.withOpacity(0.05 + t * 0.04))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04),
    );
  }

  // ── Small crescent helper ─────────────────────────────────────────────────
  void _drawSmallCrescent(Canvas canvas, Offset center, double r) {
    if (r <= 0) return;
    final outer = Path()..addOval(Rect.fromCircle(center: center, radius: r));
    final cut   = Path()..addOval(Rect.fromCircle(
        center: center.translate(r*0.48, -r*0.06), radius: r*0.76));
    final cres  = Path.combine(PathOperation.difference, outer, cut);
    canvas.drawPath(cres,
        _fill(_accentGold.withOpacity(0.4))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.2));
    canvas.drawPath(cres, _fill(_accentGold));
    // Star dot next to crescent
    canvas.drawCircle(
      center.translate(r * 0.90, -r * 0.65), r * 0.18,
      _fill(_accentGold.withOpacity(0.85)),
    );
  }

  @override
  bool shouldRepaint(_MosquePainter old) =>
      old.accent != accent || old.t != t;
}


