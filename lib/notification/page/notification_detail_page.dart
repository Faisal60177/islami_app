import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../model/notification_model.dart';
import '../cubit/notification_cubit.dart';
import '../widgets/type_badge.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';

class NotificationDetailPage extends StatelessWidget {
  final NotificationModel notification;
  const NotificationDetailPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final px = sw * 0.050;
    final n  = notification;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        final theme = getThemeById(settings.themeMode);
        return Scaffold(
          backgroundColor: theme.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // ── Collapsing app bar (with optional image) ────────────────
              SliverAppBar(
                expandedHeight: n.imageUrl != null ? sh * 0.28 : 0,
                pinned: true,
                backgroundColor: theme.surface,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: Colors.black38, shape: BoxShape.circle),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: sw * 0.045),
                  ),
                ),
                actions: [
                  // Share button
                  IconButton(
                    icon: Icon(Icons.share_rounded,
                        color: theme.accent, size: sw * 0.055),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Share.share(
                        '${n.title}\n\n${n.body}'
                            '${n.source != null ? '\n\n— ${n.source}' : ''}',
                      );
                    },
                  ),
                  // Delete button
                  IconButton(
                    icon: Icon(Icons.delete_rounded,
                        color: Colors.red[300], size: sw * 0.055),
                    onPressed: () => _confirmDelete(context, sw, theme),
                  ),
                  SizedBox(width: sw * 0.012),
                ],
                flexibleSpace: n.imageUrl != null
                    ? FlexibleSpaceBar(
                  background: Image.network(
                    n.imageUrl!,
                    fit: BoxFit.cover,
                    color: Colors.black38,
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (_, __, ___) => Container(
                        color: theme.surface),
                  ),
                )
                    : null,
              ),

              // ── Main content ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(px),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Badge + timestamp row
                      Row(children: [
                        TypeBadge(type: n.type, large: true),
                        const Spacer(),
                        Icon(Icons.access_time_rounded,
                            color: theme.textLow.withOpacity(0.6), size: sw * 0.036),
                        SizedBox(width: sw * 0.012),
                        Text(timeago.format(n.createdAt),
                            style: TextStyle(
                                color: theme.textLow.withOpacity(0.6),
                                fontSize: sw * 0.030)),
                      ]),
                      SizedBox(height: sw * 0.042),

                      // Title
                      Text(n.title,
                          style: TextStyle(
                              color: theme.textHigh,
                              fontSize: sw * 0.058,
                              fontWeight: FontWeight.w700,
                              height: 1.3)),
                      SizedBox(height: sw * 0.028),

                      // Accent divider
                      Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            theme.accent.withOpacity(0.0),
                            theme.accent.withOpacity(0.55),
                            theme.accent.withOpacity(0.0),
                          ]),
                        ),
                      ),
                      SizedBox(height: sw * 0.038),

                      // Body text
                      Text(n.body,
                          style: TextStyle(
                              color: theme.textHigh.withOpacity(0.85),
                              fontSize: sw * 0.040,
                              height: 1.80)),

                      // Source box (for hadiths)
                      if (n.source != null) ...[
                        SizedBox(height: sw * 0.048),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(sw * 0.042),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius:
                            BorderRadius.circular(sw * 0.032),
                            border: Border.all(
                                color: theme.accent.withOpacity(0.18),
                                width: 0.8),
                          ),
                          child: Row(children: [
                            Icon(Icons.menu_book_rounded,
                                color: theme.accent.withOpacity(0.75),
                                size: sw * 0.050),
                            SizedBox(width: sw * 0.025),
                            Expanded(
                              child: Text(n.source!,
                                  style: TextStyle(
                                      color: theme.accent.withOpacity(0.85),
                                      fontSize: sw * 0.034,
                                      fontStyle: FontStyle.italic)),
                            ),
                          ]),
                        ),
                      ],

                      SizedBox(height: sw * 0.060),

                      // Mark read / unread toggle
                      _readToggle(context, sw, n, theme),

                      SizedBox(height: sw * 0.060),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _readToggle(
      BuildContext context, double sw, NotificationModel n, AppThemeOption theme) {
    final isRead = n.isRead;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          final cubit = context.read<NotificationCubit>();
          if (isRead) {
            cubit.markUnread(n.id);
          } else {
            cubit.markRead(n.id);
          }
          Navigator.pop(context);
        },
        icon: Icon(
          isRead
              ? Icons.mark_email_unread_rounded
              : Icons.mark_email_read_rounded,
          color: theme.accent,
          size: sw * 0.050,
        ),
        label: Text(
          isRead ? 'Mark as unread' : 'Mark as read',
          style: TextStyle(
              color: theme.accent,
              fontSize: sw * 0.038,
              fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: sw * 0.040),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(sw * 0.042)),
          side: BorderSide(
              color: theme.accent.withOpacity(0.38), width: 1.0),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, double sw, AppThemeOption theme) {
    final cubit = context.read<NotificationCubit>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sw * 0.050)),
        title: Text('Delete notification',
            style: TextStyle(
                color: theme.textHigh,
                fontSize: sw * 0.042,
                fontWeight: FontWeight.w700)),
        content: Text(
            'This will permanently remove this notification.',
            style: TextStyle(
                color: theme.textLow, fontSize: sw * 0.034)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style:
                  TextStyle(color: theme.accent, fontSize: sw * 0.035))),
          TextButton(
              onPressed: () {
                cubit.delete(notification.id);
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to list
              },
              child: Text('Delete',
                  style: TextStyle(
                      color: Colors.red[300],
                      fontSize: sw * 0.035,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}