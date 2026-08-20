
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/verse_reader_provider.dart';
import '../providers/user_preference_provider.dart';
import '../providers/chapter_list_provider.dart';
import '../widgets/appbar_switcher_title.dart';
import '../widgets/chapter_juz_picker_sheet.dart';
import '../widgets/quran_settings_button.dart';
import '../widgets/verse_card.dart';
import '../../domain/entities/verse.dart';
import '../../domain/entities/chapter.dart';
import '../widgets/quran_audio_bar.dart';

class SurahDetailPage extends ConsumerWidget {
  final int chapterNumber;
  final String chapterName;

  const SurahDetailPage({
    super.key,
    required this.chapterNumber,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(quranPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: AppBarSwitcherTitle(
          currentLabel: chapterName,
          pickerType: PickerType.juz,
          currentJuzNumber: chapterNumber,
        ),
        actions: const [
          QuranSettingsButton(),
        ],),
      body: preferencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Error loading preferences')),
        data: (preferences) {
          final params = VerseReaderParams(
            chapterNumber: chapterNumber,
            translationIds: preferences.translationIds,
            reciterId: preferences.reciterId,
          );
          return _VerseListView(params: params, chapterId: chapterNumber);
        },
      ),
      bottomNavigationBar: const QuranAudioBar(),
    );
  }
}

class _VerseListView extends ConsumerWidget {
  final VerseReaderParams params;
  final int chapterId;

  const _VerseListView({required this.params, required this.chapterId});

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
          error: (_, __) => _buildList(verses, null),
          data: (chapters) {
            final chapter = chapters.cast<Chapter?>().firstWhere(
                  (c) => c?.id == chapterId,
              orElse: () => null,
            );
            return _buildList(verses, chapter);
          },
        );
      },
    );
  }

  Widget _buildList(List<Verse> verses, Chapter? chapter) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: verses.length + (chapter != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (chapter != null && index == 0) {
          return _ChapterHeader(chapter: chapter, verses: verses);
        }
        final verseIndex = chapter != null ? index - 1 : index;
        return VerseCard(verse: verses[verseIndex], allVerses: verses);
      },
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  final Chapter chapter;
  final List<Verse> verses;
  const _ChapterHeader({required this.chapter, required this.verses});

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
            '${chapter.translatedName} • ${chapter.revelationPlace} • ${chapter.versesCount} Ayahs',
            style: Theme.of(context).textTheme.bodySmall,

          ),
      const SizedBox(height: 12),
      Consumer(
        builder: (context, ref, _) => ElevatedButton.icon(
          onPressed: () => ref
              .read(quranAudioPlayerNotifierProvider.notifier)
              .playVerse(verses.first, queue: verses),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Play Surah'),
        ),
      ),
        ],
      ),
    );
  }
}