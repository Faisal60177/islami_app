import 'package:flutter/material.dart';
import 'package:muslim_app/features/quran_tafsir/presentation/widgets/surah_list_view.dart';
import 'package:muslim_app/features/quran_tafsir/presentation/widgets/juz_list_view.dart';
import 'package:muslim_app/features/quran_tafsir/presentation/widgets/quran_settings_button.dart';
import 'package:muslim_app/features/quran_tafsir/presentation/widgets/bookmark_list_view.dart';

class QuranTafsirPage extends StatelessWidget {
  const QuranTafsirPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
              Tab(text: "Bookmarks")
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SurahListView(),
            JuzListView(),
            BookmarkListView(),
          ],
        ),
      ),
    );
  }
}