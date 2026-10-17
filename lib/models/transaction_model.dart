import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String requestId;
  final String itemId;
  final String itemName;
  final String itemPhotoUrl;
  final String ownerId;
  final String borrowerId;
  final String ownerName;
  final String borrowerName;
  final DateTime? pickupTime;
  final DateTime? expectedReturnDate;
  final DateTime? returnRequestedAt;
  final DateTime? returnedAt;
  final bool ownerReady;
  final bool borrowerReady;
  final bool pickupConfirmed;
  final String
  status; // 'scheduled', 'active', 'return_requested', 'completed', 'disputed'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Handover identity verification & live camera photo evidence
  final bool handoverIdentityVerified;
  final String handoverVerifiedBy;
  final DateTime? handoverVerifiedAt;
  final String maskedBorrowerRegisterNumber;
  final String handoverPhotoUrl;
  final String handoverPhotoStoragePath;
  final DateTime? handoverPhotoUploadedAt;
  final bool handoverConfirmed;
  final DateTime? handoverConfirmedAt;

  // Return workflow verification & live camera photo evidence
  final bool returnIdentityVerified;
  final String returnVerifiedBy;
  final DateTime? returnVerifiedAt;
  final String maskedLenderRegisterNumber;
  final String returnPhotoUrl;
  final String returnPhotoStoragePath;
  final DateTime? returnPhotoUploadedAt;
  final bool borrowerReturnConfirmed;
  final DateTime? borrowerReturnConfirmedAt;
  final bool lenderReturnConfirmed;
  final DateTime? lenderReturnConfirmedAt;
  final DateTime? completedAt;
  final String returnCondition; // 'good', 'fair', 'damaged'
  final bool damageReported;
  final String? damageDetails;
  final bool borrowerRated;
  final bool lenderRated;

  TransactionModel({
    required this.id,
    required this.requestId,
    required this.itemId,
    required this.itemName,
    this.itemPhotoUrl = '',
    required this.ownerId,
    required this.borrowerId,
    required this.ownerName,
    required this.borrowerName,
    this.pickupTime,
    this.expectedReturnDate,
    this.returnRequestedAt,
    this.returnedAt,
    this.ownerReady = false,
    this.borrowerReady = false,
    this.pickupConfirmed = false,
    this.status = 'scheduled',
    DateTime? createdAt,
    DateTime? updatedAt,
    // Handover fields
    this.handoverIdentityVerified = false,
    this.handoverVerifiedBy = '',
    this.handoverVerifiedAt,
    this.maskedBorrowerRegisterNumber = '',
    this.handoverPhotoUrl = '',
    this.handoverPhotoStoragePath = '',
    this.handoverPhotoUploadedAt,
    this.handoverConfirmed = false,
    this.handoverConfirmedAt,
    // Return fields
    this.returnIdentityVerified = false,
    this.returnVerifiedBy = '',
    this.returnVerifiedAt,
    this.maskedLenderRegisterNumber = '',
    this.returnPhotoUrl = '',
    this.returnPhotoStoragePath = '',
    this.returnPhotoUploadedAt,
    this.borrowerReturnConfirmed = false,
    this.borrowerReturnConfirmedAt,
    this.lenderReturnConfirmed = false,
    this.lenderReturnConfirmedAt,
    this.completedAt,
    this.returnCondition = 'good',
    this.damageReported = false,
    this.damageDetails,
    this.borrowerRated = false,
    this.lenderRated = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isScheduled => status == 'scheduled';
  bool get isActive => status == 'active';
  bool get isReturnRequested => status == 'return_requested';
  bool get isCompleted => status == 'completed';
  bool get isReturned => status == 'returned' || status == 'completed';
  bool get isDisputed => status == 'disputed';

  bool hasUserRated(String userId) {
    if (userId == borrowerId) return borrowerRated;
    if (userId == ownerId) return lenderRated;
    return false;
  }

  bool hasOtherPartyRated(String userId) {
    if (userId == borrowerId) return lenderRated;
    if (userId == ownerId) return borrowerRated;
    return false;
  }

  bool get isOverdue {
    if (isCompleted) return false;
    final dueDate =
        expectedReturnDate ?? pickupTime?.add(const Duration(days: 3));
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate);
  }

  bool get bothReady => ownerReady && borrowerReady;

  bool get isHandoverReadyToConfirm =>
      handoverIdentityVerified &&
      handoverPhotoUrl.isNotEmpty &&
      !handoverConfirmed &&
      isScheduled;

  bool get isReturnReadyToConfirm =>
      returnIdentityVerified &&
      returnPhotoUrl.isNotEmpty &&
      isReturnRequested;

  TransactionModel copyWith({
    String? id,
    String? requestId,
    String? itemId,
    String? itemName,
    String? itemPhotoUrl,
    String? ownerId,
    String? borrowerId,
    String? ownerName,
    String? borrowerName,
    DateTime? pickupTime,
    DateTime? expectedReturnDate,
    DateTime? returnRequestedAt,
    DateTime? returnedAt,
    bool? ownerReady,
    bool? borrowerReady,
    bool? pickupConfirmed,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? handoverIdentityVerified,
    String? handoverVerifiedBy,
    DateTime? handoverVerifiedAt,
    String? maskedBorrowerRegisterNumber,
    String? handoverPhotoUrl,
    String? handoverPhotoStoragePath,
    DateTime? handoverPhotoUploadedAt,
    bool? handoverConfirmed,
    DateTime? handoverConfirmedAt,
    bool? returnIdentityVerified,
    String? returnVerifiedBy,
    DateTime? returnVerifiedAt,
    String? maskedLenderRegisterNumber,
    String? returnPhotoUrl,
    String? returnPhotoStoragePath,
    DateTime? returnPhotoUploadedAt,
    bool? borrowerReturnConfirmed,
    DateTime? borrowerReturnConfirmedAt,
    bool? lenderReturnConfirmed,
    DateTime? lenderReturnConfirmedAt,
    DateTime? completedAt,
    String? returnCondition,
    bool? damageReported,
    String? damageDetails,
    bool? borrowerRated,
    bool? lenderRated,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemPhotoUrl: itemPhotoUrl ?? this.itemPhotoUrl,
      ownerId: ownerId ?? this.ownerId,
      borrowerId: borrowerId ?? this.borrowerId,
      ownerName: ownerName ?? this.ownerName,
      borrowerName: borrowerName ?? this.borrowerName,
      pickupTime: pickupTime ?? this.pickupTime,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      returnRequestedAt: returnRequestedAt ?? this.returnRequestedAt,
      returnedAt: returnedAt ?? this.returnedAt,
      ownerReady: ownerReady ?? this.ownerReady,
      borrowerReady: borrowerReady ?? this.borrowerReady,
      pickupConfirmed: pickupConfirmed ?? this.pickupConfirmed,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      handoverIdentityVerified:
          handoverIdentityVerified ?? this.handoverIdentityVerified,
      handoverVerifiedBy: handoverVerifiedBy ?? this.handoverVerifiedBy,
      handoverVerifiedAt: handoverVerifiedAt ?? this.handoverVerifiedAt,
      maskedBorrowerRegisterNumber:
          maskedBorrowerRegisterNumber ?? this.maskedBorrowerRegisterNumber,
      handoverPhotoUrl: handoverPhotoUrl ?? this.handoverPhotoUrl,
      handoverPhotoStoragePath:
          handoverPhotoStoragePath ?? this.handoverPhotoStoragePath,
      handoverPhotoUploadedAt:
          handoverPhotoUploadedAt ?? this.handoverPhotoUploadedAt,
      handoverConfirmed: handoverConfirmed ?? this.handoverConfirmed,
      handoverConfirmedAt: handoverConfirmedAt ?? this.handoverConfirmedAt,
      returnIdentityVerified:
          returnIdentityVerified ?? this.returnIdentityVerified,
      returnVerifiedBy: returnVerifiedBy ?? this.returnVerifiedBy,
      returnVerifiedAt: returnVerifiedAt ?? this.returnVerifiedAt,
      maskedLenderRegisterNumber:
          maskedLenderRegisterNumber ?? this.maskedLenderRegisterNumber,
      returnPhotoUrl: returnPhotoUrl ?? this.returnPhotoUrl,
      returnPhotoStoragePath:
          returnPhotoStoragePath ?? this.returnPhotoStoragePath,
      returnPhotoUploadedAt:
          returnPhotoUploadedAt ?? this.returnPhotoUploadedAt,
      borrowerReturnConfirmed:
          borrowerReturnConfirmed ?? this.borrowerReturnConfirmed,
      borrowerReturnConfirmedAt:
          borrowerReturnConfirmedAt ?? this.borrowerReturnConfirmedAt,
      lenderReturnConfirmed:
          lenderReturnConfirmed ?? this.lenderReturnConfirmed,
      lenderReturnConfirmedAt:
          lenderReturnConfirmedAt ?? this.lenderReturnConfirmedAt,
      completedAt: completedAt ?? this.completedAt,
      returnCondition: returnCondition ?? this.returnCondition,
      damageReported: damageReported ?? this.damageReported,
      damageDetails: damageDetails ?? this.damageDetails,
      borrowerRated: borrowerRated ?? this.borrowerRated,
      lenderRated: lenderRated ?? this.lenderRated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': id,
      'requestId': requestId,
      'itemId': itemId,
      'itemName': itemName,
      'itemPhotoUrl': itemPhotoUrl,
      'ownerId': ownerId,
      'borrowerId': borrowerId,
      'ownerName': ownerName,
      'borrowerName': borrowerName,
      'pickupTime': pickupTime != null ? Timestamp.fromDate(pickupTime!) : null,
      'expectedReturnDate': expectedReturnDate != null
          ? Timestamp.fromDate(expectedReturnDate!)
          : null,
      'returnRequestedAt': returnRequestedAt != null
          ? Timestamp.fromDate(returnRequestedAt!)
          : null,
      'returnedAt': returnedAt != null ? Timestamp.fromDate(returnedAt!) : null,
      'ownerReady': ownerReady,
      'borrowerReady': borrowerReady,
      'pickupConfirmed': pickupConfirmed,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      // Handover evidence & verification fields
      'handoverIdentityVerified': handoverIdentityVerified,
      'handoverVerifiedBy': handoverVerifiedBy,
      'handoverVerifiedAt': handoverVerifiedAt != null
          ? Timestamp.fromDate(handoverVerifiedAt!)
          : null,
      'maskedBorrowerRegisterNumber': maskedBorrowerRegisterNumber,
      'handoverPhotoUrl': handoverPhotoUrl,
      'handoverPhotoStoragePath': handoverPhotoStoragePath,
      'handoverPhotoUploadedAt': handoverPhotoUploadedAt != null
          ? Timestamp.fromDate(handoverPhotoUploadedAt!)
          : null,
      'handoverConfirmed': handoverConfirmed,
      'handoverConfirmedAt': handoverConfirmedAt != null
          ? Timestamp.fromDate(handoverConfirmedAt!)
          : null,
      // Return evidence & verification fields
      'returnIdentityVerified': returnIdentityVerified,
      'returnVerifiedBy': returnVerifiedBy,
      'returnVerifiedAt': returnVerifiedAt != null
          ? Timestamp.fromDate(returnVerifiedAt!)
          : null,
      'maskedLenderRegisterNumber': maskedLenderRegisterNumber,
      'returnPhotoUrl': returnPhotoUrl,
      'returnPhotoStoragePath': returnPhotoStoragePath,
      'returnPhotoUploadedAt': returnPhotoUploadedAt != null
          ? Timestamp.fromDate(returnPhotoUploadedAt!)
          : null,
      'borrowerReturnConfirmed': borrowerReturnConfirmed,
      'borrowerReturnConfirmedAt': borrowerReturnConfirmedAt != null
          ? Timestamp.fromDate(borrowerReturnConfirmedAt!)
          : null,
      'lenderReturnConfirmed': lenderReturnConfirmed,
      'lenderReturnConfirmedAt': lenderReturnConfirmedAt != null
          ? Timestamp.fromDate(lenderReturnConfirmedAt!)
          : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'returnCondition': returnCondition,
      'damageReported': damageReported,
      'damageDetails': damageDetails,
      'borrowerRated': borrowerRated,
      'lenderRated': lenderRated,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return TransactionModel(
      id: docId ?? map['transactionId'] ?? map['id'] ?? '',
      requestId: map['requestId'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      itemPhotoUrl: map['itemPhotoUrl'] ?? '',
      ownerId: map['ownerId'] ?? '',
      borrowerId: map['borrowerId'] ?? '',
      ownerName: map['ownerName'] ?? 'Owner',
      borrowerName: map['borrowerName'] ?? 'Borrower',
      pickupTime: parseDate(map['pickupTime']),
      expectedReturnDate: parseDate(
        map['expectedReturnDate'] ?? map['dueDate'],
      ),
      returnRequestedAt: parseDate(map['returnRequestedAt']),
      returnedAt: parseDate(map['returnedAt']),
      ownerReady: map['ownerReady'] ?? false,
      borrowerReady: map['borrowerReady'] ?? false,
      pickupConfirmed: map['pickupConfirmed'] ?? false,
      status: map['status'] ?? 'scheduled',
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt']) ?? DateTime.now(),
      // Handover
      handoverIdentityVerified: map['handoverIdentityVerified'] ?? false,
      handoverVerifiedBy: map['handoverVerifiedBy'] ?? '',
      handoverVerifiedAt: parseDate(map['handoverVerifiedAt']),
      maskedBorrowerRegisterNumber:
          map['maskedBorrowerRegisterNumber'] as String? ?? '',
      handoverPhotoUrl: map['handoverPhotoUrl'] ?? '',
      handoverPhotoStoragePath: map['handoverPhotoStoragePath'] ?? '',
      handoverPhotoUploadedAt: parseDate(map['handoverPhotoUploadedAt']),
      handoverConfirmed: map['handoverConfirmed'] ?? false,
      handoverConfirmedAt: parseDate(map['handoverConfirmedAt']),
      // Return
      returnIdentityVerified: map['returnIdentityVerified'] ?? false,
      returnVerifiedBy: map['returnVerifiedBy'] ?? '',
      returnVerifiedAt: parseDate(map['returnVerifiedAt']),
      maskedLenderRegisterNumber:
          map['maskedLenderRegisterNumber'] as String? ?? '',
      returnPhotoUrl: map['returnPhotoUrl'] ?? '',
      returnPhotoStoragePath: map['returnPhotoStoragePath'] ?? '',
      returnPhotoUploadedAt: parseDate(map['returnPhotoUploadedAt']),
      borrowerReturnConfirmed: map['borrowerReturnConfirmed'] ?? false,
      borrowerReturnConfirmedAt: parseDate(map['borrowerReturnConfirmedAt']),
      lenderReturnConfirmed: map['lenderReturnConfirmed'] ?? false,
      lenderReturnConfirmedAt: parseDate(map['lenderReturnConfirmedAt']),
      completedAt: parseDate(map['completedAt']),
      returnCondition: map['returnCondition'] ?? 'good',
      damageReported: map['damageReported'] ?? false,
      damageDetails: map['damageDetails'],
      borrowerRated: map['borrowerRated'] ?? false,
      lenderRated: map['lenderRated'] ?? false,
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransactionModel.fromMap(data, docId: doc.id);
  }
}
