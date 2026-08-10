// quran_tafsir_page.dart
//
// PURPOSE: এটাই Quran (Tafsir/Translation) feature এর পূর্ণাঙ্গ home page।
// tools_page.dart থেকে tap করলে এখানেই আসবে। উপরে TabBar দিয়ে দুটো
// ট্যাব — "Surah" (chapter list) আর "Juz" (para list) — একই page এ
// swipe করে switch করা যায়, ঠিক Quran.com এর app এর মতো familiar pattern।
//
// DefaultTabController ব্যবহার করা হচ্ছে কারণ এখানে tab state কোনো
// business logic বহন করে না (শুধু UI navigation), তাই Riverpod provider
// বানানোর দরকার নেই — Flutter এর built-in tab management যথেষ্ট।

import 'package:flutter/material.dart';
import '../widgets/surah_list_view.dart';
import '../widgets/juz_list_view.dart';

// ignore: camel_case_types
class QuranTafsirPage extends StatelessWidget {
  const QuranTafsirPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Al-Quran'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Surah'),
              Tab(text: 'Juz'),
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