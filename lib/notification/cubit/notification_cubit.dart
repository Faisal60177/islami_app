import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/notification_model.dart';
import '../repository/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repo;
  StreamSubscription? _sub;

  NotificationCubit(this._repo) : super(NotificationLoading()) {
    _startListening();
  }

  // Subscribe to the real-time Firestore stream.
  // When admin sends a notification from the HTML panel,
  // this fires automatically and the UI updates instantly.
  void _startListening() {
    _sub = _repo.streamAll().listen(
          (list) {
        final prev = state;
        emit(NotificationLoaded(
          all: list,
          // Preserve whatever filter tab was active
          activeFilter: prev is NotificationLoaded ? prev.activeFilter : null,
        ));
      },
      onError: (e) => emit(NotificationError(e.toString())),
    );
  }

  // Called when user taps a filter tab (Hadith / Dua / Ad / Info / All)
  void setFilter(NotificationType? type) {
    final s = state;
    if (s is NotificationLoaded) {
      emit(s.copyWith(activeFilter: type, clearFilter: type == null));
    }
  }

  Future<void> markRead(String id)   async => _repo.markRead(id);
  Future<void> markUnread(String id) async => _repo.markUnread(id);
  Future<void> delete(String id)     async => _repo.delete(id);
  Future<void> markAllRead()         async => _repo.markAllRead();

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}