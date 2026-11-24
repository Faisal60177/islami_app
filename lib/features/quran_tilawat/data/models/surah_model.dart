class SurahModel {
  final int number;
  final String nameAr;
  final String nameEn;
  final String nameTranslit;
  final int totalAyahs;
  final String revelationType;
  final int page;
  final int para;

  const SurahModel({
    required this.number,
    required this.nameAr,
    required this.nameEn,
    required this.nameTranslit,
    required this.totalAyahs,
    required this.revelationType,
    required this.page,
    required this.para,
  });

  factory SurahModel.fromJson(Map<String, dynamic> j) => SurahModel(
    number: j['number'],
    nameAr: j['nameAr'],
    nameEn: j['nameEn'],
    nameTranslit: j['nameTranslit'],
    totalAyahs: j['totalAyahs'],
    revelationType: j['revelationType'],
    page: j['page'],
    para: j['para'],
  );
}