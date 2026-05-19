import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/notification_cubit.dart';
import '../model/notification_model.dart';
import 'notification_detail_page.dart';

/// Opened when user taps a push notification banner.
/// Fetches the Firestore doc by ID and renders NotificationDetailPage.
class NotificationDetailFromId extends StatelessWidget {
  final String docId;
  const NotificationDetailFromId({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .get(),
      builder: (context, snap) {
        // Loading
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF013220),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF82)),
            ),
          );
        }
        // Not found
        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            backgroundColor: const Color(0xFF013220),
            appBar: AppBar(backgroundColor: const Color(0xFF011A0D)),
            body: const Center(
              child: Text('Notification not found',
                  style: TextStyle(color: Colors.white54)),
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
  }
}