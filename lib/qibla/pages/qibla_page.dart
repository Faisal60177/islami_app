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

  // Raw heading from sensor — updated on every compass event
  double _compassHeading = 0.0;
  bool _headingReceived = false;

  // Computed once from GPS location — null until LocationLoaded fires
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

    // Unlock orientation so the magnetometer keeps firing.
    // Portrait lock in main.dart suppresses sensor events.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

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
    // Restore portrait lock for the rest of the app
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

      // Cancel any stale subscription first
      await _compassSub?.cancel();

      _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
        if (!mounted) return;
        final h = event.heading;
        if (h == null) return;

        // setState on every event — this triggers shouldRepaint → canvas redraws
        setState(() {
          _compassHeading = h;
          _headingReceived = true;
        });
      });
    }
  }

  // ── Location + Qibla computation ─────────────────────────────────────────
  //
  // Called from BlocBuilder whenever LocationLoaded arrives.
  // Keeps _qiblaAngle updated independently of the compass stream.
  //
  void _updateQiblaFromLocation(double lat, double lng) {
    final angle = _bearing(lat, lng, _kaabaLat, _kaabaLng);
    final dist  = _haversine(lat, lng, _kaabaLat, _kaabaLng);
    // Only call setState if values actually changed
    if (angle != _qiblaAngle || dist != _distanceKm) {
      setState(() {
        _qiblaAngle  = angle;
        _distanceKm  = dist;
      });
    }
  }

  // ── Qibla math ────────────────────────────────────────────────────────────

  /// Great-circle bearing from user to Kaaba, degrees [0–360)
  double _bearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = _toRad(lng2 - lng1);
    final l1   = _toRad(lat1);
    final l2   = _toRad(lat2);
    final x    = math.sin(dLng) * math.cos(l2);
    final y    = math.cos(l1) * math.sin(l2) -
        math.sin(l1) * math.cos(l2) * math.cos(dLng);
    return (_toDeg(math.atan2(x, y)) + 360) % 360;
  }

  /// Haversine distance in km
  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R    = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a    = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return R * 2 * math.asin(math.sqrt(a.toDouble()));
  }

  double _toRad(double d) => d * math.pi / 180;
  double _toDeg(double r) => r * 180 / math.pi;

  /// Wrap angular difference into [-180, 180]
  double _angDiff(double a, double b) {
    double d = (a - b) % 360;
    if (d >  180) d -= 360;
    if (d < -180) d += 360;
    return d;
  }

  String _cardinal(double deg) {
    const dirs = ['N','NNE','NE','ENE','E','ESE','SE','SSE',
      'S','SSW','SW','WSW','W','WNW','NW','NNW'];
    return dirs[((deg + 11.25) / 22.5).floor() % 16];
  }

  String _formatDistance(double km) {
    final s   = km.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()} km';
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

          // ── Compute Qibla angle from GPS every time location updates ─────
          // This is the ONLY place _qiblaAngle is set.
          // We call _updateQiblaFromLocation which calls setState internally,
          // so BlocBuilder rebuilding here doesn't cause a stale value.
          if (locState is LocationLoaded) {
            _updateQiblaFromLocation(
              locState.location.latitude,
              locState.location.longitude,
            );
          }

          // ── Guard screens ────────────────────────────────────────────────
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

          // Wait for both: GPS location AND first compass reading
          if (!_headingReceived) return _buildCalibrating(sw);

          // If location still loading even after permission granted
          if (_qiblaAngle == null) return _buildWaitingLocation(sw);

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

  // ── Compass widget ────────────────────────────────────────────────────────
  //
  // _compassHeading  = where the phone is pointing (from sensor, 0–360)
  // _qiblaAngle      = absolute bearing to Mecca from user's GPS (0–360)
  //
  // The arrow screen angle = _qiblaAngle - _compassHeading
  //   • When the phone points exactly at Mecca → diff = 0 → arrow points UP
  //   • When the phone points away             → diff ≠ 0 → arrow rotates
  //
  Widget _buildCompass(double sw) {
    final size    = sw * 0.78;
    final heading = _compassHeading;           // live, always non-null here
    final qibla   = _qiblaAngle!;              // non-null — guarded above
    final diff    = _angDiff(qibla, heading);
    final aligned = diff.abs() < 5.0;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            final ringSize = aligned ? size * _pulse.value : size;
            return SizedBox(
              width:  ringSize,
              height: ringSize,
              child: CustomPaint(
                // KEY: pass fresh heading + qiblaAngle on every build
                // shouldRepaint will detect the change and redraw
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
          style: TextStyle(
              color: const Color(0xFF9FE1CB), fontSize: sw * 0.033),
        ),
      ],
    );
  }

  Widget _buildQiblaBadge(double sw) {
    final deg = '${_qiblaAngle!.toStringAsFixed(1)}° from North';
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.05, vertical: sw * 0.035),
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
                      color: const Color(0xFFd0ffd0),
                      fontSize: sw * 0.032)),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                '${_compassHeading.toStringAsFixed(0)}°',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.042,
                    fontWeight: FontWeight.w700),
              ),
              Text('heading',
                  style: TextStyle(
                      color: const Color(0xFFd0ffd0),
                      fontSize: sw * 0.028)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(LocationState state, double sw) {
    String latStr = '—', lngStr = '—';
    if (state is LocationLoaded) {
      latStr = '${state.location.latitude.toStringAsFixed(4)}° N';
      lngStr = '${state.location.longitude.toStringAsFixed(4)}° E';
    }
    final bearing  = '${_qiblaAngle!.toStringAsFixed(1)}°';
    final cardinal = _cardinal(_qiblaAngle!);

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
                      color: const Color(0xFFd0ffd0),
                      fontSize: sw * 0.028)),
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

  // Shown while waiting for first compass reading
  Widget _buildCalibrating(double sw) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(sw * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF74C365)),
            SizedBox(height: sw * 0.06),
            Text('Initialising compass...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.045,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: sw * 0.03),
            Text(
              'Move your phone in a figure-8 pattern if this takes too long.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[400], fontSize: sw * 0.038),
            ),
          ],
        ),
      ),
    );
  }

  // Shown while compass works but GPS not yet resolved
  Widget _buildWaitingLocation(double sw) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(sw * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4CAF50)),
            SizedBox(height: sw * 0.06),
            Text('Getting your location...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.045,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: sw * 0.03),
            Text(
              'Make sure GPS is enabled and you have a clear sky view.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[400], fontSize: sw * 0.038),
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
            Icon(Icons.sensors_off,
                color: Colors.grey[600], size: sw * 0.18),
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
              style: TextStyle(
                  color: Colors.grey[400], fontSize: sw * 0.038),
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
            Icon(Icons.location_off,
                color: Colors.grey[600], size: sw * 0.18),
            SizedBox(height: sw * 0.05),
            Text('Location not available',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.045,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: sw * 0.03),
            Text(
              'Enable location from the Today screen and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[400], fontSize: sw * 0.038),
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
// Paints the full compass on one canvas using save/translate/rotate.
//
// How the arrow works:
//   heading    = phone's current bearing from North (sensor, 0–360°)
//   qiblaAngle = absolute bearing from user to Mecca (GPS math, 0–360°)
//
//   qiblaScreen = qiblaAngle - heading
//     → 0   when phone faces Mecca   (arrow points UP = toward Mecca)
//     → +90 when phone faces 90° away from Mecca (arrow points RIGHT)
//
// shouldRepaint fires on every setState from the compass listener,
// which happens multiple times per second — keeping the canvas live.
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
  bool shouldRepaint(_CompassPainter old) {
    // Use a small epsilon so floating-point noise doesn't suppress repaints,
    // but also doesn't spam the GPU with sub-pixel redraws
    return (old.heading - heading).abs() > 0.1 ||
        (old.qiblaAngle - qiblaAngle).abs() > 0.01 ||
        old.aligned != aligned;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width / 2;
    final cy     = size.height / 2;
    final radius = math.min(cx, cy) - 4;

    // ── 1. Background ─────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy), radius,
      Paint()..color = const Color(0xFF012818),
    );

    // Border — amber when aligned, green otherwise
    canvas.drawCircle(
      Offset(cx, cy), radius,
      Paint()
        ..color       = aligned ? Colors.amber : const Color(0xFF74C365)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = aligned ? 3.5 : 2.5,
    );

    // ── 2. Rotating dial: tick marks + N/S/E/W labels ─────────────────────
    //
    // canvas.rotate(-heading) makes North always point UP on screen.
    // Everything in this save/restore block moves with the phone rotation.
    //
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-heading * math.pi / 180);

    final tickOuter = radius - 2.0;
    for (int i = 0; i < 72; i++) {
      final isMajor   = i % 9 == 0;          // every 45° is major
      final tickInner = isMajor
          ? tickOuter - radius * 0.07
          : tickOuter - radius * 0.035;

      canvas.save();
      canvas.rotate(i * 5.0 * math.pi / 180);
      canvas.drawLine(
        Offset(0, -tickOuter),
        Offset(0, -tickInner),
        Paint()
          ..color       = isMajor
              ? const Color(0xFF74C365)
              : const Color(0xFF1a5c35)
          ..strokeWidth = isMajor ? 1.5 : 0.8
          ..strokeCap   = StrokeCap.round,
      );
      canvas.restore();
    }

    // Cardinal labels — drawn in the rotating frame but text is
    // counter-rotated so letters stay upright for the user
    _cardinal(canvas, 'N', 0,            radius, const Color(0xFFE24B4A), bold: true);
    _cardinal(canvas, 'S', math.pi,       radius, const Color(0xFF9FE1CB));
    _cardinal(canvas, 'E', math.pi / 2,   radius, const Color(0xFF9FE1CB));
    _cardinal(canvas, 'W', -math.pi / 2,  radius, const Color(0xFF9FE1CB));

    canvas.restore(); // ← end rotating dial

    // ── 3. Compass needle (red N / grey S) ───────────────────────────────
    // Shares the same -heading rotation as the dial
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-heading * math.pi / 180);

    final nLen = radius * 0.58;
    const nW   = 7.0;

    canvas.drawPath(                          // red North
      Path()..moveTo(0, -nLen)..lineTo(-nW, 0)..lineTo(nW, 0)..close(),
      Paint()..color = const Color(0xFFE24B4A),
    );
    canvas.drawPath(                          // grey South
      Path()..moveTo(0, nLen)..lineTo(-nW, 0)..lineTo(nW, 0)..close(),
      Paint()..color = const Color(0xFF666666),
    );

    canvas.restore(); // ← end needle

    // ── 4. Qibla arrow ────────────────────────────────────────────────────
    //
    // Completely independent rotation block.
    // qiblaScreen = qiblaAngle - heading (screen-space angle to Mecca)
    //   • Phone pointing at Mecca → qiblaScreen = 0 → arrow points straight UP
    //   • Phone pointing elsewhere → arrow rotates to compensate
    //
    final qiblaScreen = (qiblaAngle - heading) * math.pi / 180;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(qiblaScreen);               // ← only this one rotation

    final aLen   = radius * 0.60;
    final aColor = aligned ? Colors.amber : const Color(0xFFFFD700);
    final aPaint = Paint()..color = aColor;

    // Arrow body (points upward = toward Mecca in screen space)
    canvas.drawPath(
      Path()
        ..moveTo(0, -aLen)                    // tip
        ..lineTo(-7, aLen * 0.15)             // bottom-left wing
        ..lineTo(0, -aLen * 0.05)             // waist indent
        ..lineTo(7,  aLen * 0.15)             // bottom-right wing
        ..close(),
      aPaint,
    );

    // Glowing tip highlight
    canvas.drawCircle(
      Offset(0, -aLen + 5),
      5,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Tiny Kaaba square at the very tip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -aLen + 8), width: 10, height: 10),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF013220),
    );

    canvas.restore(); // ← end Qibla arrow

    // ── 5. Center hub ─────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy), radius * 0.04,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx, cy), radius * 0.04,
      Paint()
        ..color       = const Color(0xFF74C365)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // Draws a cardinal label positioned in the rotating frame.
  // The text itself is counter-rotated by +heading so it stays upright.
  void _cardinal(
      Canvas canvas,
      String label,
      double angleRad,
      double radius,
      Color color, {
        bool bold = false,
      }) {
    final r = radius * 0.74;
    final x = math.sin(angleRad) * r;
    final y = -math.cos(angleRad) * r;

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color:      color,
          fontSize:   13,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(heading * math.pi / 180); // counter-rotate text
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _KaabaPainter  (badge icon only)
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