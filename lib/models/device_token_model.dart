import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceTokenModel {
  final String id;
  final String userId;
  final String token;
  final String platform;
  final DateTime updatedAt;

  DeviceTokenModel({
    required this.id,
    required this.userId,
    required this.token,
    required this.platform,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'token': token,
      'platform': platform,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DeviceTokenModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return DeviceTokenModel(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      token: map['token'] ?? '',
      platform: map['platform'] ?? 'unknown',
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory DeviceTokenModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DeviceTokenModel.fromMap(data, docId: doc.id);
  }
}
