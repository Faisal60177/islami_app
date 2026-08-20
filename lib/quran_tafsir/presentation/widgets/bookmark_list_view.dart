import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bookmark_provider.dart';
import 'verse_card.dart';

class BookmarkListView extends ConsumerWidget {
  const BookmarkListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkNotifierProvider);

    if (bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'No bookmarks yet.\nTap the bookmark icon on any ayah to save it here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final allVerses = bookmarks.map((b) => b.verse).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) => VerseCard(
        verse: bookmarks[index].verse,
        allVerses: allVerses,
      ),
    );
  }
}