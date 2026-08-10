// audio_player_provider.dart
//
// PURPOSE: Ayah/Verse recitation audio play করার জন্য একটা centralized
// player state। আপাতত এটা সম্পূর্ণ ONLINE STREAMING — verse.audio.url
// সরাসরি just_audio কে দেওয়া হচ্ছে, কোনো download/local caching নেই।
//
// ভবিষ্যতে "download for offline" feature আসলে (premium/subscription),
// এই ফাইলেই একটা check যোগ হবে: "এই ayah এর audio local এ downloaded
// আছে কিনা, থাকলে local file path দাও, না থাকলে online URL দাও" —
// আর play() method এর ভিতরের logic ছাড়া বাকি কিছু বদলাতে হবে না,
// কারণ UI শুধু play()/pause()/seekToVerse() call করে, internal
// source কোথা থেকে আসছে সেটা জানে না।

import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/verse.dart';

part 'audio_player_provider.g.dart';

enum QuranAudioStatus { idle, loading, playing, paused, error }

class QuranAudioState {
  final QuranAudioStatus status;
  final String? currentVerseKey; // যেমন "1:1" — কোন আয়াত এখন বাজছে
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  const QuranAudioState({
    this.status = QuranAudioStatus.idle,
    this.currentVerseKey,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  QuranAudioState copyWith({
    QuranAudioStatus? status,
    String? currentVerseKey,
    Duration? position,
    Duration? duration,
    String? errorMessage,
  }) {
    return QuranAudioState(
      status: status ?? this.status,
      currentVerseKey: currentVerseKey ?? this.currentVerseKey,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage,
    );
  }
}

@Riverpod(keepAlive: true)
class QuranAudioPlayerNotifier extends _$QuranAudioPlayerNotifier {
  late final AudioPlayer _player;

  @override
  QuranAudioState build() {
    _player = AudioPlayer();

    // Player এর position/status বদলালে state sync রাখা হচ্ছে
    _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _player.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    _player.playerStateStream.listen((playerState) {
      if (playerState.playing) {
        state = state.copyWith(status: QuranAudioStatus.playing);
      } else if (playerState.processingState == ProcessingState.completed) {
        state = state.copyWith(status: QuranAudioStatus.idle);
      } else if (playerState.processingState == ProcessingState.ready) {
        state = state.copyWith(status: QuranAudioStatus.paused);
      }
    });

    // Provider dispose হওয়ার সময় player resource clean-up করা জরুরি,
    // নাহলে memory leak হবে।
    ref.onDispose(() {
      _player.dispose();
    });

    return const QuranAudioState();
  }

  /// একটা নির্দিষ্ট আয়াতের audio play করা।
  /// [verse] এর ভিতরে audio.url না থাকলে (null), কিছু হবে না —
  /// UI তে সেই ক্ষেত্রে play button disable রাখা উচিত।
  Future<void> playVerse(Verse verse) async {
    final audioUrl = verse.audio?.url;
    if (audioUrl == null) {
      state = state.copyWith(
        status: QuranAudioStatus.error,
        errorMessage: 'এই আয়াতের জন্য কোনো audio পাওয়া যায়নি।',
      );
      return;
    }

    try {
      state = state.copyWith(
        status: QuranAudioStatus.loading,
        currentVerseKey: verse.verseKey,
      );
      await _player.setUrl(audioUrl);
      await _player.play();
    } catch (e) {
      state = state.copyWith(
        status: QuranAudioStatus.error,
        errorMessage: 'Audio play করতে সমস্যা হয়েছে। Internet চেক করুন।',
      );
    }
  }

  Future<void> pause() async {
    await _player.pause();
    state = state.copyWith(status: QuranAudioStatus.paused);
  }

  Future<void> resume() async {
    await _player.play();
    state = state.copyWith(status: QuranAudioStatus.playing);
  }

  Future<void> stop() async {
    await _player.stop();
    state = const QuranAudioState();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }
}