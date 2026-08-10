// surah_detail_page.dart
//
// PURPOSE: একটা নির্দিষ্ট Surah এর ভিতরে ঢুকলে এই page দেখা যাবে —
// প্রতিটা Ayah এর Arabic text, Translation, আর Audio play বাটন।
//
// verseReaderNotifierProvider একটা "family" provider, তাই এখানে
// params (VerseReaderParams) পাঠাতে হচ্ছে। User এর saved preference
// (কোন translation, কোন reciter) quranPreferencesProvider থেকে আসছে।

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/verse_reader_provider.dart';
import '../providers/user_preference_provider.dart';
import '../providers/audio_player_provider.dart';
import '../../domain/entities/verse.dart';

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
      appBar: AppBar(title: Text(chapterName)),
      // প্রথমে user এর preference (translation/reciter choice) লোড হতে হবে,
      // তারপরই verse fetch করা সম্ভব — তাই nested .when() ব্যবহার হচ্ছে।
      body: preferencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('সেটিংস লোড করা যায়নি।')),
        data: (preferences) {
          final params = VerseReaderParams(
            chapterNumber: chapterNumber,
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
              Text(
                'আয়াত লোড করা যায়নি।\nইন্টারনেট সংযোগ চেক করুন।',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(
                  verseReaderNotifierProvider(params),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      ),
      data: (verses) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: verses.length,
        itemBuilder: (context, index) {
          return _VerseCard(verse: verses[index]);
        },
      ),
    );
  }
}

class _VerseCard extends ConsumerWidget {
  final Verse verse;

  const _VerseCard({required this.verse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(quranAudioPlayerNotifierProvider);
    final isCurrentlyPlaying = audioState.currentVerseKey == verse.verseKey &&
        audioState.status == QuranAudioStatus.playing;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ayah number + Audio play button ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(
                    '${verse.verseNumber}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // audio.url না থাকলে বাটন disable থাকবে
                IconButton(
                  icon: Icon(
                    isCurrentlyPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    size: 32,
                  ),
                  onPressed: verse.audio == null
                      ? null
                      : () {
                    final notifier = ref.read(
                      quranAudioPlayerNotifierProvider.notifier,
                    );
                    if (isCurrentlyPlaying) {
                      notifier.pause();
                    } else {
                      notifier.playVerse(verse);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Arabic Text ───────────────────────────────────────────
            Text(
              verse.textUthmani,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 24,
                fontFamily: 'Uthmanic', // আপনার app এ যে Arabic font আছে
                height: 1.8,
              ),
            ),

            // ── Translation(s) ────────────────────────────────────────
            if (verse.translations.isNotEmpty) ...[
              const Divider(height: 24),
              ...verse.translations.map(
                    (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    t.text,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}