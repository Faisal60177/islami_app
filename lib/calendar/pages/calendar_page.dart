import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF013220),
      appBar: AppBar(
        title: const Text(
          'Calendar',
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFF49796B),
      ),
    );
  }
}
