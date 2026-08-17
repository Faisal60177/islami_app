import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/click_mode.dart';
import '../models/history_entry.dart';

class TasbihSnapshot {
  final int totalEver;
  final int dhikrIndex;
  final int target;
  final int rounds;
  final int current;
  final ClickMode mode;
  final List<HistoryEntry> history;

  const TasbihSnapshot({
    required this.totalEver,
    required this.dhikrIndex,
    required this.target,
    required this.rounds,
    required this.current,
    required this.mode,
    required this.history,
  });
}

class TasbihRepository {
  static const _kTotal = 'tasbih_total';
  static const _kDhikrIndex = 'tasbih_dhikr_index';
  static const _kTarget = 'tasbih_target';
  static const _kRounds = 'tasbih_rounds';
  static const _kCurrent = 'tasbih_current';
  static const _kMode = 'tasbih_mode';
  static const _kHistory = 'tasbih_history';



  Future<TasbihSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final histJson = prefs.getStringList(_kHistory)?? [];

    return TasbihSnapshot(
        totalEver: prefs.getInt(_kTotal) ?? 0,
        dhikrIndex: prefs.getInt(_kDhikrIndex) ?? 0,
        target: prefs.getInt(_kTarget) ?? 100,
        rounds: prefs.getInt(_kRounds) ?? 0,
        current: prefs.getInt(_kCurrent) ?? 0,
        mode: ClickMode.values[prefs.getInt(_kMode) ?? 0],
        history: histJson.map((s) => HistoryEntry.fromJson(jsonDecode(s) as Map<String,dynamic>)).toList().reversed.take(10).toList());
  }

  Future<void> saveSession({
    required int totalEver,
    required int dhikrIndex,
    required int target,
    required int rounds,
    required int current,
    required ClickMode mode,
    required List<HistoryEntry> history,
}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTotal, totalEver);
    await prefs.setInt(_kDhikrIndex, dhikrIndex);
    await prefs.setInt(_kTarget, target);
    await prefs.setInt(_kRounds, rounds);
    await prefs.setInt(_kCurrent, current);
    await prefs.setInt(_kMode, mode.index);
    await prefs.setStringList(_kHistory, history.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistory);
  }
  }

