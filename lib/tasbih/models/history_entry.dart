class HistoryEntry {
  final String dhikr;
  final int rounds;
  final int target;
  final DateTime time;

  const HistoryEntry({
    required this.dhikr,
    required this.rounds,
    required this.target,
    required this.time,
  });

  int get total => rounds * target;

  Map<String, dynamic> toJson() =>{
    'dhikr': dhikr,
    'rounds': rounds,
    'target': target,
    'time': time.toIso8601String(),
  };


  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    dhikr: json['dhikr'],
    rounds: json['rounds'],
    target: json['target'],
    time: DateTime.parse(json['time']),
  );

  }

