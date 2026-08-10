import '../entities/chapter.dart';
import '../entities/juz.dart';
import '../entities/verse.dart';
import '../entities/translation_resource.dart';
import '../entities/reciter.dart';

abstract class QuranRepository {
  Future<List<Chapter>> getChapters();

  Future<List<Verse>> getVersesByChapter({
    required int chapterNumber,
    List<int> translationIds = const [],
    int? reciterId,
});

  Future<List<TranslationResource>> getAvailableTranslations();
  Future<List<Reciter>> getAvailableReciters();

  Future<List<Juz>> getJuzs();

}