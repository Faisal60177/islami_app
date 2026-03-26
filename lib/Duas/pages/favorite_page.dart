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

  String getShortDescription(String text, [int limit = 60]) {
    if (text.length <= limit) return text;
    return text.substring(0, limit) + '...';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.03;

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: filteredDuas.length,
      itemBuilder: (context, index) {
        final dua = filteredDuas[index];
        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(
            vertical: screenHeight * 0.01,
            horizontal: screenWidth * 0.02,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.015,
              horizontal: screenWidth * 0.04,
            ),
            title: Text(
              getShortDescription(dua.arabic),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "Category: ${dua.category}",
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                color: Colors.black54,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: screenWidth * 0.045),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DuasDetailPage(dua: dua)),
              );
            },
          ),
        );
      },
    );
  }
}