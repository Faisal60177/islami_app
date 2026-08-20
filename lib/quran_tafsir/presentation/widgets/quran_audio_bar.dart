import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslim_app/quran_tafsir/presentation/widgets/quran_settings_sheet.dart';
import '../providers/audio_player_provider.dart';
class QuranAudioBar extends ConsumerWidget {
  const QuranAudioBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(quranAudioPlayerNotifierProvider);

    // কিছুই বাজছে না (idle) হলে বার-টাই দেখানো হয় না।
    if (audioState.status == QuranAudioStatus.idle ||
        audioState.currentVerse == null) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final isPlaying = audioState.status == QuranAudioStatus.playing;
    final isLoading = audioState.status == QuranAudioStatus.loading;
    final verse = audioState.currentVerse!;
    final translation =
    verse.translations.isNotEmpty ? verse.translations.first : null;

    return Material(
      elevation: 12,
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProgressRow(audioState: audioState),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          verse.verseKey,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        if (translation != null)
                          Text(
                            translation.text.replaceAll(RegExp(r'<[^>]*>'), ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded, size: 22),
                    onPressed: () => _showMoreSheet(context, ref, audioState),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () =>
                        ref.read(quranAudioPlayerNotifierProvider.notifier).previous(),
                  ),
                  isLoading
                      ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      size: 34,
                      color: colors.primary,
                    ),
                    onPressed: () {
                      final notifier =
                      ref.read(quranAudioPlayerNotifierProvider.notifier);
                      isPlaying ? notifier.pause() : notifier.resume();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () =>
                        ref.read(quranAudioPlayerNotifierProvider.notifier).next(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () =>
                        ref.read(quranAudioPlayerNotifierProvider.notifier).stop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreSheet(
      BuildContext context, WidgetRef ref, QuranAudioState audioState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download'),
              subtitle: const Text('Coming soon'),
              enabled: false,
            ),
            ListTile(
              leading: Icon(
                audioState.repeatOne ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              ),
              title: const Text('Repeat this Ayah'),
              trailing: Switch(
                value: audioState.repeatOne,
                onChanged: (_) {
                  ref.read(quranAudioPlayerNotifierProvider.notifier).toggleRepeatOne();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.speed_rounded),
              title: const Text('Speed'),
              trailing: Text('${audioState.speed}x'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showSpeedPicker(context, ref, audioState.speed);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Reciter'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: const Color(0xff00563B),
                  builder: (_) => const QuranSettingsSheet(),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSpeedPicker(BuildContext context, WidgetRef ref, double current) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: speeds
              .map((s) => RadioListTile<double>(
            value: s,
            groupValue: current,
            title: Text('${s}x'),
            onChanged: (v) {
              if (v == null) return;
              ref.read(quranAudioPlayerNotifierProvider.notifier).setSpeed(v);
              Navigator.of(sheetContext).pop();
            },
          ))
              .toList(),
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final QuranAudioState audioState;
  const _ProgressRow({required this.audioState});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final totalMs =
      audioState.duration.inMilliseconds == 0 ? 1 : audioState.duration.inMilliseconds;
      final valueMs =
      audioState.position.inMilliseconds.clamp(0, totalMs).toDouble();

      return Row(
        children: [
          Text(_fmt(audioState.position), style: const TextStyle(fontSize: 10)),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: valueMs,
                max: totalMs.toDouble(),
                onChanged: (v) => ref
                    .read(quranAudioPlayerNotifierProvider.notifier)
                    .seekTo(Duration(milliseconds: v.toInt())),
              ),
            ),
          ),
          Text(_fmt(audioState.duration), style: const TextStyle(fontSize: 10)),
        ],
      );
    });
  }
}