import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String recipientId;
  final String senderId;
  final String senderName;
  final String type;
  final String title;
  final String message;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    this.senderName = 'BorrowNow',
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get userId => recipientId;

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    String? senderName,
    String? type,
    String? title,
    String? message,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notificationId': id,
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'title': title,
      'message': message,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return NotificationModel(
      id: docId ?? map['notificationId'] ?? map['id'] ?? '',
      recipientId: map['recipientId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'BorrowNow',
      type: map['type'] ?? 'system',
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? '',
      relatedId: map['relatedId'],
      isRead: map['isRead'] ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel.fromMap(data, docId: doc.id);
  }
}
