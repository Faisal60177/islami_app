import 'dart:convert';
import 'package:dio/dio.dart';

class QuranAuthService {
  static const String _clientId = String.fromEnvironment(
    'QURAN_CLIENT_ID',
    defaultValue: '3c57f109-9b4e-404b-965e-15248c733d1e',
  );
  static const String _clientSecret = String.fromEnvironment(
    'QURAN_CLIENT_SECRET',
    defaultValue: 'nNZxk5grgJCCSbjIljA_xkpS97',
  );
  static const String _tokenUrl =
      'https://oauth2.quran.foundation/oauth2/token';

  final Dio _authDio = Dio();

  String? _cachedToken;
  DateTime? _expiryTime;

  Future<String> getValidToken() async {
    final now = DateTime.now();

    final hasValidCachedToken = _cachedToken != null &&
        _expiryTime != null &&
        now.isBefore(_expiryTime!);

    if (hasValidCachedToken) {
      return _cachedToken!;
    }

    return _fetchNewToken();
  }

  Future<String> _fetchNewToken() async {
    try {
      final response = await _authDio.post(
        _tokenUrl,
        data: {
          'grant_type': 'client_credentials',
          'scope': 'content',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Authorization': _basicAuthHeader(),
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      final expiresIn = data['expires_in'] as int;

      _cachedToken = token;
      _expiryTime = DateTime.now().add(
        Duration(seconds: expiresIn - 60),
      );

      return token;
    } on DioException catch (e) {
      throw QuranAuthException(
        'Failed to fetch Quran API token: ${e.message}',
      );
    }
  }

  String _basicAuthHeader() {
    final credentials = '$_clientId:$_clientSecret';
    final encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  String get clientId => _clientId;
}

class QuranAuthException implements Exception {
  final String message;
  QuranAuthException(this.message);

  @override
  String toString() => 'QuranAuthException: $message';
}