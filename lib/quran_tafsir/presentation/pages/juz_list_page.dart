import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/juz_list_view.dart';

class JuzListPage extends StatelessWidget{
  const JuzListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Al-quran_tilawat')),
      body: const JuzListView(),
    );
  }

}