import '../../domain/entities/chapter.dart';
import '../../domain/entities/juz.dart';
import '../../domain/entities/verse.dart';
import '../../domain/entities/translation_resource.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_remote_datasource.dart';
// import '../datasources/quran_local_datasource.dart';


class QuranRepositoryImpl implements QuranRepository {
  final QuranRemoteDataSource _remoteDataSource;
  // final QuranLocalDataSource _localDataSource; // future

  QuranRepositoryImpl({
    required QuranRemoteDataSource remoteDataSource,
    // QuranLocalDataSource? localDataSource, //  future
  }) : _remoteDataSource = remoteDataSource;

  List<Chapter>? _cachedChapters;


  final Map<String, List<Verse>> _cachedVerses = {};

  List<TranslationResource>? _cachedTranslations;
  List<Reciter>? _cachedReciters;
  List<Juz>? _cachedJuzs;


  @override
  Future<List<Chapter>> getChapters() async {
    if (_cachedChapters != null) {
      return _cachedChapters!;
    }

    final chapters = await _remoteDataSource.getChapters();
    _cachedChapters = chapters;

    return chapters;
  }

  @override
  Future<List<Verse>> getVersesByChapter({
    required int chapterNumber,
    List<int> translationIds = const [],
    int? reciterId,
  }) async {
    final cacheKey = _buildVerseCacheKey(
      id: chapterNumber,
      prefix: 'ch',
      translationIds: translationIds,
      reciterId: reciterId,
    );

    if (_cachedVerses.containsKey(cacheKey)) {
      return _cachedVerses[cacheKey]!;
    }

    final verses = await _remoteDataSource.getVersesByChapter(
      chapterNumber: chapterNumber,
      translationIds: translationIds,
      reciterId: reciterId,
    );

    _cachedVerses[cacheKey] = verses;
    return verses;
  }

  @override
  Future<List<Verse>> getVersesByJuz({
    required int juzNumber,
    List<int> translationIds = const [],
    int? reciterId,
  }) async {
    final cacheKey = _buildVerseCacheKey(
      id: juzNumber,
      prefix: 'juz',
      translationIds: translationIds,
      reciterId: reciterId,
    );

    if (_cachedVerses.containsKey(cacheKey)) {
      return _cachedVerses[cacheKey]!;
    }

    final verses = await _remoteDataSource.getVersesByJuz(
      juzNumber: juzNumber,
      translationIds: translationIds,
      reciterId: reciterId,
    );

    _cachedVerses[cacheKey] = verses;
    return verses;
  }

  @override
  Future<List<TranslationResource>> getAvailableTranslations() async {
    if (_cachedTranslations != null) {
      return _cachedTranslations!;
    }
    final translations = await _remoteDataSource.getAvailableTranslations();
    _cachedTranslations = translations;
    return translations;
  }

  @override
  Future<List<Reciter>> getAvailableReciters() async {
    if (_cachedReciters != null) {
      return _cachedReciters!;
    }
    final reciters = await _remoteDataSource.getAvailableReciters();
    _cachedReciters = reciters;
    return reciters;
  }

  @override
  Future<List<Juz>> getJuzs() async {
    if (_cachedJuzs != null) {
      return _cachedJuzs!;
    }
    final juzs = await _remoteDataSource.getJuzs();
    _cachedJuzs = juzs;
    return juzs;
  }

  String _buildVerseCacheKey({
    required int id,
    required String prefix,
    required List<int> translationIds,
    int? reciterId,
  }) {
    final sortedTranslations = [...translationIds]..sort();
    return '$prefix$id-t${sortedTranslations.join("_")}-r${reciterId ?? "none"}';
  }
}
