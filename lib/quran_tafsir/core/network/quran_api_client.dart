import 'package:dio/dio.dart';
import 'quran_auth_service.dart';

class QuranApiClient {
  static const String baseurl = 'https://apis.quran.foundation/content/api/v4';
  final Dio dio;
  final QuranAuthService _authService;

  QuranApiClient({QuranAuthService? authService})
  :_authService = authService ?? QuranAuthService(),
  dio = Dio(
    BaseOptions(
      baseUrl: baseurl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    )
  ){
    _setupInterceptors();
  }

  void _setupInterceptors(){
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getValidToken();
          options.headers['x-auth-token'] = token;
          options.headers['x-client-id'] = _authService.clientId;
          handler.next(options);
        },
        onError: (DioException error, handler){
          handler.next(error);
        },
      ),
    );
  }

}