import 'package:dio/dio.dart';
import '../../core/network/quran_api_client.dart';
import '../models/chapter_model.dart';
import '../models/juz_model.dart';
import '../models/verse_model.dart';
import '../models/translation_resource_model.dart';
import '../models/reciter_model.dart';

class QuranRemoteDataSource {
  final QuranApiClient _apiClient;
  QuranRemoteDataSource({ required QuranApiClient apiClient})
  : _apiClient = apiClient;

  Future<List<JuzModel>> getJuzs() async {
    try {
      final response = await _apiClient.dio.get('/juzs');
      final list = response.data['juzs'] as List<dynamic>;

      final juzs = list
          .map((json) => JuzModel.fromJson(json as Map<String, dynamic>))
          .toList();
      final seen = <int>{};
      final uniqueJuzs = juzs.where((j) => seen.add(j.juzNumber)).toList();

      return uniqueJuzs;
    } on DioException catch (e) {
      throw _mapDioError(e, context: 'fetching juzs');
    }
  }


  Future<List<ChapterModel>> getChapters() async {
    try {
      final response = await _apiClient.dio.get('/chapters');
      final chapterJson = response.data['chapters'] as List<dynamic>;
      return chapterJson.map((json) => ChapterModel.fromJson(json as Map<String,dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapDioError(e, context: 'fetching chapters');
    }
  }

  Future<List<VerseModel>> getVersesByChapter({
    required int chapterNumber,
    List<int> translationIds = const [],
    int? reciterId,
    int page =1,
    int perPage = 50,
}) async {
    try{
      final queryParams = <String, dynamic>{
        'per_page': perPage > 50 ? 50 : perPage,
        'page': page,
        'fields' : 'text_uthmani,chapter_id',
        'words': true,
        'word_fields': 'text_uthmani,location,char_type_name,position',
        'translation_fields': 'resource_name',
      };
      if(translationIds.isNotEmpty){
        queryParams['translations'] = translationIds.join(',');
      }
      if(reciterId != null){
        queryParams['audio'] = reciterId;
      }

      final response = await _apiClient.dio.get(
        '/verses/by_chapter/$chapterNumber',
        queryParameters:  queryParams,
      );

      final versesJson = response.data['verses'] as List<dynamic>;
      return versesJson
          .map((json) => VerseModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e){
      throw _mapDioError(e, context: 'fetching verses for chapter $chapterNumber');
    }
  }

  Future<List<VerseModel>> getVersesByJuz({
    required int juzNumber,
    List<int> translationIds = const [],
    int? reciterId,
    int page =1,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'per_page': perPage > 50 ? 50 : perPage,
        'page': page,
        'fields': 'text_uthmani,chapter_id',
        'words': true,
        'word_fields': 'text_uthmani,location,char_type_name,position',
        'translation_fields': 'resource_name',
      };
      if (translationIds.isNotEmpty) {
        queryParams['translations'] = translationIds.join(',');
      }
      if (reciterId != null) {
        queryParams['audio'] = reciterId;
      }

      final response = await _apiClient.dio.get(
        '/verses/by_juz/$juzNumber',
        queryParameters: queryParams,
      );

      final versesJson = response.data['verses'] as List<dynamic>;
      return versesJson
          .map((json) => VerseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e, context: 'fetching verses for juz $juzNumber');
    }
  }

  Future<List<TranslationResourceModel>> getAvailableTranslations() async {
    try {
      final response = await _apiClient.dio.get('/resources/translations');
      final list = response.data['translations'] as List<dynamic>;
      return list
          .map((json) =>
          TranslationResourceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e, context: 'fetching translation resources');
    }
  }

  Future<List<ReciterModel>> getAvailableReciters() async {
    try {
      final response = await _apiClient.dio.get('/resources/recitations');
      final list = response.data['recitations'] as List<dynamic>;
      return list
          .map((json) => ReciterModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e, context: 'fetching reciters');
    }
  }



  Exception _mapDioError(DioException e, {required String context}) {
    print('=== QURAN API ERROR ($context) ===');

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return QuranNetworkException(
        'Internet connection slow। ($context)',
      );
    }
    if (e.response?.statusCode == 429) {
      return QuranRateLimitException(
        'request send, try again',
      );
    }
    return QuranNetworkException('$context failed: ${e.message}');
  }

}


class QuranNetworkException implements Exception {
  final String message;
  QuranNetworkException(this.message);
  @override
  String toString() => message;
}

class QuranRateLimitException implements Exception {
  final String message;
  QuranRateLimitException(this.message);
  @override
  String toString() => message;
}
