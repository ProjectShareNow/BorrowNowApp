import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String type;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    DateTime? timestamp,
    this.type = 'text',
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    String? type,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'messageId': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'message': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(timestamp),
      'type': type,
      'isRead': isRead,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return MessageModel(
      id: docId ?? map['messageId'] ?? map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['message'] ?? map['text'] ?? '',
      timestamp: parseDate(map['createdAt'] ?? map['timestamp']),
      type: map['type'] ?? 'text',
      isRead: map['isRead'] ?? false,
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel.fromMap(data, docId: doc.id);
  }
}
