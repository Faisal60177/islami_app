import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/verse.dart';
import 'quran_providers.dart';

part 'verse_reader_provider.g.dart';

class VerseReaderParams {
  final int chapterNumber;
  final List<int> translationIds;
  final int? reciterId;

  const VerseReaderParams({
    required this.chapterNumber,
    this.translationIds = const [],
    this.reciterId,
  });


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerseReaderParams &&
        other.chapterNumber == chapterNumber &&
        _listEquals(other.translationIds, translationIds) &&
        other.reciterId == reciterId;
  }

  @override
  int get hashCode =>
      Object.hash(chapterNumber, Object.hashAll(translationIds), reciterId);

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

@riverpod
class VerseReaderNotifier extends _$VerseReaderNotifier {
  @override
  Future<List<Verse>> build(VerseReaderParams params) async {
    final repository = ref.watch(quranRepositoryProvider);
    return repository.getVersesByChapter(
      chapterNumber: params.chapterNumber,
      translationIds: params.translationIds,
      reciterId: params.reciterId,
    );
  }
}