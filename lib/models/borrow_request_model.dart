import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowRequestModel {
  final String id;
  final String itemId;
  final String itemName;
  final String category;
  final String itemPhotoUrl;
  final String ownerId;
  final String borrowerId;
  final String borrowerName;
  final String borrowerDepartment;
  final String borrowerPhotoUrl;
  final double borrowerRating;
  final String collegeId;
  final DateTime? requiredDate;
  final String requiredTime;
  final String duration;
  final String pickupLocation;
  final String? message;
  final String status; // 'open', 'pending', 'helper_selected', 'handoff', 'active', 'completed', 'cancelled', 'returned'
  final String? rejectionReason;
  final List<String> helperIds;
  final List<Map<String, dynamic>> helpers;
  final String? acceptedHelperId;
  final String? acceptedHelperName;
  final DateTime? acceptedHelperAt;
  final List<String> rejectedHelperIds;
  final String? chatId;
  final DateTime createdAt;
  final DateTime updatedAt;

  BorrowRequestModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.category = '',
    this.itemPhotoUrl = '',
    required this.ownerId,
    required this.borrowerId,
    required this.borrowerName,
    this.borrowerDepartment = '',
    this.borrowerPhotoUrl = '',
    this.borrowerRating = 0.0,
    this.collegeId = '',
    this.requiredDate,
    this.requiredTime = '',
    this.duration = '',
    required this.pickupLocation,
    this.message,
    this.status = 'open',
    this.rejectionReason,
    this.helperIds = const [],
    this.helpers = const [],
    this.acceptedHelperId,
    this.acceptedHelperName,
    this.acceptedHelperAt,
    this.rejectedHelperIds = const [],
    this.chatId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isOpen => status == 'open' || status == 'pending' || status == 'campus_broadcast';
  bool get isPending => status == 'pending' || status == 'open';
  bool get isHelperSelected => status == 'helper_selected' || acceptedHelperId != null;
  bool get isApproved => status == 'approved' || status == 'helper_selected';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed' || status == 'returned';
  bool get isReturnRequested => status == 'return_requested';
  bool get isReturned => status == 'returned';

  // Aliases for convenience
  String get requesterId => borrowerId;
  String get borrowerCollegeId => collegeId;
  String get requesterName => borrowerName;
  String get itemImageUrl => itemPhotoUrl;
  String? get note => message;
  DateTime? get needUntil => requiredDate;

  String get effectiveChatId {
    if (chatId != null && chatId!.isNotEmpty) return chatId!;
    if (acceptedHelperId != null && acceptedHelperId!.isNotEmpty) {
      return 'chat_${id}_${borrowerId}_$acceptedHelperId';
    }
    return '';
  }

  BorrowRequestModel copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? category,
    String? itemPhotoUrl,
    String? ownerId,
    String? borrowerId,
    String? borrowerName,
    String? borrowerDepartment,
    String? borrowerPhotoUrl,
    double? borrowerRating,
    String? collegeId,
    DateTime? requiredDate,
    bool clearRequiredDate = false,
    String? requiredTime,
    String? duration,
    String? pickupLocation,
    String? message,
    String? status,
    String? rejectionReason,
    List<String>? helperIds,
    List<Map<String, dynamic>>? helpers,
    String? acceptedHelperId,
    bool clearAcceptedHelper = false,
    String? acceptedHelperName,
    DateTime? acceptedHelperAt,
    List<String>? rejectedHelperIds,
    String? chatId,
    bool clearChatId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BorrowRequestModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      itemPhotoUrl: itemPhotoUrl ?? this.itemPhotoUrl,
      ownerId: ownerId ?? this.ownerId,
      borrowerId: borrowerId ?? this.borrowerId,
      borrowerName: borrowerName ?? this.borrowerName,
      borrowerDepartment: borrowerDepartment ?? this.borrowerDepartment,
      borrowerPhotoUrl: borrowerPhotoUrl ?? this.borrowerPhotoUrl,
      borrowerRating: borrowerRating ?? this.borrowerRating,
      collegeId: collegeId ?? this.collegeId,
      requiredDate: clearRequiredDate ? null : (requiredDate ?? this.requiredDate),
      requiredTime: requiredTime ?? this.requiredTime,
      duration: duration ?? this.duration,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      message: message ?? this.message,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      helperIds: helperIds ?? this.helperIds,
      helpers: helpers ?? this.helpers,
      acceptedHelperId: clearAcceptedHelper
          ? null
          : (acceptedHelperId ?? this.acceptedHelperId),
      acceptedHelperName: clearAcceptedHelper
          ? null
          : (acceptedHelperName ?? this.acceptedHelperName),
      acceptedHelperAt: clearAcceptedHelper
          ? null
          : (acceptedHelperAt ?? this.acceptedHelperAt),
      rejectedHelperIds: rejectedHelperIds ?? this.rejectedHelperIds,
      chatId: clearChatId
          ? null
          : (clearAcceptedHelper ? null : (chatId ?? this.chatId)),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': id,
      'itemId': itemId,
      'itemName': itemName,
      'category': category,
      if (itemPhotoUrl.isNotEmpty) ...{
        'itemPhotoUrl': itemPhotoUrl,
        'itemImageUrl': itemPhotoUrl,
      },
      'ownerId': ownerId,
      'borrowerId': borrowerId,
      'requesterId': borrowerId,
      'borrowerName': borrowerName,
      'requesterName': borrowerName,
      'borrowerDepartment': borrowerDepartment,
      'borrowerPhotoUrl': borrowerPhotoUrl,
      'borrowerRating': borrowerRating,
      if (collegeId.isNotEmpty) ...{
        'collegeId': collegeId,
        'borrowerCollegeId': collegeId,
      },
      if (requiredDate != null) ...{
        'requiredDate': Timestamp.fromDate(requiredDate!),
        'needUntil': Timestamp.fromDate(requiredDate!),
      },
      if (requiredTime.isNotEmpty) 'requiredTime': requiredTime,
      if (duration.isNotEmpty) 'duration': duration,
      'pickupLocation': pickupLocation,
      if (message != null && message!.isNotEmpty) ...{
        'message': message,
        'note': message,
      },
      'status': status,
      'requestStatus': status,
      'rejectionReason': rejectionReason,
      'helperIds': helperIds,
      'helpers': helpers,
      'acceptedHelperId': acceptedHelperId,
      'acceptedHelperName': acceptedHelperName,
      'acceptedHelperAt': acceptedHelperAt != null
          ? Timestamp.fromDate(acceptedHelperAt!)
          : null,
      'rejectedHelperIds': rejectedHelperIds,
      'chatId': chatId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BorrowRequestModel.fromMap(
    Map<String, dynamic> map, {
    String? docId,
  }) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rawHelperIds = map['helperIds'];
    final List<String> helperIdsList = rawHelperIds is List
        ? rawHelperIds.map((e) => e.toString()).toList()
        : [];

    final rawHelpers = map['helpers'];
    final List<Map<String, dynamic>> helpersList = rawHelpers is List
        ? rawHelpers
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : [];

    final rawRejected = map['rejectedHelperIds'];
    final List<String> rejectedList = rawRejected is List
        ? rawRejected.map((e) => e.toString()).toList()
        : [];

    final borrowerId = map['requesterId'] ?? map['borrowerId'] ?? '';
    final borrowerName =
        map['requesterName'] ?? map['borrowerName'] ?? 'Student';
    final imageUrl = map['itemImageUrl'] ?? map['itemPhotoUrl'] ?? '';
    final message = map['note'] ?? map['message'];
    final status = map['requestStatus'] ?? map['status'] ?? 'open';
    final collegeId = (map['collegeId'] ??
            map['borrowerCollegeId'] ??
            map['registerNumber'] ??
            map['borrowerRegisterNumber'] ??
            '')
        .toString();

    return BorrowRequestModel(
      id: docId ?? map['requestId'] ?? map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      category: map['category'] ?? '',
      itemPhotoUrl: imageUrl,
      ownerId: map['ownerId'] ?? '',
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerDepartment: map['borrowerDepartment'] ?? '',
      borrowerPhotoUrl: map['borrowerPhotoUrl'] ?? '',
      borrowerRating:
          ((map['borrowerRating'] ?? map['rating']) as num?)?.toDouble().clamp(0.0, 5.0) ??
          0.0,
      collegeId: collegeId,
      requiredDate: parseNullableDate(map['needUntil'] ?? map['requiredDate']),
      requiredTime: map['requiredTime'] ?? '',
      duration: map['duration'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      message: message,
      status: status,
      rejectionReason: map['rejectionReason'],
      helperIds: helperIdsList,
      helpers: helpersList,
      acceptedHelperId: map['acceptedHelperId'] as String?,
      acceptedHelperName: map['acceptedHelperName'] as String?,
      acceptedHelperAt: parseNullableDate(map['acceptedHelperAt']),
      rejectedHelperIds: rejectedList,
      chatId: map['chatId'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory BorrowRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BorrowRequestModel.fromMap(data, docId: doc.id);
  }
}
