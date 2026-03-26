import 'package:flutter/material.dart';
import '../repository/duas_repository.dart';
import '../model/category_model.dart';
import 'category_duas_page.dart';

class CategoryPage extends StatelessWidget {
  final String searchQuery;
  const CategoryPage({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.03;

    return FutureBuilder<List<CategoryModel>>(
      future: DuasRepository().getAllCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data!
            .where((cat) =>
            cat.categoryTitle.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

        if (categories.isEmpty) {
          return Center(
            child: Text(
              'No categories found',
              style: TextStyle(fontSize: screenWidth * 0.045),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(padding),
          child: GridView.builder(
            itemCount: categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: padding,
              mainAxisSpacing: padding,
              childAspectRatio: 3 / 2,
            ),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryDuasPage(category: cat),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                  elevation: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat.categoryIcon == 'sun'
                            ? Icons.wb_sunny
                            : Icons.nightlight_round,
                        size: screenWidth * 0.12,
                        color: Colors.teal,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        cat.categoryTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.045,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}