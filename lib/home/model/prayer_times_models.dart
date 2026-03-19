class PrayerTimesModel {
  final DateTime fajrStart;
  final DateTime fajrEnd;

  final DateTime sunRiseStart;
  final DateTime sunRiseEnd;
  final DateTime noonStart;
  final DateTime noonEnd;
  final DateTime sunSetStart;
  final DateTime sunSetEnd;

  final DateTime dhuhrStart;
  final DateTime dhuhrEnd;

  final DateTime asrStart;
  final DateTime asrEnd;

  final DateTime maghribStart;
  final DateTime maghribEnd;

  final DateTime ishaStart;
  final DateTime ishaEnd;

  final DateTime ishraqStart;
  final DateTime ishraqEnd;
  final DateTime chashtStart;
  final DateTime chashtEnd;
  final DateTime tahajjudStart;
  final DateTime tahajjudEnd;
  final DateTime awabinStart;
  final DateTime awabinEnd;
  final DateTime zawalStart;

  final DateTime iftarTime;
  final DateTime sahriEnd;



  const PrayerTimesModel({
    required this.fajrStart,
    required this.fajrEnd,
    required this.sunRiseStart,
    required this.sunRiseEnd,
    required this.noonStart,
    required this.noonEnd,
    required this.sunSetStart,
    required this.sunSetEnd,
    required this.dhuhrStart,
    required this.dhuhrEnd,
    required this.asrStart,
    required this.asrEnd,
    required this.maghribStart,
    required this.maghribEnd,
    required this.ishaStart,
    required this.ishaEnd,
    required this.ishraqStart,
    required this.ishraqEnd,
    required this.chashtStart,
    required this.chashtEnd,
    required this.tahajjudStart,
    required this.tahajjudEnd,
    required this.iftarTime,
    required this.sahriEnd,
    required this.awabinStart,
    required this.awabinEnd,
    required this.zawalStart,
  });

  /// CopyWith method
  PrayerTimesModel copyWith({
    DateTime? fajrStart,
    DateTime? fajrEnd,
    DateTime? sunRiseStart,
    DateTime? sunRiseEnd,
    DateTime? noonStart,
    DateTime? noonEnd,
    DateTime? sunSetStart,
    DateTime? sunSetEnd,
    DateTime? dhuhrStart,
    DateTime? dhuhrEnd,
    DateTime? asrStart,
    DateTime? asrEnd,
    DateTime? maghribStart,
    DateTime? maghribEnd,
    DateTime? ishaStart,
    DateTime? ishaEnd,
    DateTime? ishraqStart,
    DateTime? ishraqEnd,
    DateTime? chashtStart,
    DateTime? chashtEnd,
    DateTime? tahajjudStart,
    DateTime? tahajjudEnd,
    DateTime? iftarTime,
    DateTime? sahriEnd,
    DateTime? awabinStart,
    DateTime? awabinEnd,
    DateTime? zawalStart,
  }) {
    return PrayerTimesModel(
      fajrStart: fajrStart ?? this.fajrStart,
      fajrEnd: fajrEnd ?? this.fajrEnd,
      sunRiseStart: sunRiseStart ?? this.sunRiseStart,
      sunRiseEnd: sunRiseEnd ?? this.sunRiseEnd,
      noonStart: noonStart ?? this.noonStart,
      noonEnd: noonEnd ?? this.noonEnd,
      sunSetStart: sunSetStart ?? this.sunSetStart,
      sunSetEnd: sunSetEnd ?? this.sunSetEnd,
      dhuhrStart: dhuhrStart ?? this.dhuhrStart,
      dhuhrEnd: dhuhrEnd ?? this.dhuhrEnd,
      asrStart: asrStart ?? this.asrStart,
      asrEnd: asrEnd ?? this.asrEnd,
      maghribStart: maghribStart ?? this.maghribStart,
      maghribEnd: maghribEnd ?? this.maghribEnd,
      ishaStart: ishaStart ?? this.ishaStart,
      ishaEnd: ishaEnd ?? this.ishaEnd,
      ishraqStart: ishraqStart ?? this.ishraqStart,
      ishraqEnd: ishraqEnd ?? this.ishraqEnd,
      chashtStart: chashtStart ?? this.chashtStart,
      chashtEnd: chashtEnd ?? this.chashtEnd,
      tahajjudStart: tahajjudStart ?? this.tahajjudStart,
      tahajjudEnd: tahajjudEnd ?? this.tahajjudEnd,
      iftarTime: iftarTime ?? this.iftarTime,
      sahriEnd: sahriEnd ?? this.sahriEnd,
      awabinStart: awabinStart ?? this.awabinStart,
      awabinEnd: awabinEnd ?? this.awabinEnd,
      zawalStart: zawalStart ?? this.zawalStart,
    );
  }

  /// JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'fajrStart': fajrStart.toIso8601String(),
      'fajrEnd': fajrEnd.toIso8601String(),
      'sunRiseStart': sunRiseStart.toIso8601String(),
      'sunRiseEnd': sunRiseEnd.toIso8601String(),
      'noonStart': noonStart.toIso8601String(),
      'noonEnd': noonEnd.toIso8601String(),
      'sunSetStart': sunSetStart.toIso8601String(),
      'sunSetEnd': sunSetEnd.toIso8601String(),
      'dhuhrStart': dhuhrStart.toIso8601String(),
      'dhuhrEnd': dhuhrEnd.toIso8601String(),
      'asrStart': asrStart.toIso8601String(),
      'asrEnd': asrEnd.toIso8601String(),
      'maghribStart': maghribStart.toIso8601String(),
      'maghribEnd': maghribEnd.toIso8601String(),
      'ishaStart': ishaStart.toIso8601String(),
      'ishaEnd': ishaEnd.toIso8601String(),
      'ishraqStart': ishraqStart.toIso8601String(),
      'ishraqEnd': ishraqEnd.toIso8601String(),
      'chashtStart': chashtStart.toIso8601String(),
      'chashtEnd': chashtEnd.toIso8601String(),
      'tahajjudStart': tahajjudStart.toIso8601String(),
      'tahajjudEnd': tahajjudEnd.toIso8601String(),
      'iftarTime': iftarTime.toIso8601String(),
      'sahriEnd': sahriEnd.toIso8601String(),
      'awabinStart': awabinStart.toIso8601String(),
      'awabinEnd': awabinEnd.toIso8601String(),
      'zawalStart': zawalStart.toIso8601String(),
    };
  }

  factory PrayerTimesModel.fromJson(Map<String, dynamic> json) {
    return PrayerTimesModel(
      fajrStart: DateTime.parse(json['fajrStart']),
      fajrEnd: DateTime.parse(json['fajrEnd']),
      sunRiseStart: DateTime.parse(json['sunRiseStart']),
      sunRiseEnd: DateTime.parse(json['sunRiseEnd']),
      noonStart: DateTime.parse(json['noonStart']),
      noonEnd: DateTime.parse(json['noonEnd']),
      sunSetStart: DateTime.parse(json['sunSetStart']),
      sunSetEnd: DateTime.parse(json['sunSetEnd']),
      dhuhrStart: DateTime.parse(json['dhuhrStart']),
      dhuhrEnd: DateTime.parse(json['dhuhrEnd']),
      asrStart: DateTime.parse(json['asrStart']),
      asrEnd: DateTime.parse(json['asrEnd']),
      maghribStart: DateTime.parse(json['maghribStart']),
      maghribEnd: DateTime.parse(json['maghribEnd']),
      ishaStart: DateTime.parse(json['ishaStart']),
      ishaEnd: DateTime.parse(json['ishaEnd']),
      ishraqStart: DateTime.parse(json['ishraqStart']),
      ishraqEnd: DateTime.parse(json['ishraqEnd']),
      chashtStart: DateTime.parse(json['chashtStart']),
      chashtEnd: DateTime.parse(json['chashtEnd']),
      tahajjudStart: DateTime.parse(json['tahajjudStart']),
      tahajjudEnd: DateTime.parse(json['tahajjudEnd']),
      iftarTime: DateTime.parse(json['iftarTime']),
      sahriEnd: DateTime.parse(json['sahriEnd']),
      awabinStart: DateTime.parse(json['awabinStart']),
      awabinEnd: DateTime.parse(json['awabinEnd']),
      zawalStart: DateTime.parse(json['zawalStart']),
    );
  }

}