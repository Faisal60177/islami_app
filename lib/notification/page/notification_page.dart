import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF013220),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFF49796B),
      ),
    );
  }
}
