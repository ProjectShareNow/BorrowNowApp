import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reportedUserId;
  final String reportedUserName;
  final String? itemId;
  final String? transactionId;
  final String reason;
  final String description;
  final String status; // 'pending', 'under_review', 'resolved', 'dismissed'
  final String? adminNotes;
  final String? evidenceUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reportedUserId,
    required this.reportedUserName,
    this.itemId,
    this.transactionId,
    required this.reason,
    required this.description,
    this.status = 'pending',
    this.adminNotes,
    this.evidenceUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isPending => status == 'pending';
  bool get isUnderReview => status == 'under_review';
  bool get isResolved => status == 'resolved';
  bool get isDismissed => status == 'dismissed';
  String get category => reason;

  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? reportedUserId,
    String? reportedUserName,
    String? itemId,
    String? transactionId,
    String? reason,
    String? description,
    String? status,
    String? adminNotes,
    String? evidenceUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reportedUserName: reportedUserName ?? this.reportedUserName,
      itemId: itemId ?? this.itemId,
      transactionId: transactionId ?? this.transactionId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportId': id,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'itemId': itemId,
      'transactionId': transactionId,
      'reason': reason,
      'category': reason,
      'description': description,
      'status': status,
      'adminNotes': adminNotes,
      'evidenceUrl': evidenceUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ReportModel(
      id: docId ?? map['reportId'] ?? map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? 'Student',
      reportedUserId: map['reportedUserId'] ?? '',
      reportedUserName: map['reportedUserName'] ?? 'Student',
      itemId: map['itemId'],
      transactionId: map['transactionId'],
      reason: map['reason'] ?? map['category'] ?? 'Other issues',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      adminNotes: map['adminNotes'],
      evidenceUrl: map['evidenceUrl'] ?? map['evidencePhotoUrl'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReportModel.fromMap(data, docId: doc.id);
  }
}
