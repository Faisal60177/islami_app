import 'package:flutter/material.dart';
import '../model/duas_model.dart';
import '../repository/duas_repository.dart';
import 'duas_detail_page.dart';

class BookmarkedDuasPage extends StatefulWidget {
  final String searchQuery;
  const BookmarkedDuasPage({super.key, required this.searchQuery});
  @override
  State<BookmarkedDuasPage> createState() => _BookmarkedDuasPageState();
}

class _BookmarkedDuasPageState extends State<BookmarkedDuasPage> {
  final DuasRepository repository = DuasRepository();
  List<DuasModel> bookmarkedDuas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBookmarks();
  }

  Future<void> loadBookmarks() async {
    final allDuas = await repository.getAllDuas();
    setState(() {
      bookmarkedDuas = allDuas.where((dua) => dua.isBookmarked).toList();
      isLoading = false;
    });
  }

  String getShortDescription(String text, [int limit = 60]) {
    if (text.length <= limit) return text;
    return text.substring(0, limit) + '...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bookmarked Duas")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookmarkedDuas.isEmpty
          ? const Center(child: Text("No bookmarked duas yet"))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: bookmarkedDuas.length,
        itemBuilder: (context, index) {
          final dua = bookmarkedDuas[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 12),
              leading: CircleAvatar(
                child: Text(dua.id.toString()),
                backgroundColor: Colors.green[200],
              ),
              title: Text(
                getShortDescription(dua.arabic),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16),
              ),
              subtitle: Text(
                "Category: ${dua.category}",
                style:
                const TextStyle(fontSize: 12, color: Colors.black54),
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
      ),
    );
  }
}