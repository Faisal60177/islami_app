import 'package:flutter/material.dart';
import '../widgets/surah_list_view.dart';

class SurahListPage extends StatelessWidget {
  const SurahListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Al-quran_tilawat')),
      body: const SurahListView(),
    );
  }
}