import 'package:cloud_firestore/cloud_firestore.dart';

// Every notification has one of these types.
// The admin picks the type when sending from the HTML panel.
enum NotificationType { hadith, dua, ad, info }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;   // optional banner image URL
  final String? source;     // e.g. "Sahih Bukhari 5027"
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.source,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  // Build a NotificationModel from a Firestore document snapshot
  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id:        doc.id,
      title:     d['title']    ?? '',
      body:      d['body']     ?? '',
      imageUrl:  d['imageUrl'],
      source:    d['source'],
      type:      _typeFrom(d['type']),
      isRead:    d['isRead']   ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Used when toggling isRead locally before Firestore confirms
  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id, title: title, body: body,
    imageUrl: imageUrl, source: source, type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  static NotificationType _typeFrom(String? v) {
    switch (v) {
      case 'hadith': return NotificationType.hadith;
      case 'dua':    return NotificationType.dua;
      case 'ad':     return NotificationType.ad;
      default:       return NotificationType.info;
    }
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.hadith: return 'Hadith';
      case NotificationType.dua:    return 'Dua';
      case NotificationType.ad:     return 'Ad';
      case NotificationType.info:   return 'Info';
    }
  }
}