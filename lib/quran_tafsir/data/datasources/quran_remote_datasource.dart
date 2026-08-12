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
      return list
          .map((json) => JuzModel.fromJson(json as Map<String, dynamic>))
          .toList();
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
}) async {
    try{
      final queryParams = <String, dynamic>{
        'per_page': 50,
        'fields' : 'text_uthmani',
      };
      if(translationIds.isNotEmpty){
        queryParams['translations'] = translationIds.join(',');
      }
      if(reciterId != null){
        queryParams['audio'] = reciterId;
      }

      final response = await _apiClient.dio.get(
        '/verse/by_chapter/$chapterNumber',
        queryParameters:  queryParams,
      );

      final versesJson = response.data['verses'] as List<dynamic>;
      return versesJson
          .map((json) => VerseModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e){
      throw _mapDioError(e, context: 'fetching verses for chapter $chapterNumber');
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
    // ignore: avoid_print
    print('Type: ${e.type}');
    // ignore: avoid_print
    print('Message: ${e.message}');
    // ignore: avoid_print
    print('Status Code: ${e.response?.statusCode}');
    // ignore: avoid_print
    print('Response Data: ${e.response?.data}');

    print('Underlying Error: ${e.error}');
    print('Underlying Error Type: ${e.error.runtimeType}');
    // ignore: avoid_print
    print('===================================');

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return QuranNetworkException(
        'Internet connection মনে হচ্ছে নেই বা slow। ($context)',
      );
    }
    if (e.response?.statusCode == 429) {
      return QuranRateLimitException(
        'অনেক বেশি request পাঠানো হয়েছে, একটু পর আবার চেষ্টা করুন।',
      );
    }
    return QuranNetworkException('$context এ সমস্যা হয়েছে: ${e.message}');
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




