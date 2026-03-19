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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dua Detail"),
        actions: [
          IconButton(
            icon: Icon(
              dua.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.redAccent,
            ),
            onPressed: toggleFavorite,
          ),
          IconButton(
            icon: Icon(
              dua.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.blueAccent,
            ),
            onPressed: toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Arabic",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              dua.arabic,
              style: const TextStyle(fontSize: 22, color: Colors.black87),
              textAlign: TextAlign.right,
            ),
            const Divider(height: 24),

            Text(
              "Transliteration",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              dua.transliteration,
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const Divider(height: 24),

            Text(
              "Translation (English)",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              dua.translation['en'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Divider(height: 24),

            Text(
              "Translation (Bangla)",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              dua.translation['bn'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Divider(height: 24),

            if (dua.reference.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reference",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dua.reference,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const Divider(height: 24),
                ],
              ),

            // 🔊 Audio button
            if (dua.audioUrl != null && dua.audioUrl!.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  // Play audio logic here (use just_audio or audioplayers package)
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text("Play Audio"),
              ),
          ],
        ),
      ),
    );
  }
}