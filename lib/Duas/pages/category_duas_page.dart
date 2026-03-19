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
    return Scaffold(
      appBar: AppBar(title: Text(category.categoryTitle)),
      body: FutureBuilder<List<DuasModel>>(
        future: DuasRepository().getAllDuas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allDuas = snapshot.data!;
          final filteredDuas = allDuas
              .where((d) => d.category.toLowerCase() == category.category.toLowerCase())
              .toList();

          if (filteredDuas.isEmpty) return const Center(child: Text('No Duas in this category'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredDuas.length,
            itemBuilder: (context, index) {
              final dua = filteredDuas[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(dua.id.toString()),
                    backgroundColor: Colors.teal[100],
                  ),
                  title: Text(
                    dua.arabic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    dua.translation['en'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
        },
      ),
    );
  }
}