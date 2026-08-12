// quran_auth_service.dart
//
// PURPOSE (উদ্দেশ্য):
// এই ফাইলের একটাই কাজ — Quran.Foundation এর OAuth2 token নেওয়া এবং
// সেটা memory তে cache করে রাখা, যাতে প্রতিটা API call এর আগে বারবার
// নতুন token request না করতে হয় (token ১ ঘণ্টা / ৩৬০০ সেকেন্ড valid থাকে)।
//
// এই ফাইলটা QuranApiClient (পরের ফাইল) ব্যবহার করবে প্রতিটা request এর আগে।

import 'dart:convert';
import 'package:dio/dio.dart';

class QuranAuthService {
  // Production credentials — env variable থেকে আনাই ভালো practice,
  // কিন্তু এখানে সরলতার জন্য constant হিসেবে দেখানো হলো।
  // ⚠️ প্রোডাকশনে এগুলো flutter_dotenv বা --dart-define দিয়ে inject করুন,
  // সরাসরি source code এ hardcode রাখবেন না (git এ commit হয়ে যাওয়ার ঝুঁকি)।
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

  // token আলাদা Dio instance দিয়ে fetch করা হচ্ছে, কারণ এই request এ
  // auth header interceptor লাগবে না (এটা নিজেই auth নেওয়ার জন্য call)।
  final Dio _authDio = Dio();

  // In-memory cache — App বন্ধ হয়ে গেলে এটা হারিয়ে যাবে, যা ঠিক আছে,
  // কারণ পরের বার app খুললে নতুন token নেওয়াই স্বাভাবিক।
  String? _cachedToken;
  DateTime? _expiryTime;

  /// সবসময় valid token রিটার্ন করে।
  /// যদি cache তে valid token থাকে, সেটাই দেয় (network call হয় না)।
  /// যদি না থাকে বা expire হয়ে গেছে, নতুন করে fetch করে।
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
      final expiresIn = data['expires_in'] as int; // সাধারণত 3599 সেকেন্ড

      _cachedToken = token;
      // Safety buffer হিসেবে ৬০ সেকেন্ড আগেই expired ধরে নিচ্ছি,
      // যাতে ঠিক শেষ মুহূর্তে কোনো request fail না করে।
      _expiryTime = DateTime.now().add(
        Duration(seconds: expiresIn - 60),
      );

      return token;
    } on DioException catch (e) {
      // ignore: avoid_print
      print('=== TOKEN FETCH ERROR ===');
      // ignore: avoid_print
      print('Type: ${e.type}');
      // ignore: avoid_print
      print('Message: ${e.message}');
      // ignore: avoid_print
      print('Error: ${e.error}');
      // ignore: avoid_print
      print('Status Code: ${e.response?.statusCode}');
      // ignore: avoid_print
      print('Response: ${e.response?.data}');
      // ignore: avoid_print
      print('=========================');
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

  /// শুধু Client ID লাগবে x-client-id header এ, তাই এটা expose করা হলো।
  String get clientId => _clientId;
}

class QuranAuthException implements Exception {
  final String message;
  QuranAuthException(this.message);

  @override
  String toString() => 'QuranAuthException: $message';
}