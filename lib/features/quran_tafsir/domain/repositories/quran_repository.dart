import 'package:muslim_app/features/quran_tafsir/domain/entities/chapter.dart';
import 'package:muslim_app/features/quran_tafsir/domain/entities/juz.dart';
import 'package:muslim_app/features/quran_tafsir/domain/entities/verse.dart';
import 'package:muslim_app/features/quran_tafsir/domain/entities/translation_resource.dart';
import 'package:muslim_app/features/quran_tafsir/domain/entities/reciter.dart';

abstract class QuranRepository {
  Future<List<Chapter>> getChapters();

  Future<List<Verse>> getVersesByChapter({
    required int chapterNumber,
    List<int> translationIds = const [],
    int? reciterId,
  });

  Future<List<Verse>> getVersesByJuz({
    required int juzNumber,
    List<int> translationIds = const [],
    int? reciterId,
  });

  Future<List<TranslationResource>> getAvailableTranslations();
  Future<List<Reciter>> getAvailableReciters();

  Future<List<Juz>> getJuzs();
}
