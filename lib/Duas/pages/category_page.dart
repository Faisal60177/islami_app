import 'package:flutter/material.dart';
import '../repository/duas_repository.dart';
import '../model/category_model.dart';
import 'category_duas_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'all_duas_page.dart';
import 'category_page.dart';
import 'favorite_page.dart';
import 'bookmark_page.dart';

class CategoryPage extends StatelessWidget {
  final String searchQuery;
  const CategoryPage({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: DuasRepository().getAllCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categories = snapshot.data!
            .where((cat) => cat.categoryTitle.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

        if (categories.isEmpty) return const Center(child: Text('No categories found'));

        return Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat.categoryIcon == 'sun'
                            ? Icons.wb_sunny
                            : Icons.nightlight_round,
                        size: 40,
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.categoryTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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