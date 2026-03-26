import 'package:flutter/material.dart';
import '../model/category_model.dart';
import '../model/duas_model.dart';
import '../repository/duas_repository.dart';
import 'duas_detail_page.dart';

class CategoryDuasPage extends StatelessWidget {
  final CategoryModel category;
  const CategoryDuasPage({super.key, required this.category});

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
                margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                elevation: 3,
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.015,
                    horizontal: screenWidth * 0.04,
                  ),
                  leading: CircleAvatar(
                    radius: screenWidth * 0.06,
                    child: Text(
                      dua.id.toString(),
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    backgroundColor: Colors.teal[100],
                  ),
                  title: Text(
                    dua.arabic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  subtitle: Text(
                    dua.translation['en'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: screenWidth * 0.04),
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