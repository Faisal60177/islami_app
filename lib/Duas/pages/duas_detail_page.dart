import 'package:flutter/material.dart';
import '../model/duas_model.dart';
import '../repository/duas_repository.dart';

class DuasDetailPage extends StatefulWidget {
  final DuasModel dua;
  const DuasDetailPage({super.key, required this.dua});

  @override
  State<DuasDetailPage> createState() => _DuasDetailPageState();
}

class _DuasDetailPageState extends State<DuasDetailPage> {
  late DuasModel dua;

  @override
  void initState() {
    super.initState();
    dua = widget.dua;
  }

  void toggleFavorite() async {
    await DuasRepository().toggleFavorite(dua);
    setState(() {
      dua.isFavorite = !dua.isFavorite;
    });
  }

  void toggleBookmark() async {
    await DuasRepository().toggleBookmark(dua);
    setState(() {
      dua.isBookmarked = !dua.isBookmarked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.04;
    final spacing = screenHeight * 0.015;

    return Scaffold(
      appBar: AppBar(
        title: Text("Dua Detail", style: TextStyle(fontSize: screenWidth * 0.05)),
        actions: [
          IconButton(
            icon: Icon(
              dua.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.redAccent,
              size: screenWidth * 0.07,
            ),
            onPressed: toggleFavorite,
          ),
          IconButton(
            icon: Icon(
              dua.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.blueAccent,
              size: screenWidth * 0.07,
            ),
            onPressed: toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arabic
            Text(
              "Arabic",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05),
            ),
            SizedBox(height: spacing / 2),
            Text(
              dua.arabic,
              style: TextStyle(fontSize: screenWidth * 0.055, color: Colors.black87),
              textAlign: TextAlign.right,
            ),
            Divider(height: spacing * 2),

            // Transliteration
            Text(
              "Transliteration",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05),
            ),
            SizedBox(height: spacing / 2),
            Text(
              dua.transliteration,
              style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black87),
            ),
            Divider(height: spacing * 2),

            // Translation English
            Text(
              "Translation (English)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05),
            ),
            SizedBox(height: spacing / 2),
            Text(
              dua.translation['en'] ?? '',
              style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.black87),
            ),
            Divider(height: spacing * 2),

            // Translation Bangla
            Text(
              "Translation (Bangla)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05),
            ),
            SizedBox(height: spacing / 2),
            Text(
              dua.translation['bn'] ?? '',
              style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.black87),
            ),
            Divider(height: spacing * 2),

            // Reference
            if (dua.reference.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reference",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05),
                  ),
                  SizedBox(height: spacing / 2),
                  Text(
                    dua.reference,
                    style: TextStyle(fontSize: screenWidth * 0.038, color: Colors.black54),
                  ),
                  Divider(height: spacing * 2),
                ],
              ),

            // Audio Button
            if (dua.audioUrl != null && dua.audioUrl!.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  // Audio playback logic here
                },
                icon: Icon(Icons.play_arrow, size: screenWidth * 0.06),
                label: Text("Play Audio", style: TextStyle(fontSize: screenWidth * 0.045)),
              ),
          ],
        ),
      ),
    );
  }
}