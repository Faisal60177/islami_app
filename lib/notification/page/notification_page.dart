import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../model/notification_model.dart';
import '../widgets/notification_tile.dart';
import '../widgets/empty_state.dart';
import 'notification_detail_page.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _View();
  }
}

class _View extends StatelessWidget {
  const _View();

  // Filter tab definitions: (type or null for All, display label)
  static const _tabs = <(NotificationType?, String)>[
    (null,                    'All'),
    (NotificationType.hadith, 'Hadith'),
    (NotificationType.dua,    'Dua'),
    (NotificationType.ad,     'Ad'),
    (NotificationType.info,   'Info'),
  ];

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final px = sw * 0.042;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        final theme = getThemeById(settings.themeMode);
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              _header(context, sw, px, theme),
              _filterRow(context, sw, theme),
              Expanded(child: _list(context, sw, px, theme)),
            ],
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _header(BuildContext context, double sw, double px, AppThemeOption theme) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
          top: top + sw * 0.030, left: px, right: px, bottom: sw * 0.028),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
            bottom: BorderSide(color: theme.accent.withOpacity(0.20))),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: theme.accent, size: sw * 0.045),
            ),
          ),
          SizedBox(width: sw * 0.028),

          // Title + unread count subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications',
                    style: TextStyle(
                        color: theme.textHigh,
                        fontSize: sw * 0.052,
                        fontWeight: FontWeight.w700)),
                BlocBuilder<NotificationCubit, NotificationState>(
                  builder: (_, state) {
                    final count = state is NotificationLoaded
                        ? state.unreadCount : 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Text('$count unread',
                        style: TextStyle(
                            color: theme.accent, fontSize: sw * 0.030));
                  },
                ),
              ],
            ),
          ),

          // Mark all read button (only shown when unread > 0)
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is! NotificationLoaded || state.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.read<NotificationCubit>().markAllRead();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.028, vertical: sw * 0.013),
                  decoration: BoxDecoration(
                    color: theme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(sw * 0.04),
                    border: Border.all(
                        color: theme.accent.withOpacity(0.28), width: 0.8),
                  ),
                  child: Text('Mark all read',
                      style: TextStyle(
                          color: theme.accent,
                          fontSize: sw * 0.028,
                          fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Horizontal filter tabs ───────────────────────────────────────────────────
  Widget _filterRow(BuildContext context, double sw, AppThemeOption theme) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final active = state is NotificationLoaded
            ? state.activeFilter : null;
        return Container(
          height: sw * 0.12,
          color: theme.surface,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.042, vertical: sw * 0.018),
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => SizedBox(width: sw * 0.018),
            itemBuilder: (_, i) {
              final (type, label) = _tabs[i];
              final isActive = type == active;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<NotificationCubit>().setFilter(type);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                  EdgeInsets.symmetric(horizontal: sw * 0.038),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.accent.withOpacity(0.16)
                        : theme.cardColor.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(sw * 0.040),
                    border: Border.all(
                      color: isActive
                          ? theme.accent.withOpacity(0.45)
                          : theme.textLow.withOpacity(0.15),
                      width: isActive ? 1.0 : 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(label,
                        style: TextStyle(
                          color: isActive ? theme.accent : theme.textLow,
                          fontSize: sw * 0.032,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                        )),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Notification list ────────────────────────────────────────────────────────
  Widget _list(BuildContext context, double sw, double px, AppThemeOption theme) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        if (state is NotificationLoading) {
          return Center(
              child: CircularProgressIndicator(color: theme.accent));
        }
        if (state is NotificationError) {
          return Center(
              child: Text(state.message,
                  style: TextStyle(
                      color: Colors.red[300], fontSize: sw * 0.038)));
        }
        if (state is NotificationLoaded) {
          final items = state.filtered;
          if (items.isEmpty) {
            return NotificationEmptyState(
                isFiltered: state.activeFilter != null);
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(px, sw * 0.038, px, sw * 0.06),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final n = items[i];
              final cubit = context.read<NotificationCubit>();
              return NotificationTile(
                notification: n,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: NotificationDetailPage(notification: n),
                    ),
                  ),
                ),
                onMarkRead:   () => cubit.markRead(n.id),
                onMarkUnread: () => cubit.markUnread(n.id),
                onDelete:     () => cubit.delete(n.id),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}