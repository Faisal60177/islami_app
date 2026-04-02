import 'package:flutter/material.dart';
import '../model/category_model.dart';
import '../model/duas_model.dart';
import '../repository/duas_repository.dart';
import 'duas_detail_page.dart';

class CategoryDuasPage extends StatelessWidget {
  final CategoryModel category;
  const CategoryDuasPage({super.key, required this.category});

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
          category.categoryTitle,
          style: TextStyle(fontSize: screenWidth * 0.05),
        ),
      ),
      body: FutureBuilder<List<DuasModel>>(
        future: DuasRepository().getAllDuas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDuas = snapshot.data!;
          final filteredDuas = allDuas
              .where((d) =>
          d.category.toLowerCase() == category.category.toLowerCase())
              .toList();

          if (filteredDuas.isEmpty) {
            return Center(
              child: Text(
                'No Duas in this category',
                style: TextStyle(fontSize: screenWidth * 0.045),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(padding),
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
                    getShortDescription(dua.tags),
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
        },
      ),
    );
  }
}