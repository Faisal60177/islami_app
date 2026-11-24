import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:muslim_app/features/notification/data/models/notification_model.dart';
import 'package:muslim_app/features/notification/presentation/pages/notification_detail_page.dart';
import 'package:muslim_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:muslim_app/features/settings/presentation/cubit/settings_state.dart';
import 'package:muslim_app/app/theme/app_themes.dart';

/// Opened when user taps a push notification banner.
/// Fetches the Firestore doc by ID and renders NotificationDetailPage.
class NotificationDetailFromId extends StatelessWidget {
  final String docId;
  const NotificationDetailFromId({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        final theme = getThemeById(settings.themeMode);
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('notifications')
              .doc(docId)
              .get(),
          builder: (context, snap) {
            // Loading
            if (snap.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: theme.background,
                body: Center(
                  child: CircularProgressIndicator(color: theme.accent),
                ),
              );
            }
            // Not found
            if (!snap.hasData || !snap.data!.exists) {
              return Scaffold(
                backgroundColor: theme.background,
                appBar: AppBar(backgroundColor: theme.surface),
                body: Center(
                  child: Text('Notification not found',
                      style: TextStyle(color: theme.textLow)),
                ),
              );
            }
            // Found — open detail page
            final notification = NotificationModel.fromDoc(snap.data!);
            return BlocProvider.value(
              value: context.read<NotificationCubit>(),
              child: NotificationDetailPage(notification: notification),
            );
          },
        );
      },
    );
  }
}