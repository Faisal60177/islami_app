import '../model/notification_model.dart';

abstract class NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);
}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> all;        // full unfiltered list from Firestore
  final NotificationType? activeFilter;     // null means "show All"

  NotificationLoaded({required this.all, this.activeFilter});

  // The UI uses this — filtered by the active tab
  List<NotificationModel> get filtered {
    if (activeFilter == null) return all;
    return all.where((n) => n.type == activeFilter).toList();
  }

  // Drives the red badge on the bell icon in PrayerTimesPage
  int get unreadCount => all.where((n) => !n.isRead).length;

  NotificationLoaded copyWith({
    List<NotificationModel>? all,
    NotificationType? activeFilter,
    bool clearFilter = false,
  }) {
    return NotificationLoaded(
      all: all ?? this.all,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
    );
  }
}