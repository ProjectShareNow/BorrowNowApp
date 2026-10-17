import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String requestId;
  final String itemId;
  final String itemName;
  final String itemPhotoUrl;
  final String ownerId; // Backward-compatible alias for lenderId
  final String lenderId;
  final String borrowerId;
  final String ownerName; // Backward-compatible alias for lenderName
  final String lenderName;
  final String borrowerName;
  final List<String> participants;
  final String status; // 'active', 'closed'
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastSenderId;
  final int unreadCountOwner;
  final int unreadCountBorrower;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.requestId,
    required this.itemId,
    required this.itemName,
    this.itemPhotoUrl = '',
    String? ownerId,
    String? lenderId,
    required this.borrowerId,
    String? ownerName,
    String? lenderName,
    required this.borrowerName,
    List<String>? participants,
    this.status = 'active',
    this.lastMessage = '',
    DateTime? lastMessageTime,
    this.lastSenderId = '',
    this.unreadCountOwner = 0,
    this.unreadCountBorrower = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : ownerId = ownerId ?? lenderId ?? '',
        lenderId = lenderId ?? ownerId ?? '',
        ownerName = ownerName ?? lenderName ?? 'Lender',
        lenderName = lenderName ?? ownerName ?? 'Lender',
        participants = participants ??
            [
              borrowerId,
              (lenderId ?? ownerId ?? ''),
            ].where((s) => s.isNotEmpty).toList(),
        lastMessageTime = lastMessageTime ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';

  bool isUserParticipant(String userId) {
    if (participants.contains(userId)) return true;
    return userId == ownerId || userId == lenderId || userId == borrowerId;
  }

  String getOtherUserName(String currentUserId) {
    return currentUserId == borrowerId
        ? (lenderName.isNotEmpty ? lenderName : ownerName)
        : borrowerName;
  }

  int getUnreadCount(String currentUserId) {
    return currentUserId == ownerId || currentUserId == lenderId
        ? unreadCountOwner
        : unreadCountBorrower;
  }

  ChatModel copyWith({
    String? id,
    String? requestId,
    String? itemId,
    String? itemName,
    String? itemPhotoUrl,
    String? ownerId,
    String? lenderId,
    String? borrowerId,
    String? ownerName,
    String? lenderName,
    String? borrowerName,
    List<String>? participants,
    String? status,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastSenderId,
    int? unreadCountOwner,
    int? unreadCountBorrower,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final effectiveOwnerId = ownerId ?? lenderId ?? this.ownerId;
    final effectiveLenderId = lenderId ?? ownerId ?? this.lenderId;
    final effectiveOwnerName = ownerName ?? lenderName ?? this.ownerName;
    final effectiveLenderName = lenderName ?? ownerName ?? this.lenderName;

    return ChatModel(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemPhotoUrl: itemPhotoUrl ?? this.itemPhotoUrl,
      ownerId: effectiveOwnerId,
      lenderId: effectiveLenderId,
      borrowerId: borrowerId ?? this.borrowerId,
      ownerName: effectiveOwnerName,
      lenderName: effectiveLenderName,
      borrowerName: borrowerName ?? this.borrowerName,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      unreadCountOwner: unreadCountOwner ?? this.unreadCountOwner,
      unreadCountBorrower: unreadCountBorrower ?? this.unreadCountBorrower,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final effectiveLenderId = lenderId.isNotEmpty ? lenderId : ownerId;
    final effectiveLenderName = lenderName.isNotEmpty ? lenderName : ownerName;
    final participantList = participants.isNotEmpty
        ? participants
        : [borrowerId, effectiveLenderId].where((s) => s.isNotEmpty).toList();

    return {
      'id': id,
      'chatId': id,
      'requestId': requestId,
      'itemId': itemId,
      'itemName': itemName,
      'itemPhotoUrl': itemPhotoUrl,
      'ownerId': effectiveLenderId,
      'lenderId': effectiveLenderId,
      'borrowerId': borrowerId,
      'ownerName': effectiveLenderName,
      'lenderName': effectiveLenderName,
      'borrowerName': borrowerName,
      'participants': participantList,
      'status': status,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageAt': Timestamp.fromDate(lastMessageTime),
      'lastSenderId': lastSenderId,
      'unreadCountOwner': unreadCountOwner,
      'unreadCountBorrower': unreadCountBorrower,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final String bId = (map['borrowerId'] ?? '').toString();
    final String oId = (map['lenderId'] ?? map['ownerId'] ?? '').toString();
    final String bName = (map['borrowerName'] ?? 'Borrower').toString();
    final String oName = (map['lenderName'] ?? map['ownerName'] ?? 'Lender').toString();

    final rawParticipants = map['participants'];
    final List<String> participantsList = rawParticipants is List
        ? rawParticipants.map((e) => e.toString()).toList()
        : <String>[bId, oId].where((s) => s.isNotEmpty).toList();

    return ChatModel(
      id: docId ?? map['chatId'] ?? map['id'] ?? '',
      requestId: map['requestId'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      itemPhotoUrl: map['itemPhotoUrl'] ?? '',
      ownerId: oId,
      lenderId: oId,
      borrowerId: bId,
      ownerName: oName,
      lenderName: oName,
      borrowerName: bName,
      participants: participantsList,
      status: map['status'] ?? 'active',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: parseDate(map['lastMessageAt'] ?? map['lastMessageTime']),
      lastSenderId: map['lastSenderId'] ?? '',
      unreadCountOwner: (map['unreadCountOwner'] as num?)?.toInt() ?? 0,
      unreadCountBorrower: (map['unreadCountBorrower'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatModel.fromMap(data, docId: doc.id);
  }
}
