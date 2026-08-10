// surah_list_page.dart
//
// PURPOSE: এটা এখন শুধু SurahListView কে নিজের Scaffold/AppBar দিয়ে
// wrap করছে — যদি কখনো এই page টা সরাসরি (TabBar ছাড়া) কোথাও থেকে
// navigate করতে হয়, তার জন্য এটা এখনও রাখা হলো।
//
// মূল "home page" হিসেবে এখন থেকে QuranTafsirPage ব্যবহার হবে
// (TabBar সহ) — এটা দেখুন quran_tafsir_page.dart তে।

import 'package:flutter/material.dart';
import '../widgets/surah_list_view.dart';

class SurahListPage extends StatelessWidget {
  const SurahListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Al-Quran')),
      body: const SurahListView(),
    );
  }
}