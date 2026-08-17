import 'package:flutter/material.dart';
import 'quran_settings_sheet.dart';

class QuranSettingsButton extends StatelessWidget {
  const QuranSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Reciter and Translation Settings',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Color(0xff00563B),
          builder: (_) => const QuranSettingsSheet(),
        );
      },
    );
  }
}