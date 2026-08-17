import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/tasbih/cubit/tasbih_state.dart';
import 'package:muslim_app/tasbih/repository/tasbih_repository.dart';
import 'package:muslim_app/tasbih/services/feedback_service.dart';

import '../models/click_mode.dart';
import '../models/history_entry.dart';

class TasbihCubit extends Cubit<TasbihState> {

  TasbihCubit({
    TasbihRepository? repository,
    FeedbackService? feedbackService,
  })
      : _repo = repository ?? TasbihRepository(),
        _feedback = feedbackService ?? FeedbackService(),
        super(const TasbihState());

  final TasbihRepository _repo;
  final FeedbackService _feedback;

  Future<void> load() async {
    final snap = await _repo.load();
    emit(state.copyWith(
      isLoaded: true,
      dhikrIndex: snap.dhikrIndex,
      current: snap.current,
      rounds: snap.rounds,
      totalEver: snap.totalEver,
      target: snap.target,
      mode: snap.mode,
      history: snap.history,
    ));
  }

  Future<void> Increament() async {
    if (state.current >= state.target) return;
    final newCurrent = state.current + 1;
    emit(state.copyWith(
      current: newCurrent,
      totalEver: state.totalEver + 1,
      justCompleted: false,
    ));
    await _feedback.playTick(state.mode);

    if (newCurrent == state.target) {
      await _completeRound();
    }
    await _persistSession();
  }

  Future<void> _completeRound() async {
    emit(state.copyWith(rounds: state.rounds + 1, justCompleted: true));
    await _feedback.playRoundComplete(state.mode);
  }

  void selectDhikr(int index) {
    if (state.current > 0 || state.rounds > 0) {
      saveToHistory();

      emit(state.copyWith(dhikrIndex: index,
        current: 0,
        rounds: 0,
        justCompleted: false,
      ));
      _persistSession();
    }
  }

  void setTarget(int target) {
    if (target <= 0) return;
    emit(state.copyWith(
        target: target, current: 0, rounds: 0, justCompleted: false));
    _persistSession();
  }

  void setMode(ClickMode mode) {
    emit(state.copyWith(mode: mode));
    _persistSession();
  }

  void resetCurrent() {
    emit(state.copyWith(current: 0, justCompleted: false));
    _persistSession();
  }

  void resetFull() {
    emit(state.copyWith(current: 0, rounds: 0, justCompleted: false));
    _persistSession();
  }

  void saveToHistory() {
    if (state.rounds == 0) return;
    final entry = HistoryEntry(
      dhikr: state.activeDhikr,
      rounds: state.rounds,
      target: state.target,
      time: DateTime.now(),
    );
    final updated = [entry, ...state.history];

    emit(state.copyWith(
      history: updated.length > 20 ? updated.sublist(0, 20) : updated,
    ));
    _persistSession();
  }

  Future<void> clearHistory() async {

    emit(state.copyWith(history: []));
    await _repo.clearHistory();
  }

  Future<void> _persistSession() {
    return _repo.saveSession(
      totalEver: state.totalEver,
      dhikrIndex: state.dhikrIndex,
      target: state.target,
      rounds: state.rounds,
      current: state.current,
      mode: state.mode,
      history: state.history,
    );
  }

  Future<void> persistNow() => _persistSession();
  @override
  Future<void> close() {
    _feedback.dispose();
    return super.close();
  }

}