import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String department;
  final String academicYear;
  final String semester;
  final String registerNumber;
  final String collegeId;
  final String idCardImageUrl;
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final String? rejectionReason;
  final bool isActive;
  final int itemsListedCount;
  final int borrowedCount;
  final double ratingAverage;
  final int ratingsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.department = '',
    this.academicYear = '',
    this.semester = '',
    this.registerNumber = '',
    this.collegeId = '',
    this.idCardImageUrl = '',
    this.verificationStatus = 'pending',
    this.rejectionReason,
    this.isActive = true,
    this.itemsListedCount = 0,
    this.borrowedCount = 0,
    this.ratingAverage = 0.0,
    this.ratingsCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isAdmin =>
      AppConstants.adminEmails.contains(email.trim().toLowerCase()) ||
      email.trim().toLowerCase().startsWith('admin@');
  bool get isVerified =>
      verificationStatus == 'verified' || verificationStatus == 'approved';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? department,
    String? academicYear,
    String? semester,
    String? registerNumber,
    String? collegeId,
    String? idCardImageUrl,
    String? verificationStatus,
    String? rejectionReason,
    bool? isActive,
    int? itemsListedCount,
    int? borrowedCount,
    double? ratingAverage,
    int? ratingsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      registerNumber: registerNumber ?? this.registerNumber,
      collegeId: collegeId ?? this.collegeId,
      idCardImageUrl: idCardImageUrl ?? this.idCardImageUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isActive: isActive ?? this.isActive,
      itemsListedCount: itemsListedCount ?? this.itemsListedCount,
      borrowedCount: borrowedCount ?? this.borrowedCount,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final effectiveCollegeId = collegeId.isNotEmpty ? collegeId : registerNumber;
    final effectiveRegisterNumber =
        registerNumber.isNotEmpty ? registerNumber : collegeId;

    return {
      'academicYear': academicYear,
      'borrowedCount': borrowedCount,
      'collegeId': effectiveCollegeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'department': department,
      'email': email,
      'fullName': fullName,
      'idCardImageUrl': idCardImageUrl,
      'isActive': isActive,
      'itemsListedCount': itemsListedCount,
      'ratingAverage': ratingAverage,
      'ratingsCount': ratingsCount,
      'registerNumber': effectiveRegisterNumber,
      'rejectionReason': rejectionReason,
      'semester': semester,
      'uid': uid,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'verificationStatus': verificationStatus,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    // Support canonical fields with safe fallback for unmigrated fields
    final String resolvedFullName =
        (map['fullName'] ?? map['name'] ?? '').toString();
    final String resolvedAcademicYear =
        (map['academicYear'] ?? map['year'] ?? '').toString();
    final String resolvedIdCardImageUrl =
        (map['idCardImageUrl'] ?? map['idCardUrl'] ?? '').toString();
    final String resolvedRegisterNumber =
        (map['registerNumber'] ?? map['collegeId'] ?? '').toString();
    final String resolvedCollegeId =
        (map['collegeId'] ?? map['registerNumber'] ?? '').toString();

    return UserModel(
      uid: docId ?? map['uid'] ?? '',
      fullName: resolvedFullName,
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      academicYear: resolvedAcademicYear,
      semester: map['semester'] ?? '',
      registerNumber: resolvedRegisterNumber,
      collegeId: resolvedCollegeId,
      idCardImageUrl: resolvedIdCardImageUrl,
      verificationStatus: map['verificationStatus'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      isActive: map['isActive'] ?? true,
      itemsListedCount: (map['itemsListedCount'] as num?)?.toInt() ?? 0,
      borrowedCount: (map['borrowedCount'] as num?)?.toInt() ?? 0,
      ratingAverage: () {
        final count = (map['ratingsCount'] ?? map['ratingCount'] as num?)?.toInt() ?? 0;
        if (count == 0) return 0.0;
        final raw = (map['ratingAverage'] ?? map['rating'] as num?)?.toDouble() ?? 0.0;
        return raw.clamp(0.0, 5.0);
      }(),
      ratingsCount: (map['ratingsCount'] ?? map['ratingCount'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, docId: doc.id);
  }
}
