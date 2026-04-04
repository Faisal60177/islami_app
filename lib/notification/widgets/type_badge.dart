import 'package:flutter/material.dart';
import '../model/notification_model.dart';

class TypeBadge extends StatelessWidget {
  final NotificationType type;
  final bool large;
  const TypeBadge({super.key, required this.type, this.large = false});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final (label, bg, fg) = _style();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sw * (large ? 0.035 : 0.022),
        vertical:   sw * (large ? 0.012 : 0.007),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(sw * 0.05),
        border: Border.all(color: fg.withOpacity(0.35), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: sw * (large ? 0.032 : 0.026),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  (String, Color, Color) _style() {
    switch (type) {
      case NotificationType.hadith:
        return ('Hadith', const Color(0xFF0A3D25), const Color(0xFF4CAF82));
      case NotificationType.dua:
        return ('Dua',    const Color(0xFF0E2A3B), const Color(0xFF64B5F6));
      case NotificationType.ad:
        return ('Ad',     const Color(0xFF3B0E0E), const Color(0xFFEF9A9A));
      case NotificationType.info:
        return ('Info',   const Color(0xFF2A2210), const Color(0xFFFFCC80));
    }
  }
}