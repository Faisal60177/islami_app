import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../location/cubit/location_cubit.dart';
import '../../../location/cubit/location_state.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  double? _compassHeading;
  double? _qiblaAngle;
  double? _distanceKm;
  bool _permissionGranted = false;
  bool _calibrating = false;

  StreamSubscription<CompassEvent>? _compassSub;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // ── CRITICAL FIX ──────────────────────────────────────────────────────
    // main.dart locks orientation to portrait-only with:
    //   SystemChrome.setPreferredOrientations([portraitUp, portraitDown])
    //
    // That system call suppresses motion-sensor events on both Android and
    // iOS, causing FlutterCompass to emit only one event (or none) and then
    // go completely silent — even though the phone is physically rotating.
    //
    // Fix: unlock all orientations while this page is open.
    // dispose() re-locks portrait before the user returns to other pages.
    //SystemChrome.setPreferredOrientations([
      //DeviceOrientation.portraitUp,
      //DeviceOrientation.portraitDown,
     // DeviceOrientation.landscapeLeft,
     // DeviceOrientation.landscapeRight,
    //]);

    WidgetsBinding.instance.addObserver(this);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _requestPermissionAndStart();
  }

  @override
  void dispose() {
    // Re-lock portrait before leaving so the rest of the app is unaffected
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    WidgetsBinding.instance.removeObserver(this);
    _compassSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_permissionGranted) {
      _requestPermissionAndStart();
    }
  }

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.locationWhenInUse.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() => _permissionGranted = true);

      await _compassSub?.cancel();

      _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
        if (!mounted) return;
        final h = event.heading;
        if (h == null) return;
        setState(() => _compassHeading = h);
      });
    }
  }

  // ── Qibla math ────────────────────────────────────────────────────────────

  double _bearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = _toRad(lng2 - lng1);
    final l1 = _toRad(lat1);
    final l2 = _toRad(lat2);
    final x = math.sin(dLng) * math.cos(l2);
    final y = math.cos(l1) * math.sin(l2) -
        math.sin(l1) * math.cos(l2) * math.cos(dLng);
    return (_toDeg(math.atan2(x, y)) + 360) % 360;
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return r * 2 * math.asin(math.sqrt(a as double));
  }

  double _toRad(double d) => d * math.pi / 180;
  double _toDeg(double r) => r * 180 / math.pi;

  String _cardinal(double deg) {
    const dirs = [
      'N','NNE','NE','ENE','E','ESE','SE','SSE',
      'S','SSW','SW','WSW','W','WNW','NW','NNW'
    ];
    return dirs[((deg + 11.25) / 22.5).floor() % 16];
  }

  String _formatDistance(double km) {
    final s = km.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()} km';
  }

  double _angDiff(double a, double b) {
    double d = (a - b) % 360;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d;
  }

  void _calibrate() {
    setState(() => _calibrating = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Move your phone in a figure-8 pattern to calibrate the compass.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF74C365),
        duration: Duration(seconds: 4),
      ),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _calibrating = false);
    });
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF013220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF013220),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Qibla Direction',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, locState) {

          if (locState is LocationLoaded) {
            final lat = locState.location.latitude;
            final lng = locState.location.longitude;
            _qiblaAngle = _bearing(lat, lng, _kaabaLat, _kaabaLng);
            _distanceKm = _haversine(lat, lng, _kaabaLat, _kaabaLng);
          }

          if (!_permissionGranted) return _buildPermissionDenied(sw);

          if (locState is LocationLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            );
          }

          if (locState is LocationPermissionDenied ||
              locState is LocationInitial) {
            return _buildNoLocation(sw);
          }

          if (_compassHeading == null) return _buildCalibrating(sw);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.05, vertical: sw * 0.04),
            child: Column(
              children: [
                _buildLocationRow(locState, sw),
                SizedBox(height: sh * 0.015),
                _buildDistanceBadge(sw),
                SizedBox(height: sh * 0.025),
                _buildCompass(sw),
                SizedBox(height: sh * 0.03),
                _buildQiblaBadge(sw),
                SizedBox(height: sh * 0.018),
                _buildInfoGrid(locState, sw),
                SizedBox(height: sh * 0.02),
                _buildCalibrateBtn(sw),
                SizedBox(height: sh * 0.02),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildLocationRow(LocationState state, double sw) {
    String city = '';
    if (state is LocationLoaded) {
      city = '${state.location.city}, ${state.location.country}';
    }
    return Row(
      children: [
        const Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            city.isEmpty ? 'Detecting location...' : city,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: sw * 0.038,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceBadge(double sw) {
    final dist = _distanceKm != null ? _formatDistance(_distanceKm!) : '— km';
    return Column(
      children: [
        Text(
          dist,
          style: TextStyle(
            color: Colors.white,
            fontSize: sw * 0.07,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'distance to Makkah al-Mukarramah',
          style: TextStyle(color: const Color(0xFF9FE1CB), fontSize: sw * 0.033),
        ),
      ],
    );
  }

  Widget _buildCompass(double sw) {
    final size = sw * 0.78;
    final heading = _compassHeading!;
    final qibla   = _qiblaAngle ?? 0.0;
    final diff    = _angDiff(qibla, heading);
    final aligned = diff.abs() < 5.0;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            final ringSize = aligned ? size * _pulse.value : size;
            return SizedBox(
              width: ringSize,
              height: ringSize,
              child: CustomPaint(
                painter: _CompassPainter(
                  heading:    heading,
                  qiblaAngle: qibla,
                  aligned:    aligned,
                ),
              ),
            );
          },
        ),
        if (aligned) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Facing Qibla ✦',
              style: TextStyle(
                color: const Color(0xFF013220),
                fontSize: sw * 0.034,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQiblaBadge(double sw) {
    final deg = _qiblaAngle != null
        ? '${_qiblaAngle!.toStringAsFixed(1)}° from North'
        : '—';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.05, vertical: sw * 0.035),
      decoration: BoxDecoration(
        color: const Color(0xFF74C365),
        borderRadius: BorderRadius.circular(sw * 0.035),
      ),
      child: Row(
        children: [
          Container(
            width: sw * 0.09,
            height: sw * 0.09,
            decoration: BoxDecoration(
              color: const Color(0xFF013220),
              borderRadius: BorderRadius.circular(6),
            ),
            child: CustomPaint(painter: _KaabaPainter()),
          ),
          SizedBox(width: sw * 0.04),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Qibla Direction',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: sw * 0.042,
                      fontWeight: FontWeight.w700)),
              Text(deg,
                  style: TextStyle(
                      color: const Color(0xFFd0ffd0), fontSize: sw * 0.032)),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                '${_compassHeading!.toStringAsFixed(0)}°',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.042,
                    fontWeight: FontWeight.w700),
              ),
              Text('heading',
                  style: TextStyle(
                      color: const Color(0xFFd0ffd0), fontSize: sw * 0.028)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(LocationState state, double sw) {
    String latStr = '—', lngStr = '—';
    if (state is LocationLoaded) {
      latStr = '${state.location.latitude.toStringAsFixed(2)}° N';
      lngStr = '${state.location.longitude.toStringAsFixed(2)}° E';
    }
    final bearing = _qiblaAngle != null
        ? '${_qiblaAngle!.toStringAsFixed(1)}°' : '—';
    final cardinal = _qiblaAngle != null ? _cardinal(_qiblaAngle!) : '—';

    final items = [
      ('Your latitude',  latStr),
      ('Your longitude', lngStr),
      ('Qibla bearing',  bearing),
      ('Direction',      cardinal),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: sw * 0.025,
      crossAxisSpacing: sw * 0.025,
      childAspectRatio: 2.4,
      children: items.map((item) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF74C365),
            borderRadius: BorderRadius.circular(sw * 0.03),
          ),
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.04, vertical: sw * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.$1,
                  style: TextStyle(
                      color: const Color(0xFFd0ffd0), fontSize: sw * 0.028)),
              Text(item.$2,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: sw * 0.038,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalibrateBtn(double sw) {
    return GestureDetector(
      onTap: _calibrate,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: sw * 0.038),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF74C365), width: 1.5),
          borderRadius: BorderRadius.circular(sw * 0.03),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.screen_rotation,
                color: const Color(0xFF74C365), size: sw * 0.05),
            SizedBox(width: sw * 0.02),
            Text(
              _calibrating ? 'Calibrating...' : 'Calibrate compass',
              style: TextStyle(
                  color: const Color(0xFF74C365),
                  fontSize: sw * 0.038,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrating(double sw) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(sw * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF74C365)),
            SizedBox(height: sw * 0.06),
            Text('Waiting for compass...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.045,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: sw * 0.03),
            Text(
              'Move your phone in a figure-8 pattern to help calibrate.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: sw * 0.038),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied(double sw) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(sw * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, color: Colors.grey[600], size: sw * 0.18),
            SizedBox(height: sw * 0.05),
            Text('Location permission required',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.045,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: sw * 0.03),
            Text(
              'Please grant location access to calculate the Qibla direction.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: sw * 0.038),
            ),
            SizedBox(height: sw * 0.06),
            GestureDetector(
              onTap: openAppSettings,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.08, vertical: sw * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFF74C365),
                  borderRadius: BorderRadius.circular(sw * 0.03),
                ),
                child: Text('Open settings',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: sw * 0.04,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLocation(double sw) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(sw * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, color: Colors.grey[600], size: sw * 0.18),
            SizedBox(height: sw * 0.05),
            Text('Location not found',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.045,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: sw * 0.03),
            Text(
              'Enable location from the Today screen and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: sw * 0.038),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _CompassPainter
//
// Draws the entire compass in one CustomPainter.
// canvas.translate(cx,cy) + canvas.rotate() always rotates around the
// true geometric center — no widget Transform.rotate alignment issues.
// shouldRepaint returns true on every heading change → compass stays live.
// ══════════════════════════════════════════════════════════════════════════════
class _CompassPainter extends CustomPainter {
  final double heading;
  final double qiblaAngle;
  final bool aligned;

  const _CompassPainter({
    required this.heading,
    required this.qiblaAngle,
    required this.aligned,
  });

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.heading != heading ||
          old.qiblaAngle != qiblaAngle ||
          old.aligned != aligned;

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width / 2;
    final cy     = size.height / 2;
    final radius = math.min(cx, cy) - 4;

    // ── 1. Background + border ────────────────────────────────────────────
    canvas.drawCircle(Offset(cx, cy), radius,
        Paint()..color = const Color(0xFF012818));

    canvas.drawCircle(
      Offset(cx, cy), radius,
      Paint()
        ..color = aligned ? Colors.amber : const Color(0xFF74C365)
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 3.0 : 2.5,
    );

    // ── 2. Rotating dial (ticks + cardinal labels) ────────────────────────
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-heading * math.pi / 180);

    // 72 tick marks, one every 5°
    for (int i = 0; i < 72; i++) {
      final angle     = i * 5.0 * math.pi / 180;
      final isMajor   = i % 9 == 0;
      final tickOuter = radius - 2;
      final tickInner = isMajor
          ? tickOuter - radius * 0.07
          : tickOuter - radius * 0.035;

      canvas.save();
      canvas.rotate(angle);
      canvas.drawLine(
        Offset(0, -tickOuter),
        Offset(0, -tickInner),
        Paint()
          ..color = isMajor
              ? const Color(0xFF74C365)
              : const Color(0xFF1a5c35)
          ..strokeWidth = isMajor ? 1.5 : 0.8
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    // Cardinal labels — positioned inside the rotating context but the text
    // itself is counter-rotated so it always reads upright on screen
    _drawCardinalLabel(canvas, 'N', 0,           radius, const Color(0xFFE24B4A), bold: true);
    _drawCardinalLabel(canvas, 'S', math.pi,      radius, const Color(0xFF9FE1CB));
    _drawCardinalLabel(canvas, 'E', math.pi / 2,  radius, const Color(0xFF9FE1CB));
    _drawCardinalLabel(canvas, 'W', -math.pi / 2, radius, const Color(0xFF9FE1CB));

    canvas.restore(); // end dial

    // ── 3. Compass needle (rotates with dial = -heading) ──────────────────
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-heading * math.pi / 180);

    final needleLen = radius * 0.60;
    const needleW   = 7.0;

    // Red North
    canvas.drawPath(
      Path()
        ..moveTo(0, -needleLen)
        ..lineTo(-needleW, 0)
        ..lineTo(needleW, 0)
        ..close(),
      Paint()..color = const Color(0xFFE24B4A),
    );
    // Grey South
    canvas.drawPath(
      Path()
        ..moveTo(0, needleLen)
        ..lineTo(-needleW, 0)
        ..lineTo(needleW, 0)
        ..close(),
      Paint()..color = const Color(0xFF666666),
    );

    canvas.restore(); // end needle

    // ── 4. Qibla arrow — independent rotation ─────────────────────────────
    // Screen angle = absolute qibla bearing − current device heading.
    // This is calculated from scratch; it does NOT share the needle's
    // save/restore block, so there is zero risk of double-rotation.
    final qiblaScreen = (qiblaAngle - heading) * math.pi / 180;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(qiblaScreen);

    final arrowLen   = radius * 0.58;
    final arrowColor = aligned ? Colors.amber : const Color(0xFFFFD700);

    canvas.drawPath(
      Path()
        ..moveTo(0, -arrowLen)
        ..lineTo(-6, arrowLen * 0.12)
        ..lineTo(0, -arrowLen * 0.06)
        ..lineTo(6, arrowLen * 0.12)
        ..close(),
      Paint()..color = arrowColor,
    );

    // Tiny Kaaba square at tip
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -arrowLen + 9), width: 11, height: 11),
      Paint()..color = const Color(0xFF013220),
    );

    canvas.restore(); // end Qibla arrow

    // ── 5. Center dot ─────────────────────────────────────────────────────
    canvas.drawCircle(Offset(cx, cy), radius * 0.035,
        Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(cx, cy), radius * 0.035,
      Paint()
        ..color = const Color(0xFF74C365)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  /// Draws a cardinal label at [angle] radians from top inside the
  /// rotating dial context, then counter-rotates the text so it stays upright.
  void _drawCardinalLabel(
      Canvas canvas,
      String text,
      double angle,
      double radius,
      Color color, {
        bool bold = false,
      }) {
    final r = radius * 0.74;
    final x = math.sin(angle) * r;
    final y = -math.cos(angle) * r;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(heading * math.pi / 180); // undo dial rotation for text
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _KaabaPainter
// ══════════════════════════════════════════════════════════════════════════════
class _KaabaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.25, w * 0.8, h * 0.65),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF74C365),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.38, h * 0.52, w * 0.24, h * 0.38),
      Paint()..color = const Color(0xFF013220),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.08, h * 0.2, w * 0.84, h * 0.1),
      Paint()..color = const Color(0xFF9FE1CB),
    );
  }

  @override
  bool shouldRepaint(_KaabaPainter old) => false;
}