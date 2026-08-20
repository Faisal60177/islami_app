import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/verse.dart';

part 'audio_player_provider.g.dart';

enum QuranAudioStatus { idle, loading, playing, paused, error }

class QuranAudioState {
  final QuranAudioStatus status;
  final String? currentVerseKey;
  final Verse? currentVerse;
  final Duration position;
  final Duration duration;
  final double speed;
  final bool repeatOne;
  final String? errorMessage;

  const QuranAudioState({
    this.status = QuranAudioStatus.idle,
    this.currentVerseKey,
    this.currentVerse,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.repeatOne = false,
    this.errorMessage,
  });

  QuranAudioState copyWith({
    QuranAudioStatus? status,
    String? currentVerseKey,
    Verse? currentVerse,
    Duration? position,
    Duration? duration,
    double? speed,
    bool? repeatOne,
    String? errorMessage,
  }) {
    return QuranAudioState(
      status: status ?? this.status,
      currentVerseKey: currentVerseKey ?? this.currentVerseKey,
      currentVerse: currentVerse ?? this.currentVerse,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      repeatOne: repeatOne ?? this.repeatOne,
      errorMessage: errorMessage,
    );
  }
}

@Riverpod(keepAlive: true)
class QuranAudioPlayerNotifier extends _$QuranAudioPlayerNotifier {
  late final AudioPlayer _player;

  List<Verse> _playableQueue = [];
  ConcatenatingAudioSource? _playlist;

  @override
  QuranAudioState build() {
    _player = AudioPlayer();

    _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _player.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playableQueue.length) {
        state = state.copyWith(currentVerseKey: _playableQueue[index].verseKey,
        currentVerse: _playableQueue[index]);
      }
    });

    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        state = const QuranAudioState();
      } else if (playerState.playing) {
        state = state.copyWith(status: QuranAudioStatus.playing);
      } else if (playerState.processingState == ProcessingState.buffering ||
          playerState.processingState == ProcessingState.loading) {
        state = state.copyWith(status: QuranAudioStatus.loading);
      } else if (playerState.processingState == ProcessingState.ready) {
        state = state.copyWith(status: QuranAudioStatus.paused);
      }
    });

    ref.onDispose(() {
      _player.dispose();
    });

    return const QuranAudioState();
  }

  bool _isSameQueue(List<Verse> queue) {
    if (queue.length != _playableQueue.length) return false;
    if (queue.isEmpty) return true;
    return queue.first.verseKey == _playableQueue.first.verseKey &&
        queue.last.verseKey == _playableQueue.last.verseKey;
  }

  Future<void> playVerse(Verse verse, {required List<Verse> queue}) async {
    final playable = queue.where((v) => v.audio != null).toList();
    final targetIndex = playable.indexWhere((v) => v.verseKey == verse.verseKey);

    if (targetIndex == -1) {
      state = state.copyWith(
        status: QuranAudioStatus.error,
        errorMessage: 'No Audio for this Ayah',
      );
      return;
    }

    try {
      state = state.copyWith(
        status: QuranAudioStatus.loading,
        currentVerseKey: verse.verseKey,
      );

      if (!_isSameQueue(playable)) {
        _playableQueue = playable;
        final sources = playable
            .map((v) => AudioSource.uri(Uri.parse(v.audio!.url)))
            .toList();
        _playlist = ConcatenatingAudioSource(children: sources);
        await _player.setAudioSource(_playlist!, initialIndex: targetIndex);
      } else {
        await _player.seek(Duration.zero, index: targetIndex);
      }

      await _player.play();
    } catch (e) {
      state = state.copyWith(
        status: QuranAudioStatus.error,
        errorMessage: 'Check your Internet',
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

  Future<void> next() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  Future<void> previous() async {
    if (_player.hasPrevious) await _player.seekToPrevious();
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  Future<void> toggleRepeatOne() async {
    final newValue = !state.repeatOne;
    await _player.setLoopMode(newValue ? LoopMode.one : LoopMode.off);
    state = state.copyWith(repeatOne: newValue);
  }
}