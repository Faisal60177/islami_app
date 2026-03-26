import 'package:flutter/material.dart';
import 'duas_detail_page.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.02),
      itemCount: filteredDuas.length,
      itemBuilder: (context, index) {
        final dua = filteredDuas[index];
        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(
              vertical: screenHeight * 0.008,
              horizontal: screenWidth * 0.02),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.03)),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.012,
                horizontal: screenWidth * 0.03),
            leading: CircleAvatar(
              radius: screenWidth * 0.06,
              backgroundColor: Colors.teal[200],
              child: Text(
                dua.id.toString(),
                style: TextStyle(fontSize: screenWidth * 0.035),
              ),
            ),
            title: Text(
              getShortDescription(dua.arabic),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: screenWidth * 0.045),
            ),
            subtitle: Text(
              "Category: ${dua.category}",
              style: TextStyle(
                  fontSize: screenWidth * 0.035, color: Colors.black54),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                size: screenWidth * 0.04),
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