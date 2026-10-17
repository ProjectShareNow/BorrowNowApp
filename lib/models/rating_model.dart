import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String ratingId;
  final String transactionId;
  final String requestId;
  final String itemId;
  final String reviewerId;
  final String reviewerName;
  final String revieweeId;
  final String reviewerRole; // 'borrower' or 'lender'
  final double rating;
  final String feedback;
  final DateTime createdAt;

  RatingModel({
    String? id,
    String? ratingId,
    required this.transactionId,
    this.requestId = '',
    this.itemId = '',
    String? reviewerId,
    String? reviewerName,
    String? revieweeId,
    String? fromUserId,
    String? fromUserName,
    String? toUserId,
    this.reviewerRole = '',
    required this.rating,
    String? feedback,
    String? review,
    DateTime? createdAt,
  })  : id = id ?? ratingId ?? '',
        ratingId = ratingId ?? id ?? '',
        reviewerId = reviewerId ?? fromUserId ?? '',
        reviewerName = reviewerName ?? fromUserName ?? 'User',
        revieweeId = revieweeId ?? toUserId ?? '',
        feedback = feedback ?? review ?? '',
        createdAt = createdAt ?? DateTime.now();

  // Backward compatibility getters
  String get fromUserId => reviewerId;
  String get fromUserName => reviewerName;
  String get toUserId => revieweeId;
  String get review => feedback;

  RatingModel copyWith({
    String? id,
    String? ratingId,
    String? transactionId,
    String? requestId,
    String? itemId,
    String? reviewerId,
    String? reviewerName,
    String? revieweeId,
    String? fromUserId,
    String? fromUserName,
    String? toUserId,
    String? reviewerRole,
    double? rating,
    String? feedback,
    String? review,
    DateTime? createdAt,
  }) {
    return RatingModel(
      id: id ?? ratingId ?? this.id,
      ratingId: ratingId ?? id ?? this.ratingId,
      transactionId: transactionId ?? this.transactionId,
      requestId: requestId ?? this.requestId,
      itemId: itemId ?? this.itemId,
      reviewerId: reviewerId ?? fromUserId ?? this.reviewerId,
      reviewerName: reviewerName ?? fromUserName ?? this.reviewerName,
      revieweeId: revieweeId ?? toUserId ?? this.revieweeId,
      reviewerRole: reviewerRole ?? this.reviewerRole,
      rating: rating ?? this.rating,
      feedback: feedback ?? review ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final effectiveId = id.isNotEmpty ? id : ratingId;
    return {
      'id': effectiveId,
      'ratingId': effectiveId,
      'transactionId': transactionId,
      'requestId': requestId,
      'itemId': itemId,
      'reviewerId': reviewerId,
      'fromUserId': reviewerId,
      'reviewerName': reviewerName,
      'fromUserName': reviewerName,
      'revieweeId': revieweeId,
      'toUserId': revieweeId,
      'reviewerRole': reviewerRole,
      'rating': rating.round(),
      'feedback': feedback,
      'review': feedback,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final resolvedId = docId ?? map['ratingId'] ?? map['id'] ?? '';
    final resolvedReviewerId =
        (map['reviewerId'] ?? map['fromUserId'] ?? '').toString();
    final resolvedReviewerName =
        (map['reviewerName'] ?? map['fromUserName'] ?? 'User').toString();
    final resolvedRevieweeId =
        (map['revieweeId'] ?? map['toUserId'] ?? '').toString();
    final resolvedFeedback =
        (map['feedback'] ?? map['review'] ?? '').toString();
    final rawRating = (map['rating'] as num?)?.toDouble() ?? 5.0;

    return RatingModel(
      id: resolvedId,
      ratingId: resolvedId,
      transactionId: (map['transactionId'] ?? '').toString(),
      requestId: (map['requestId'] ?? '').toString(),
      itemId: (map['itemId'] ?? '').toString(),
      reviewerId: resolvedReviewerId,
      reviewerName: resolvedReviewerName,
      revieweeId: resolvedRevieweeId,
      reviewerRole: (map['reviewerRole'] ?? '').toString(),
      rating: rawRating.clamp(1.0, 5.0),
      feedback: resolvedFeedback,
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RatingModel.fromMap(data, docId: doc.id);
  }
}
