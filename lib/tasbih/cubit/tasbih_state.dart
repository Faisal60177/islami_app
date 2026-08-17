import 'package:equatable/equatable.dart';
import '../models/click_mode.dart';
import '../models/history_entry.dart';
import '../pages/tasbih_page.dart';

class TasbihState  extends Equatable{
  final bool isLoaded;
  final List<String> dhikrOptions;
  final int dhikrIndex;
  final int current;
  final int rounds;
  final int totalEver;
  final int target;
  final List<int> presets;
  final ClickMode mode;
  final List<HistoryEntry> history;
  final bool justCompleted;

  const TasbihState({
    this.isLoaded= false,
    this.dhikrOptions = const [
      'سُبْحَانَ ٱللَّهِ',
      'ٱلْحَمْدُ لِلَّهِ',
      'ٱللَّهُ أَكْبَرُ',
      'أَسْتَغْفِرُ ٱللَّهَ',
      'لَا إِلَٰهَ إِلَّا ٱللَّهُ',
      'ٱللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
      'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّهِ',
      'حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ',
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      'سُبْحَانَ ٱللَّهِ وَبِحَمْدِهِ',
      'سُبْحَانَ ٱللَّهِ ٱلْعَظِيمِ',
      'سُبْحَانَ ٱللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ ٱللَّهِ ٱلْعَظِيمِ',
      'لَا إِلَٰهَ إِلَّا ٱللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ ٱلْمُلْكُ وَلَهُ ٱلْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
      'أَسْتَغْفِرُ ٱللَّهَ ٱلَّذِي لَا إِلَٰهَ إِلَّا هُوَ ٱلْحَيُّ ٱلْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
      'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ ٱلظَّالِمِينَ',
      'رَبَّنَا آتِنَا فِي ٱلدُّنْيَا حَسَنَةً وَفِي ٱلْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ ٱلنَّارِ',
      'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ'
    ],
    this.dhikrIndex = 0,
    this.current = 0,
    this.rounds = 0,
    this.totalEver = 0,
    this.target = 100,
    this.presets = const [33, 100, 500, 1000],
    this.mode = ClickMode.sound,
    this.history = const [],
    this.justCompleted = false,
});

  String get activeDhikr => dhikrOptions[dhikrIndex];
  double get progress => target == 0 ? 0 : current / target;
  int get sessionTotal => rounds * target + current;

  TasbihState copyWith({
    bool? isLoaded,
    int? dhikrIndex,
    int? current,
    int? rounds,
    int? totalEver,
    int? target,
    ClickMode? mode,
    List<HistoryEntry>? history,
    bool? justCompleted,
}) {
    return TasbihState(
      isLoaded: isLoaded ?? this.isLoaded,
      dhikrIndex: dhikrIndex ?? this.dhikrIndex,
      current: current ?? this.current,
      rounds: rounds ?? this.rounds,
      totalEver: totalEver ?? this.totalEver,
      target: target ?? this.target,
      presets: presets,
      mode: mode ?? this.mode,
      history: history ?? this.history,
      justCompleted: justCompleted ?? this.justCompleted,
    );
  }

  @override
  List<Object?> get props => [
    isLoaded,
    dhikrIndex,
    current,
    rounds,
    totalEver,
    target,
    mode,
    history,
    justCompleted,
  ];
}