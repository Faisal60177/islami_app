import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
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

// FIX #8: Added WidgetsBindingObserver to re-check permission when app resumes
class _QiblaPageState extends State<QiblaPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  // Kaaba coordinates
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  double? _compassHeading;
  double? _qiblaAngle;
  double? _distanceKm;
  bool _permissionGranted = false;
  bool _calibrating = false;

  // FIX #1: Store the StreamSubscription so it can be cancelled
  StreamSubscription<CompassEvent>? _compassSub;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    // FIX #8: Register lifecycle observer
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
    // FIX #8: Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    // FIX #1: Cancel compass stream to prevent memory leaks
    _compassSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // FIX #8: Re-check permission when user returns from Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_permissionGranted) {
      _requestPermissionAndStart();
    }
  }

  // ── permission + compass stream ───────────────────────────────────────────

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.locationWhenInUse.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _permissionGranted = true);
      // FIX #1: Store subscription reference so we can cancel it in dispose()
      _compassSub = FlutterCompass.events?.listen((event) {
        if (!mounted) return;
        // FIX #5: Only update if heading is non-null (some devices return null)
        if (event.heading != null) {
          setState(() => _compassHeading = event.heading);
        }
      });
    }
  }

  // ── Qibla math ────────────────────────────────────────────────────────────

  /// Great-circle bearing from (lat1,lng1) to (lat2,lng2) in degrees [0–360)
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
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return r * 2 * math.asin(math.sqrt(a));
  }

  double _toRad(double deg) => deg * math.pi / 180;
  double _toDeg(double rad) => rad * 180 / math.pi;

  /// Compass cardinal label for a bearing
  String _cardinal(double deg) {
    const dirs = ['N','NNE','NE','ENE','E','ESE','SE','SSE',
      'S','SSW','SW','WSW','W','WNW','NW','NNW'];
    return dirs[((deg + 11.25) / 22.5).floor() % 16];
  }

  // FIX #7: Clean distance formatter (no fragile regex)
  String _formatDistance(double km) {
    final rounded = km.round();
    final str = rounded.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return '${buf.toString()} km';
  }

  // ── calibration hint ──────────────────────────────────────────────────────

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

  // ── build ─────────────────────────────────────────────────────────────────

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
          // Compute Qibla whenever location is available
          if (locState is LocationLoaded) {
            final lat = locState.location.latitude;
            final lng = locState.location.longitude;
            _qiblaAngle = _bearing(lat, lng, _kaabaLat, _kaabaLng);
            _distanceKm = _haversine(lat, lng, _kaabaLat, _kaabaLng);
          }

          if (!_permissionGranted) {
            return _buildPermissionDenied(sw);
          }

          if (locState is LocationLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            );
          }

          if (locState is LocationPermissionDenied || locState is LocationInitial) {
            return _buildNoLocation(sw);
          }

          // FIX #5: Show calibrating screen while compass heading is not yet available
          if (_compassHeading == null) {
            return _buildCalibrating(sw);
          }

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
                SizedBox(height: sh * 0.025),
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

  // ── location label ────────────────────────────────────────────────────────

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

  // ── distance badge ────────────────────────────────────────────────────────

  Widget _buildDistanceBadge(double sw) {
    // FIX #7: Use clean formatter instead of fragile regex
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
            color: const Color(0xFF9FE1CB),
            fontSize: sw * 0.033,
          ),
        ),
      ],
    );
  }

  // ── compass widget ────────────────────────────────────────────────────────

  Widget _buildCompass(double sw) {
    final size = sw * 0.72;

    // FIX #2: dialRotation rotates the N/S/E/W labels and needle
    // so that North always points up on screen relative to the device
    final dialRotation = -_compassHeading! * math.pi / 180;

    // FIX #3: qiblaRotation is the absolute compass bearing to Mecca
    // minus the current device heading — giving the screen-space angle
    // This is applied independently at the same Stack level as dialRotation
    final qiblaRotation = (_qiblaAngle! - _compassHeading!) * math.pi / 180;

    // FIX #4: Correct angular difference calculation wrapping to [-180, 180]
    // to handle the 359°→0° boundary correctly
    double diff = (_qiblaAngle! - _compassHeading!) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    final aligned = diff.abs() < 5;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring when aligned
        if (aligned)
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: size * _pulse.value,
              height: size * _pulse.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber.withOpacity(0.5),
                  width: 3,
                ),
              ),
            ),
          ),

        // Compass outer ring
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF012818),
            border: Border.all(color: const Color(0xFF74C365), width: 2.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [

              // ── tick marks (static — always fixed on screen) ──────────────
              ...List.generate(72, (i) {
                final angle = i * 5.0 * math.pi / 180;
                final isMajor = i % 9 == 0;
                final tickLen = isMajor ? size * 0.06 : size * 0.03;
                return Transform.rotate(
                  angle: angle,
                  // FIX #2: alignment ensures rotation is around the widget center
                  alignment: Alignment.center,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: size * 0.025),
                      child: Container(
                        width: isMajor ? 1.5 : 0.8,
                        height: tickLen,
                        color: isMajor
                            ? const Color(0xFF74C365)
                            : const Color(0xFF1a5c35),
                      ),
                    ),
                  ),
                );
              }),

              // ── rotating dial (N/S/E/W labels) ───────────────────────────
              // Rotates so that N always faces upward on the screen
              Transform.rotate(
                angle: dialRotation,
                // FIX #2: alignment: Alignment.center prevents off-axis rotation
                alignment: Alignment.center,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _dirLabel('N', Alignment.topCenter,
                          const Color(0xFFE24B4A), sw),
                      _dirLabel('S', Alignment.bottomCenter,
                          const Color(0xFF9FE1CB), sw),
                      _dirLabel('E', Alignment.centerRight,
                          const Color(0xFF9FE1CB), sw),
                      _dirLabel('W', Alignment.centerLeft,
                          const Color(0xFF9FE1CB), sw),
                    ],
                  ),
                ),
              ),

              // ── compass needle (red = North, grey = South) ─────────────
              // Same rotation as the dial labels
              Transform.rotate(
                angle: dialRotation,
                // FIX #2: alignment: Alignment.center is critical here
                alignment: Alignment.center,
                child: CustomPaint(
                  size: Size(size * 0.55, size * 0.55),
                  painter: _NeedlePainter(),
                ),
              ),

              // ── Qibla golden arrow ─────────────────────────────────────
              // FIX #3: Independent rotation — NOT nested inside dialRotation.
              // qiblaRotation already accounts for heading, so it stands alone.
              Transform.rotate(
                angle: qiblaRotation,
                // FIX #2: alignment: Alignment.center is critical here too
                alignment: Alignment.center,
                child: CustomPaint(
                  size: Size(size * 0.55, size * 0.55),
                  painter: _QiblaNeedlePainter(aligned: aligned),
                ),
              ),

              // ── center dot ───────────────────────────────────────────────
              Container(
                width: size * 0.05,
                height: size * 0.05,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // "Facing Qibla" label when aligned
        if (aligned)
          Positioned(
            bottom: -size * 0.05,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Facing Qibla',
                style: TextStyle(
                  color: const Color(0xFF013220),
                  fontSize: sw * 0.032,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dirLabel(
      String text, Alignment alignment, Color color, double sw) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.all(sw * 0.025),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: sw * 0.038,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Qibla direction badge ─────────────────────────────────────────────────

  Widget _buildQiblaBadge(double sw) {
    final deg = _qiblaAngle != null
        ? '${_qiblaAngle!.toStringAsFixed(1)}° from North'
        : '—';
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.05, vertical: sw * 0.035),
      decoration: BoxDecoration(
        color: const Color(0xFF74C365),
        borderRadius: BorderRadius.circular(sw * 0.035),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Kaaba icon
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
              Text(
                'Qibla Direction',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.042,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                deg,
                style: TextStyle(
                    color: const Color(0xFFd0ffd0),
                    fontSize: sw * 0.032),
              ),
            ],
          ),
          const Spacer(),
          // FIX #5: Safe — _compassHeading is non-null here (guarded above)
          Column(
            children: [
              Text(
                '${_compassHeading!.toStringAsFixed(0)}°',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.042,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                'heading',
                style: TextStyle(
                    color: const Color(0xFFd0ffd0),
                    fontSize: sw * 0.028),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── info grid ─────────────────────────────────────────────────────────────

  Widget _buildInfoGrid(LocationState state, double sw) {
    String latStr = '—', lngStr = '—';
    if (state is LocationLoaded) {
      latStr = '${state.location.latitude.toStringAsFixed(2)}° N';
      lngStr = '${state.location.longitude.toStringAsFixed(2)}° E';
    }
    final bearing = _qiblaAngle != null
        ? '${_qiblaAngle!.toStringAsFixed(1)}°'
        : '—';
    final cardinal = _qiblaAngle != null ? _cardinal(_qiblaAngle!) : '—';

    final items = [
      ('Your latitude', latStr),
      ('Your longitude', lngStr),
      ('Qibla bearing', bearing),
      ('Direction', cardinal),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: sw * 0.025,
      crossAxisSpacing: sw * 0.025,
      childAspectRatio: 2.4,
      children: items
          .map((item) => Container(
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
            Text(
              item.$1,
              style: TextStyle(
                  color: const Color(0xFFd0ffd0),
                  fontSize: sw * 0.028),
            ),
            Text(
              item.$2,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: sw * 0.038,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ))
          .toList(),
    );
  }

  // ── calibrate button ──────────────────────────────────────────────────────

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

  // ── fallback screens ──────────────────────────────────────────────────────

  // FIX #5: New screen shown while compass sensor hasn't produced a reading yet
  Widget _buildCalibrating(double sw) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(sw * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF74C365)),
            SizedBox(height: sw * 0.06),
            Text(
              'Waiting for compass...',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: sw * 0.045,
                  fontWeight: FontWeight.w600),
            ),
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
            Icon(Icons.sensors_off,
                color: Colors.grey[600], size: sw * 0.18),
            SizedBox(height: sw * 0.05),
            Text(
              'Location permission required',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: sw * 0.045,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: sw * 0.03),
            Text(
              'Please grant location access to calculate the Qibla direction.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: sw * 0.038),
            ),
            SizedBox(height: sw * 0.06),
            GestureDetector(
              // FIX #8: openAppSettings works; lifecycle observer re-checks on resume
              onTap: openAppSettings,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.08, vertical: sw * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFF74C365),
                  borderRadius: BorderRadius.circular(sw * 0.03),
                ),
                child: Text(
                  'Open settings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: sw * 0.04,
                      fontWeight: FontWeight.w600),
                ),
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
            Text(
              'Location not found',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: sw * 0.045,
                  fontWeight: FontWeight.w600),
            ),
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

// ── Custom painters ───────────────────────────────────────────────────────────

class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final len = size.height * 0.46;

    // Red North half
    final northPaint = Paint()..color = const Color(0xFFE24B4A);
    final northPath = Path()
      ..moveTo(cx, cy - len)
      ..lineTo(cx - 7, cy)
      ..lineTo(cx + 7, cy)
      ..close();
    canvas.drawPath(northPath, northPaint);

    // Grey South half
    final southPaint = Paint()..color = const Color(0xFF555555);
    final southPath = Path()
      ..moveTo(cx, cy + len)
      ..lineTo(cx - 7, cy)
      ..lineTo(cx + 7, cy)
      ..close();
    canvas.drawPath(southPath, southPaint);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => false;
}

class _QiblaNeedlePainter extends CustomPainter {
  final bool aligned;
  const _QiblaNeedlePainter({required this.aligned});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final len = size.height * 0.44;

    final color = aligned ? Colors.amber : const Color(0xFFFFD700);
    final paint = Paint()..color = color;

    // Golden Qibla arrow
    final path = Path()
      ..moveTo(cx, cy - len)
      ..lineTo(cx - 6, cy + len * 0.1)
      ..lineTo(cx, cy - len * 0.05)
      ..lineTo(cx + 6, cy + len * 0.1)
      ..close();
    canvas.drawPath(path, paint);

    // Small Kaaba square at tip
    final tipPaint = Paint()..color = const Color(0xFF013220);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, cy - len + 8),
        width: 10,
        height: 10,
      ),
      tipPaint,
    );
  }

  @override
  // FIX: Also repaint when heading changes (aligned state changes)
  bool shouldRepaint(_QiblaNeedlePainter old) => old.aligned != aligned;
}

class _KaabaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.25, w * 0.8, h * 0.65),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF74C365),
    );

    // Door
    canvas.drawRect(
      Rect.fromLTWH(w * 0.38, h * 0.52, w * 0.24, h * 0.38),
      Paint()..color = const Color(0xFF013220),
    );

    // Top band
    canvas.drawRect(
      Rect.fromLTWH(w * 0.08, h * 0.2, w * 0.84, h * 0.1),
      Paint()..color = const Color(0xFF9FE1CB),
    );
  }

  @override
  bool shouldRepaint(_KaabaPainter old) => false;
}