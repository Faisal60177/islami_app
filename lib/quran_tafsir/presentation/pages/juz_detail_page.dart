import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/verse_reader_provider.dart';
import '../providers/user_preference_provider.dart';
import '../providers/chapter_list_provider.dart';
import '../widgets/quran_settings_button.dart';
import '../widgets/verse_card.dart';
import '../../domain/entities/verse.dart';
import '../../domain/entities/chapter.dart';

class JuzDetailPage extends ConsumerWidget {
  final int juzNumber;
  final String juzName;

  const JuzDetailPage({
    super.key,
    required this.juzNumber,
    required this.juzName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(quranPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(juzName),
        actions: const [
          QuranSettingsButton(),
        ],),
      body: preferencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Error loading preferences')),
        data: (preferences) {
          final params = VerseReaderParams(
            juzNumber: juzNumber,
            translationIds: preferences.translationIds,
            reciterId: preferences.reciterId,
          );
          return _VerseListView(params: params);
        },
      ),
    );
  }
}

class _VerseListView extends ConsumerWidget {
  final VerseReaderParams params;

  const _VerseListView({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versesAsync = ref.watch(verseReaderNotifierProvider(params));
    final chaptersAsync = ref.watch(chapterListNotifierProvider);

    return versesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                "Ayah didn't load.\ncheck your internet",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(
                  verseReaderNotifierProvider(params),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
      data: (verses) {
        return chaptersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildList(verses, []),
          data: (chapters) => _buildList(verses, chapters),
        );
      },
    );
  }

  Widget _buildList(List<Verse> verses, List<Chapter> chapters) {
    final List<dynamic> items = [];
    int? lastChapterId;

    for (final verse in verses) {
      if (verse.chapterId != lastChapterId) {
        final chapter = chapters.cast<Chapter?>().firstWhere(
              (c) => c?.id == verse.chapterId,
          orElse: () => null,
        );
        items.add(chapter ?? verse.chapterId);
        lastChapterId = verse.chapterId;
      }
      items.add(verse);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is Chapter) {
          return _ChapterHeader(chapter: item);
        } else if (item is int) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Surah $item', style: Theme.of(context).textTheme.titleLarge),
          );
        }
        return VerseCard(verse: item as Verse, allVerses: verses);
      },
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  final Chapter chapter;
  const _ChapterHeader({required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            chapter.nameArabic,
            style: const TextStyle(fontSize: 28, fontFamily: 'Uthmanic'),
          ),
          const SizedBox(height: 8),
          Text(
            chapter.nameSimple,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${chapter.translatedName} • ${chapter.revelationPlace}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}