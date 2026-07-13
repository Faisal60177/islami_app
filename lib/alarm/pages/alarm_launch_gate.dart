import 'package:flutter/material.dart';
import '../services/alarm_ring_service.dart';
import 'alarm_ringing_page.dart';

class AlarmLaunchGate extends StatefulWidget {
  final Widget child;
  const AlarmLaunchGate({super.key, required this.child});

  @override
  State<AlarmLaunchGate> createState() => _AlarmLaunchGateState();
}

class _AlarmLaunchGateState extends State<AlarmLaunchGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingAlarm());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingAlarm();
    }
  }

  Future<void> _checkPendingAlarm() async {
    final pending = await AlarmRingService.getPendingAlarm();
    if (pending == null || !mounted) return;

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => AlarmRingingPage(
          alarmId: pending['id'] as int,
          prayerLabel: pending['prayerLabel'] as String,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}