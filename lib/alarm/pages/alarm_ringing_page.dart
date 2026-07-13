import 'dart:async';
import 'package:flutter/material.dart';
import '../services/alarm_ring_service.dart';

class AlarmRingingPage extends StatefulWidget {
  final int alarmId;
  final String prayerLabel;

  const AlarmRingingPage({
    super.key,
    required this.alarmId,
    required this.prayerLabel,
  });

  @override
  State<AlarmRingingPage> createState() => _AlarmRingingPageState();
}

class _AlarmRingingPageState extends State<AlarmRingingPage> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _timeLabel() {
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final m = _now.minute.toString().padLeft(2, '0');
    final ap = _now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  Future<void> _stop() async {
    await AlarmRingService.requestStop(widget.alarmId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // block back button — must use Stop, like a real alarm
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1410),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 48),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icons/AppIcon.png',
                    width: 96,
                    height: 96,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Muslim Life',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  widget.prayerLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "It's time for prayer",
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  _timeLabel(),
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DA672),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _stop,
                    child: const Text(
                      'Stop Alarm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}