import 'package:flutter/material.dart';

const _accent = Color(0xFF4CAF82);

class NotificationEmptyState extends StatelessWidget {
  final bool isFiltered;
  const NotificationEmptyState({super.key, this.isFiltered = false});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(sw * 0.10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: sw * 0.24,
              height: sw * 0.24,
              decoration: BoxDecoration(
                color: const Color(0xFF0D2E1C),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _accent.withOpacity(0.20), width: 1.5),
              ),
              child: Icon(
                isFiltered
                    ? Icons.filter_list_off_rounded
                    : Icons.notifications_off_rounded,
                color: _accent.withOpacity(0.45),
                size: sw * 0.11,
              ),
            ),
            SizedBox(height: sw * 0.055),
            Text(
              isFiltered ? 'Nothing here' : 'All caught up!',
              style: TextStyle(
                color: Colors.white,
                fontSize: sw * 0.050,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: sw * 0.018),
            Text(
              isFiltered
                  ? 'No messages of this type yet.\nTry a different filter.'
                  : 'New hadiths, duas and updates\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: sw * 0.034,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}