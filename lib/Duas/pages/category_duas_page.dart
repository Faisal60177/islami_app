import 'package:flutter/material.dart';
import '../model/category_model.dart';
import '../model/duas_model.dart';
import '../repository/duas_repository.dart';
import 'duas_detail_page.dart';

class CategoryDuasPage extends StatefulWidget {
  final CategoryModel category;
  const CategoryDuasPage({super.key, required this.category});

  @override
  State<CategoryDuasPage> createState() => _CategoryDuasPageState();
}

class _CategoryDuasPageState extends State<CategoryDuasPage> {
  final DuasRepository repository = DuasRepository();
  List<DuasModel> duas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDuas();
  }

  Future<void> loadDuas() async {
    setState(() => isLoading = true);
    // ✅ directly query by category — no getAllDuas + Dart filter
    final data = await repository
        .getDuasByCategory(widget.category.categoryTitle);
    setState(() {
      duas = data;
      isLoading = false;
    });
  }

  String getShortDescription(String text, [int limit = 60]) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.categoryTitle,
            style: TextStyle(fontSize: w * 0.05)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : duas.isEmpty
          ? Center(
          child: Text('No Duas in this category',
              style: TextStyle(fontSize: w * 0.045)))
          : RefreshIndicator(
        onRefresh: loadDuas,
        child: ListView.builder(
          padding: EdgeInsets.all(w * 0.03),
          itemCount: duas.length,
          itemBuilder: (context, index) {
            final dua = duas[index];
            return Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(
                  vertical: h * 0.008, horizontal: w * 0.02),
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(w * 0.03)),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                    vertical: h * 0.012,
                    horizontal: w * 0.03),
                leading: CircleAvatar(
                  radius: w * 0.06,
                  backgroundColor: Colors.teal[200],
                  child: Text(dua.id.toString(),
                      style:
                      TextStyle(fontSize: w * 0.035)),
                ),
                title: Text(
                  getShortDescription(dua.tags),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: w * 0.045),
                ),
                subtitle: Text(
                  'Category: ${dua.categoryTitle}',
                  style: TextStyle(
                      fontSize: w * 0.035,
                      color: Colors.black54),
                ),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: w * 0.04),
                onTap: () async {
                  // ✅ await so we can detect when user comes back
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            DuasDetailPage(dua: dua)),
                  );
                  // no reload needed here — category list has no
                  // favorite/bookmark icons to update
                },
              ),
            );
          },
        ),
      ),
    );
  }
}