import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/notification_model.dart';

class NotificationRepository {
  // Points to the "notifications" collection in Firestore.
  // This MUST match what the admin HTML panel writes to.
  final CollectionReference _col =
  FirebaseFirestore.instance.collection('notifications');

  // Real-time stream — newest first.
  // Every time admin adds/edits/deletes a document,
  // Flutter receives the update within ~1 second automatically.
  Stream<List<NotificationModel>> streamAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map(NotificationModel.fromDoc).toList());
  }

  Future<void> markRead(String id) async {
    await _col.doc(id).update({'isRead': true});
  }

  Future<void> markUnread(String id) async {
    await _col.doc(id).update({'isRead': false});
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  // Batch update — marks ALL unread docs as read in one transaction
  Future<void> markAllRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final snap  = await _col.where('isRead', isEqualTo: false).get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}