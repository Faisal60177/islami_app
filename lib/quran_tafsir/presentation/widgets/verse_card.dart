import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/audio_player_provider.dart';
import '../providers/user_preference_provider.dart';
import '../../domain/entities/verse.dart';

const int _kTransliterationResourceId = 57;

class VerseCard extends ConsumerStatefulWidget {
  final Verse verse;
  final List<Verse> allVerses;

  const VerseCard({
    super.key,
    required this.verse,
    required this.allVerses,
  });

  @override
  ConsumerState<VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends ConsumerState<VerseCard> {
  final GlobalKey _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final verse = widget.verse;

    final isCurrentlyPlaying = ref.watch(
      quranAudioPlayerNotifierProvider.select(
            (s) =>
        s.currentVerseKey == verse.verseKey &&
            s.status == QuranAudioStatus.playing,
      ),
    );
    final isLoadingThisVerse = ref.watch(
      quranAudioPlayerNotifierProvider.select(
            (s) =>
        s.currentVerseKey == verse.verseKey &&
            s.status == QuranAudioStatus.loading,
      ),
    );
    final position = isCurrentlyPlaying
        ? ref.watch(quranAudioPlayerNotifierProvider.select((s) => s.position))
        : Duration.zero;

    // ── Auto-scroll: এই card টা "playing" হয়ে ওঠার মুহূর্তে ──
    ref.listen(
      quranAudioPlayerNotifierProvider.select(
            (s) => s.currentVerseKey == verse.verseKey,
      ),
          (previous, isNowActive) {
        if (isNowActive == true && previous != true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = _cardKey.currentContext;
            if (ctx != null) {
              Scrollable.ensureVisible(
                ctx,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                alignment: 0.2, // screen এর উপরের দিকে রাখা, একদম top না
              );
            }
          });
        }
      },
    );

    final fontSizeAsync = ref.watch(
      quranPreferencesProvider.select((s) => s.valueOrNull?.arabicFontSize),
    );
    final arabicFontSize = fontSizeAsync ?? 26.0;

    return Card(
      key: _cardKey,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentlyPlaying
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ActionButtons(verse: verse, allVerses: widget.allVerses),
                Text(
                  verse.verseKey,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ArabicVerseText(
              verse: verse,
              currentPositionMs: position.inMilliseconds,
              isThisVersePlaying: isCurrentlyPlaying,
              fontSize: arabicFontSize,
            ),

            // ── Transliteration: আলাদা, italic, translation থেকে আলাদা ──
            if (_transliterationOf(verse) != null) ...[
              const SizedBox(height: 12),
              Text(
                _stripHtmlTags(_transliterationOf(verse)!.text),
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ],

            if (_otherTranslationsOf(verse).isNotEmpty) ...[
              const Divider(height: 28),
              ..._otherTranslationsOf(verse)
                  .map((t) => _TranslationTile(translation: t)),
            ],
          ],
        ),
      ),
    );
  }

  VerseTranslation? _transliterationOf(Verse verse) {
    try {
      return verse.translations
          .firstWhere((t) => t.resourceId == _kTransliterationResourceId);
    } catch (_) {
      return null;
    }
  }

  List<VerseTranslation> _otherTranslationsOf(Verse verse) {
    return verse.translations
        .where((t) => t.resourceId != _kTransliterationResourceId)
        .toList();
  }

  String _stripHtmlTags(String text) => text.replaceAll(RegExp(r'<[^>]*>'), '');
}

// Arabic Text: word-by-word highlight + dynamic font size
class _ArabicVerseText extends StatelessWidget {
  final Verse verse;
  final int currentPositionMs;
  final bool isThisVersePlaying;
  final double fontSize;

  const _ArabicVerseText({
    required this.verse,
    required this.currentPositionMs,
    required this.isThisVersePlaying,
    required this.fontSize,
  });

  (int, int)? _activeWordRange() {
    if (!isThisVersePlaying) return null;
    final segments = verse.audio?.segments ?? [];
    for (final seg in segments) {
      if (currentPositionMs >= seg.startMs && currentPositionMs <= seg.endMs) {
        return (seg.wordStart, seg.wordEnd);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontFamily: 'Uthmanic',
      height: 2.0,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final highlightColor = Theme.of(context).colorScheme.primary;
    if (verse.words.isEmpty) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: verse.textUthmani, style: baseStyle),
            const TextSpan(text: ' '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _AyahNumberOrnament(number: verse.verseNumber, size: fontSize),
            ),
          ],
        ),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      );
    }

    final activeRange = _activeWordRange();
    final spans = <InlineSpan>[];

    for (final word in verse.words) {
      if (word.charType == 'end') continue;

      final isActive = activeRange != null &&
          word.position >= activeRange.$1 &&
          word.position <= activeRange.$2;

      spans.add(
        TextSpan(
          text: '${word.textUthmani} ',
          style: baseStyle.copyWith(
            color: isActive ? highlightColor : baseStyle.color,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      );
    }

    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _AyahNumberOrnament(number: verse.verseNumber, size: fontSize),
      ),
    );

    return Text.rich(
      TextSpan(children: spans, style: baseStyle),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
    );
  }
}

class _AyahNumberOrnament extends StatelessWidget {
  final int number;
  final double size;
  const _AyahNumberOrnament({required this.number, required this.size});

  @override
  Widget build(BuildContext context) {
    final ornamentSize = size * 1.35; // Arabic font size এর অনুপাতে scale
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.brightness_low,
            size: ornamentSize,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          Text(
            '$number',
            style: TextStyle(
              fontSize: ornamentSize * 0.27,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


// Action buttons: play/pause + copy + share
class _ActionButtons extends ConsumerWidget {
  final Verse verse;
  final List<Verse> allVerses;

  const _ActionButtons({required this.verse, required this.allVerses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentlyPlaying = ref.watch(
      quranAudioPlayerNotifierProvider.select(
            (s) =>
        s.currentVerseKey == verse.verseKey &&
            s.status == QuranAudioStatus.playing,
      ),
    );
    final isLoadingThisVerse = ref.watch(
      quranAudioPlayerNotifierProvider.select(
            (s) =>
        s.currentVerseKey == verse.verseKey &&
            s.status == QuranAudioStatus.loading,
      ),
    );

    return Row(
      children: [
        isLoadingThisVerse
            ? const SizedBox(
          width: 32,
          height: 32,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
            : IconButton(
          icon: Icon(
            isCurrentlyPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_fill,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: verse.audio == null
              ? null
              : () {
            final notifier =
            ref.read(quranAudioPlayerNotifierProvider.notifier);
            if (isCurrentlyPlaying) {
              notifier.pause();
            } else {
              notifier.playVerse(verse, queue: allVerses);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 20),
          onPressed: () {
            final translationText = verse.translations.isNotEmpty
                ? verse.translations.first.text
                : '';
            Clipboard.setData(
              ClipboardData(text: '${verse.textUthmani}\n\n$translationText'),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ayah copied to clipboard'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded, size: 20),
          onPressed: () {
            final translationText = verse.translations.isNotEmpty
                ? verse.translations.first.text
                : '';
            Share.share(
              '${verse.textUthmani}\n\n$translationText\n\nShared via Muslim Life',
            );
          },
        ),
      ],
    );
  }
}

class _TranslationTile extends StatelessWidget {
  final VerseTranslation translation;
  const _TranslationTile({required this.translation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translation.text.replaceAll(RegExp(r'<[^>]*>'), ''),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            '— ${translation.resourceName}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}