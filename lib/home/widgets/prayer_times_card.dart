import 'package:flutter/material.dart';
import 'package:muslim_app/home/model/prayer_times_models.dart';
import 'package:intl/intl.dart';

class PrayerTimesCard extends StatelessWidget {
  final PrayerTimesModel prayerTimes;

  const PrayerTimesCard({super.key, required this.prayerTimes});

  String formatTime(DateTime dt) {
    return DateFormat.Hm().format(dt); // HH:mm format
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow("Fajr", prayerTimes.fajrStart, prayerTimes.fajrEnd),
            _buildRow("Dhuhr", prayerTimes.dhuhrStart, prayerTimes.dhuhrEnd),
            _buildRow("Asr", prayerTimes.asrStart, prayerTimes.asrEnd),
            _buildRow("Maghrib", prayerTimes.maghribStart, prayerTimes.maghribEnd),
            _buildRow("Isha", prayerTimes.ishaStart, prayerTimes.ishaEnd),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String name, DateTime start, DateTime end) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text("${formatTime(start)} - ${formatTime(end)}", style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}