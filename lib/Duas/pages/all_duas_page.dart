import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:islamic_app/Duas/cubit/duas_state.dart';
import 'package:islamic_app/Duas/cubit/duas_cubit.dart';
import 'duas_page.dart';
import 'duas_detail_page.dart';

import 'package:flutter/material.dart';
import '../model/duas_model.dart';
import '../repository/duas_repository.dart';

class AllDuasPage extends StatefulWidget {
  final String searchQuery;
  const AllDuasPage({super.key, required this.searchQuery});

  @override
  State<AllDuasPage> createState() => _AllDuasPageState();
}

class _AllDuasPageState extends State<AllDuasPage> {
  final DuasRepository repository = DuasRepository();
  List<DuasModel> allDuas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDuas();
  }

  Future<void> loadDuas() async {
    final duas = await repository.getAllDuas();
    setState(() {
      allDuas = duas;
      isLoading = false;
    });
  }

  List<DuasModel> get filteredDuas {
    if (widget.searchQuery.isEmpty) return allDuas;
    final query = widget.searchQuery.toLowerCase();
    return allDuas.where((dua) =>
    dua.arabic.toLowerCase().contains(query) ||
        dua.transliteration.toLowerCase().contains(query) ||
        dua.category.toLowerCase().contains(query)
    ).toList();
  }

  String getShortDescription(String text, [int limit = 60]) {
    if (text.length <= limit) return text;
    return text.substring(0, limit) + '...';
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredDuas.length,
      itemBuilder: (context, index) {
        final dua = filteredDuas[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            leading: CircleAvatar(
              child: Text(dua.id.toString()),
              backgroundColor: Colors.teal[200],
            ),
            title: Text(
              getShortDescription(dua.arabic),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
            ),
            subtitle: Text(
              "Category: ${dua.category}",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DuasDetailPage(dua: dua),
                ),
              );
            },
          ),
        );
      },
    );
  }
}