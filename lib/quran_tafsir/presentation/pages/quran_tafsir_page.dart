import 'package:flutter/material.dart';
import '../widgets/surah_list_view.dart';
import '../widgets/juz_list_view.dart';
import '../widgets/quran_settings_button.dart';

class QuranTafsirPage extends StatelessWidget {
  const QuranTafsirPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Al Quran Tafsir"),
          actions: const [
            QuranSettingsButton(),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Surah"),
              Tab(text: "Para"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SurahListView(),
            JuzListView(),
          ],
        ),
      ),
    );
  }
}