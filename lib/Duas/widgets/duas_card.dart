import 'package:flutter/material.dart';
import 'package:muslim_app/Duas/model/duas_model.dart';

class DuasCard extends StatelessWidget {
  final DuasModel dua;
  final VoidCallback onFavorite;
  final VoidCallback onBookmark;

  const DuasCard({
    super.key,
    required this.dua,
    required this.onFavorite,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dua.arabic, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(dua.translation['en'] ?? '', style: const TextStyle(fontSize: 14)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(dua.isFavorite ? Icons.star : Icons.star_border),
                  onPressed: onFavorite,
                ),
                IconButton(
                  icon: Icon(dua.isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: onBookmark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}