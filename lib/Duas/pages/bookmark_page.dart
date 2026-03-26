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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.03;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bookmarked Duas",
          style: TextStyle(fontSize: screenWidth * 0.05),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookmarkedDuas.isEmpty
          ? Center(
        child: Text(
          "No bookmarked duas yet",
          style: TextStyle(fontSize: screenWidth * 0.045),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(padding),
        itemCount: bookmarkedDuas.length,
        itemBuilder: (context, index) {
          final dua = bookmarkedDuas[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(
              vertical: screenHeight * 0.01,
              horizontal: screenWidth * 0.02,
            ),
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(screenWidth * 0.03)),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.015,
                horizontal: screenWidth * 0.04,
              ),
              leading: CircleAvatar(
                radius: screenWidth * 0.06,
                backgroundColor: Colors.green[200],
                child: Text(
                  dua.id.toString(),
                  style: TextStyle(fontSize: screenWidth * 0.045),
                ),
              ),
              title: Text(
                getShortDescription(dua.arabic),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                ),
              ),
              subtitle: Text(
                "Category: ${dua.category}",
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  color: Colors.black54,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: screenWidth * 0.045),
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