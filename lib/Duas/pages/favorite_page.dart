import 'package:flutter/material.dart';
import '../model/duas_model.dart';
import '../repository/duas_repository.dart';
import 'duas_detail_page.dart';

class FavoriteDuasPage extends StatefulWidget {
  final String searchQuery;
  const FavoriteDuasPage({super.key, required this.searchQuery});

  @override
  State<FavoriteDuasPage> createState() => _FavoriteDuasPageState();
}

class _FavoriteDuasPageState extends State<FavoriteDuasPage> {
  final DuasRepository repository = DuasRepository();
  List<DuasModel> favoriteDuas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDuas();
  }

  Future<void> loadDuas() async {
    final duas = await repository.getAllDuas();
    setState(() {
      favoriteDuas = duas.where((d) => d.isFavorite).toList();
      isLoading = false;
    });
  }

  List<DuasModel> get filteredDuas {
    if (widget.searchQuery.isEmpty) return favoriteDuas;
    final query = widget.searchQuery.toLowerCase();
    return favoriteDuas.where((d) =>
    d.arabic.toLowerCase().contains(query) ||
        d.transliteration.toLowerCase().contains(query) ||
        d.category.toLowerCase().contains(query)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      itemCount: filteredDuas.length,
      itemBuilder: (context, index) {
        final dua = filteredDuas[index];
        return ListTile(
          title: Text(dua.arabic),
          subtitle: Text("Category: ${dua.category}"),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => DuasDetailPage(dua: dua))),
        );
      },
    );
  }
}