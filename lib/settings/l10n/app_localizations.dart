import 'package:flutter/material.dart';

// ─── Supported Languages ──────────────────────────────────────────────────────
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRtl;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.isRtl = false,
  });
}

const List<AppLanguage> supportedLanguages = [
  AppLanguage(code: 'en', name: 'English',  nativeName: 'English',    flag: '🇬🇧'),
  AppLanguage(code: 'ar', name: 'Arabic',   nativeName: 'العربية',    flag: '🇸🇦', isRtl: true),
  AppLanguage(code: 'bn', name: 'Bengali',  nativeName: 'বাংলা',      flag: '🇧🇩'),
  AppLanguage(code: 'ur', name: 'Urdu',     nativeName: 'اردو',       flag: '🇵🇰', isRtl: true),
  AppLanguage(code: 'tr', name: 'Turkish',  nativeName: 'Türkçe',     flag: '🇹🇷'),
  AppLanguage(code: 'id', name: 'Indonesian',nativeName:'Bahasa Indonesia', flag: '🇮🇩'),
  AppLanguage(code: 'ms', name: 'Malay',    nativeName: 'Bahasa Melayu', flag: '🇲🇾'),
  AppLanguage(code: 'fr', name: 'French',   nativeName: 'Français',   flag: '🇫🇷'),
  AppLanguage(code: 'de', name: 'German',   nativeName: 'Deutsch',    flag: '🇩🇪'),
  AppLanguage(code: 'ru', name: 'Russian',  nativeName: 'Русский',    flag: '🇷🇺'),
];

// ─── Translation Maps ─────────────────────────────────────────────────────────
const Map<String, Map<String, String>> _translations = {
  'en': {
    'fajr': 'Fajr',        'dhuhr': 'Dhuhr',       'asr': 'Asr',
    'maghrib': 'Maghrib',  'isha': 'Isha',          'sunrise': 'Sunrise',
    'sunset': 'Sunset',    'noon': 'Noon',          'tahajjud': 'Tahajjud',
    'ishraq': 'Ishraq',    'chasht': 'Chasht',      'zawal': 'Zawal',
    'awabin': 'Awabin',    'iftar': 'Iftar',        'sahri': 'Sahri End',
    'today': 'Today',      'tools': 'Tools',        'quran': 'Quran',
    'duas': 'Duas',        'menu': 'Menu',          'settings': 'Settings',
    'profile': 'Profile',  'logout': 'Sign Out',    'prayer_times': 'Prayer Times',
    'salat_prayers': 'Salat Prayers',
    'prohibited_times': 'Prohibited Times',
    'sawm_times': 'Sawm Times',
    'nafal_prayers': 'Nafal Prayers',
    'active': 'Active',    'now': 'Now',            'prohibited': 'Prohibited',
    'locating': 'Locating...',
    'permission_denied': 'Permission denied',
    'loading': 'Loading...',
  },
  'ar': {
    'fajr': 'الفجر',       'dhuhr': 'الظهر',       'asr': 'العصر',
    'maghrib': 'المغرب',   'isha': 'العشاء',        'sunrise': 'الشروق',
    'sunset': 'الغروب',    'noon': 'الزوال',        'tahajjud': 'التهجد',
    'ishraq': 'الإشراق',   'chasht': 'الضحى',       'zawal': 'الزوال',
    'awabin': 'الأوابين',  'iftar': 'الإفطار',      'sahri': 'نهاية السحور',
    'today': 'اليوم',      'tools': 'أدوات',        'quran': 'القرآن',
    'duas': 'الأدعية',     'menu': 'القائمة',       'settings': 'الإعدادات',
    'profile': 'الملف',    'logout': 'تسجيل الخروج','prayer_times': 'أوقات الصلاة',
    'salat_prayers': 'الصلوات الفريضة',
    'prohibited_times': 'أوقات النهي',
    'sawm_times': 'أوقات الصيام',
    'nafal_prayers': 'صلوات النافلة',
    'active': 'نشط',       'now': 'الآن',           'prohibited': 'محظور',
    'locating': 'جارٍ التحديد...',
    'permission_denied': 'تم رفض الإذن',
    'loading': 'جارٍ التحميل...',
  },
  'bn': {
    'fajr': 'ফজর',         'dhuhr': 'জোহর',        'asr': 'আসর',
    'maghrib': 'মাগরিব',   'isha': 'এশা',           'sunrise': 'সূর্যোদয়',
    'sunset': 'সূর্যাস্ত',  'noon': 'দুপুর',         'tahajjud': 'তাহাজ্জুদ',
    'ishraq': 'ইশরাক',     'chasht': 'চাশত',        'zawal': 'যাওয়াল',
    'awabin': 'আওয়াবিন',   'iftar': 'ইফতার',        'sahri': 'সেহরি শেষ',
    'today': 'আজ',          'tools': 'টুলস',         'quran': 'কুরআন',
    'duas': 'দোয়া',         'menu': 'মেনু',          'settings': 'সেটিংস',
    'profile': 'প্রোফাইল', 'logout': 'সাইন আউট',   'prayer_times': 'নামাজের সময়',
    'salat_prayers': 'ফরজ নামাজ',
    'prohibited_times': 'নিষিদ্ধ সময়',
    'sawm_times': 'রোজার সময়',
    'nafal_prayers': 'নফল নামাজ',
    'active': 'সক্রিয়',   'now': 'এখন',            'prohibited': 'নিষিদ্ধ',
    'locating': 'অবস্থান খোঁজা হচ্ছে...',
    'permission_denied': 'অনুমতি অস্বীকৃত',
    'loading': 'লোড হচ্ছে...',
  },
  'ur': {
    'fajr': 'فجر',         'dhuhr': 'ظہر',          'asr': 'عصر',
    'maghrib': 'مغرب',     'isha': 'عشاء',           'sunrise': 'طلوع آفتاب',
    'sunset': 'غروب آفتاب','noon': 'زوال',           'tahajjud': 'تہجد',
    'ishraq': 'اشراق',     'chasht': 'چاشت',         'zawal': 'زوال',
    'awabin': 'اوابین',    'iftar': 'افطار',         'sahri': 'سحری ختم',
    'today': 'آج',         'tools': 'ٹولز',          'quran': 'قرآن',
    'duas': 'دعائیں',      'menu': 'مینو',           'settings': 'ترتیبات',
    'profile': 'پروفائل',  'logout': 'سائن آوٹ',    'prayer_times': 'نماز کے اوقات',
    'salat_prayers': 'فرض نمازیں',
    'prohibited_times': 'ممنوع اوقات',
    'sawm_times': 'روزے کے اوقات',
    'nafal_prayers': 'نفل نمازیں',
    'active': 'فعال',      'now': 'ابھی',            'prohibited': 'ممنوع',
    'locating': 'مقام تلاش ہو رہا ہے...',
    'permission_denied': 'اجازت سے انکار',
    'loading': 'لوڈ ہو رہا ہے...',
  },
  'tr': {
    'fajr': 'Sabah',       'dhuhr': 'Öğle',         'asr': 'İkindi',
    'maghrib': 'Akşam',    'isha': 'Yatsı',          'sunrise': 'Güneş Doğuşu',
    'sunset': 'Güneş Batışı','noon': 'Öğle Vakti',  'tahajjud': 'Teheccüd',
    'ishraq': 'İşrak',     'chasht': 'Kuşluk',       'zawal': 'Zeval',
    'awabin': 'Evvabin',   'iftar': 'İftar',         'sahri': 'Sahur Sonu',
    'today': 'Bugün',      'tools': 'Araçlar',       'quran': 'Kuran',
    'duas': 'Dualar',      'menu': 'Menü',           'settings': 'Ayarlar',
    'profile': 'Profil',   'logout': 'Çıkış',        'prayer_times': 'Namaz Vakitleri',
    'salat_prayers': 'Farz Namazlar',
    'prohibited_times': 'Yasak Vakitler',
    'sawm_times': 'Oruç Vakitleri',
    'nafal_prayers': 'Nafile Namazlar',
    'active': 'Aktif',     'now': 'Şimdi',           'prohibited': 'Yasak',
    'locating': 'Konum bulunuyor...',
    'permission_denied': 'İzin reddedildi',
    'loading': 'Yükleniyor...',
  },
  'id': {
    'fajr': 'Subuh',       'dhuhr': 'Zuhur',        'asr': 'Ashar',
    'maghrib': 'Magrib',   'isha': 'Isya',           'sunrise': 'Matahari Terbit',
    'sunset': 'Matahari Terbenam','noon': 'Tengah Hari','tahajjud': 'Tahajud',
    'ishraq': 'Isyrak',    'chasht': 'Dhuha',        'zawal': 'Zawal',
    'awabin': 'Awwabin',   'iftar': 'Buka Puasa',    'sahri': 'Akhir Sahur',
    'today': 'Hari Ini',   'tools': 'Alat',          'quran': 'Al-Quran',
    'duas': 'Doa',         'menu': 'Menu',           'settings': 'Pengaturan',
    'profile': 'Profil',   'logout': 'Keluar',       'prayer_times': 'Waktu Shalat',
    'salat_prayers': 'Shalat Wajib',
    'prohibited_times': 'Waktu Terlarang',
    'sawm_times': 'Waktu Puasa',
    'nafal_prayers': 'Shalat Sunnah',
    'active': 'Aktif',     'now': 'Sekarang',        'prohibited': 'Terlarang',
    'locating': 'Mencari lokasi...',
    'permission_denied': 'Izin ditolak',
    'loading': 'Memuat...',
  },
  'ms': {
    'fajr': 'Subuh',       'dhuhr': 'Zohor',        'asr': 'Asar',
    'maghrib': 'Maghrib',  'isha': 'Isyak',          'sunrise': 'Matahari Terbit',
    'sunset': 'Matahari Terbenam','noon': 'Tengah Hari','tahajjud': 'Tahajud',
    'ishraq': 'Isyraq',    'chasht': 'Dhuha',        'zawal': 'Zawal',
    'awabin': 'Awwabin',   'iftar': 'Berbuka',       'sahri': 'Akhir Sahur',
    'today': 'Hari Ini',   'tools': 'Alat',          'quran': 'Al-Quran',
    'duas': 'Doa',         'menu': 'Menu',           'settings': 'Tetapan',
    'profile': 'Profil',   'logout': 'Log Keluar',   'prayer_times': 'Waktu Solat',
    'salat_prayers': 'Solat Fardhu',
    'prohibited_times': 'Waktu Larangan',
    'sawm_times': 'Waktu Puasa',
    'nafal_prayers': 'Solat Sunat',
    'active': 'Aktif',     'now': 'Sekarang',        'prohibited': 'Dilarang',
    'locating': 'Mencari lokasi...',
    'permission_denied': 'Kebenaran ditolak',
    'loading': 'Memuatkan...',
  },
  'fr': {
    'fajr': 'Fajr',        'dhuhr': 'Dhuhr',        'asr': 'Asr',
    'maghrib': 'Maghrib',  'isha': 'Isha',           'sunrise': 'Lever du soleil',
    'sunset': 'Coucher du soleil','noon': 'Midi',    'tahajjud': 'Tahajjud',
    'ishraq': 'Ishraq',    'chasht': 'Dhuha',        'zawal': 'Zawal',
    'awabin': 'Awabin',    'iftar': 'Iftar',         'sahri': 'Fin du Sahri',
    'today': "Aujourd'hui",'tools': 'Outils',        'quran': 'Coran',
    'duas': 'Douas',       'menu': 'Menu',           'settings': 'Paramètres',
    'profile': 'Profil',   'logout': 'Déconnexion',  'prayer_times': 'Heures de prière',
    'salat_prayers': 'Prières obligatoires',
    'prohibited_times': 'Heures interdites',
    'sawm_times': 'Heures de jeûne',
    'nafal_prayers': 'Prières surérogatoires',
    'active': 'Actif',     'now': 'Maintenant',      'prohibited': 'Interdit',
    'locating': 'Localisation...',
    'permission_denied': 'Permission refusée',
    'loading': 'Chargement...',
  },
  'de': {
    'fajr': 'Fajr',        'dhuhr': 'Dhuhr',        'asr': 'Asr',
    'maghrib': 'Maghrib',  'isha': 'Isha',           'sunrise': 'Sonnenaufgang',
    'sunset': 'Sonnenuntergang','noon': 'Mittagszeit','tahajjud': 'Tahajjud',
    'ishraq': 'Ishraq',    'chasht': 'Duha',         'zawal': 'Zawal',
    'awabin': 'Awabin',    'iftar': 'Iftar',         'sahri': 'Sahri-Ende',
    'today': 'Heute',      'tools': 'Werkzeuge',     'quran': 'Koran',
    'duas': 'Duas',        'menu': 'Menü',           'settings': 'Einstellungen',
    'profile': 'Profil',   'logout': 'Abmelden',     'prayer_times': 'Gebetszeiten',
    'salat_prayers': 'Pflichtgebete',
    'prohibited_times': 'Verbotene Zeiten',
    'sawm_times': 'Fastenzeiten',
    'nafal_prayers': 'Freiwillige Gebete',
    'active': 'Aktiv',     'now': 'Jetzt',           'prohibited': 'Verboten',
    'locating': 'Standort wird ermittelt...',
    'permission_denied': 'Berechtigung verweigert',
    'loading': 'Lädt...',
  },
  'ru': {
    'fajr': 'Фаджр',       'dhuhr': 'Зухр',         'asr': 'Аср',
    'maghrib': 'Магриб',   'isha': 'Иша',            'sunrise': 'Восход',
    'sunset': 'Закат',     'noon': 'Полдень',        'tahajjud': 'Тахаджуд',
    'ishraq': 'Ишрак',     'chasht': 'Духа',         'zawal': 'Заваль',
    'awabin': 'Аввабин',   'iftar': 'Ифтар',         'sahri': 'Конец сухура',
    'today': 'Сегодня',    'tools': 'Инструменты',   'quran': 'Коран',
    'duas': 'Дуа',         'menu': 'Меню',           'settings': 'Настройки',
    'profile': 'Профиль',  'logout': 'Выйти',        'prayer_times': 'Время молитв',
    'salat_prayers': 'Обязательные молитвы',
    'prohibited_times': 'Запрещённое время',
    'sawm_times': 'Время поста',
    'nafal_prayers': 'Дополнительные молитвы',
    'active': 'Активно',   'now': 'Сейчас',          'prohibited': 'Запрещено',
    'locating': 'Определение местоположения...',
    'permission_denied': 'В разрешении отказано',
    'loading': 'Загрузка...',
  },
};

// ─── AppLocalizations ─────────────────────────────────────────────────────────
class AppLocalizations {
  final String languageCode;
  const AppLocalizations(this.languageCode);

  String translate(String key) {
    return _translations[languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  String get fajr    => translate('fajr');
  String get dhuhr   => translate('dhuhr');
  String get asr     => translate('asr');
  String get maghrib => translate('maghrib');
  String get isha    => translate('isha');
  String get sunrise => translate('sunrise');
  String get sunset  => translate('sunset');
  String get noon    => translate('noon');
  String get tahajjud=> translate('tahajjud');
  String get ishraq  => translate('ishraq');
  String get chasht  => translate('chasht');
  String get zawal   => translate('zawal');
  String get awabin  => translate('awabin');
  String get iftar   => translate('iftar');
  String get sahri   => translate('sahri');
  String get today   => translate('today');
  String get tools   => translate('tools');
  String get quran   => translate('quran');
  String get duas    => translate('duas');
  String get menu    => translate('menu');
  String get settings=> translate('settings');
  String get profile => translate('profile');
  String get logout  => translate('logout');
  String get prayerTimes    => translate('prayer_times');
  String get salatPrayers   => translate('salat_prayers');
  String get prohibitedTimes=> translate('prohibited_times');
  String get sawmTimes      => translate('sawm_times');
  String get nafalPrayers   => translate('nafal_prayers');
  String get active  => translate('active');
  String get now     => translate('now');
  String get prohibited     => translate('prohibited');
  String get locating       => translate('locating');
  String get permissionDenied=> translate('permission_denied');
  String get loading => translate('loading');

  bool get isRtl =>
      supportedLanguages.firstWhere((l) => l.code == languageCode,
          orElse: () => supportedLanguages.first).isRtl;
}

// ─── Extension for easy access ────────────────────────────────────────────────
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations l10n(String languageCode) => AppLocalizations(languageCode);
}