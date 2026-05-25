// lib/utils/language_utils.dart

class LanguageUtils {
  static bool isRtl(String languageCode) =>
      languageCode == 'ar' || languageCode == 'ur';

  static bool isArabicUser(String languageCode) =>
      languageCode == 'ar';
}