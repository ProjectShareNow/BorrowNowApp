import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/id_generator.dart';
import '../app/app_config.dart';
import '../models/rating_model.dart';
import '../models/notification_model.dart';
import 'in_memory_store.dart';

class RatingService {
  final FirebaseFirestore? firestore;

  RatingService({this.firestore});

  /// Check if user has already rated this transaction
  Future<bool> hasUserRatedTransaction({
    required String transactionId,
    required String fromUserId,
  }) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final docId = '${transactionId}_$fromUserId';
      final docSnap = await firestore.collection('ratings').doc(docId).get();
      if (docSnap.exists) return true;

      final snapshot = await firestore
          .collection('ratings')
          .where('transactionId', isEqualTo: transactionId)
          .where('reviewerId', isEqualTo: fromUserId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) return true;

      // Fallback check on fromUserId alias
      final legacySnap = await firestore
          .collection('ratings')
          .where('transactionId', isEqualTo: transactionId)
          .where('fromUserId', isEqualTo: fromUserId)
          .limit(1)
          .get();
      return legacySnap.docs.isNotEmpty;
    } else {
      return InMemoryStore.instance.ratings.values.any(
        (r) =>
            r.transactionId == transactionId &&
            (r.reviewerId == fromUserId || r.fromUserId == fromUserId),
      );
    }
  }

  /// Get review submitted by a specific user for a transaction
  Future<RatingModel?> getReviewForTransaction({
    required String transactionId,
    required String userId,
  }) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final docId = '${transactionId}_$userId';
      final docSnap = await firestore.collection('ratings').doc(docId).get();
      if (docSnap.exists) {
        return RatingModel.fromFirestore(docSnap);
      }

      final query = await firestore
          .collection('ratings')
          .where('transactionId', isEqualTo: transactionId)
          .where('reviewerId', isEqualTo: userId)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return RatingModel.fromFirestore(query.docs.first);
      }

      final legacyQuery = await firestore
          .collection('ratings')
          .where('transactionId', isEqualTo: transactionId)
          .where('fromUserId', isEqualTo: userId)
          .limit(1)
          .get();
      if (legacyQuery.docs.isNotEmpty) {
        return RatingModel.fromFirestore(legacyQuery.docs.first);
      }
      return null;
    } else {
      try {
        return InMemoryStore.instance.ratings.values.firstWhere(
          (r) =>
              r.transactionId == transactionId &&
              (r.reviewerId == userId || r.fromUserId == userId),
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Get the other party's review for this transaction
  Future<RatingModel?> getOtherPartyReview({
    required String transactionId,
    required String currentUserId,
  }) async {
    final reviews = await getTransactionReviews(transactionId);
    try {
      return reviews.firstWhere(
        (r) => r.reviewerId != currentUserId && r.fromUserId != currentUserId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all reviews for a transaction (borrower's review & lender's review)
  Future<List<RatingModel>> getTransactionReviews(String transactionId) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final snapshot = await firestore
          .collection('ratings')
          .where('transactionId', isEqualTo: transactionId)
          .get();
      return snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc))
          .toList();
    } else {
      return InMemoryStore.instance.ratings.values
          .where((r) => r.transactionId == transactionId)
          .toList();
    }
  }

  /// Submit rating and review (1 to 5 stars, never 0; completed transactions only)
  Future<void> submitRating(RatingModel rating) async {
    // 1. Rating scale validation: 1 to 5 stars, cannot be 0 or outside [1.0, 5.0]
    if (rating.rating < 1.0 || rating.rating > 5.0) {
      throw Exception(
        'Rating must be between 1 and 5 stars. Ratings of 0 are not allowed.',
      );
    }

    if (rating.transactionId.trim().isEmpty) {
      throw Exception(
        'A valid completed transaction is required to submit a rating.',
      );
    }

    // 2. Prevent self-rating
    if (rating.reviewerId.isNotEmpty && rating.reviewerId == rating.revieweeId) {
      throw Exception('You cannot submit a review for yourself.');
    }

    // 3. Prevent duplicate reviews from the same participant for the same transaction
    final alreadyRated = await hasUserRatedTransaction(
      transactionId: rating.transactionId,
      fromUserId: rating.reviewerId,
    );
    if (alreadyRated) {
      throw Exception(
        'You have already submitted a rating for this transaction.',
      );
    }

    // Enforce document structure: ${transactionId}_${reviewerId}
    final ratingId = '${rating.transactionId}_${rating.reviewerId}';

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      // 4. Security: Only count valid reviews associated with completed transactions
      final txnDoc = await firestore
          .collection('transactions')
          .doc(rating.transactionId)
          .get();
      if (!txnDoc.exists) {
        throw Exception('Transaction not found.');
      }

      final txnData = txnDoc.data();
      final status = (txnData?['status'] as String? ?? '').toLowerCase();
      if (status != 'completed' && status != 'returned') {
        throw Exception(
          'Ratings can only be submitted for completed transactions.',
        );
      }

      final ownerId = txnData?['ownerId'] as String? ?? '';
      final borrowerId = txnData?['borrowerId'] as String? ?? '';
      final itemName = txnData?['itemName'] as String? ?? 'Item';
      final requestId = txnData?['requestId'] as String? ?? rating.requestId;
      final itemId = txnData?['itemId'] as String? ?? rating.itemId;

      final isBorrower = rating.reviewerId == borrowerId;
      final isOwner = rating.reviewerId == ownerId;

      if (!isBorrower && !isOwner) {
        throw Exception(
          'Only verified transaction participants can submit a review.',
        );
      }

      final resolvedRole = rating.reviewerRole.isNotEmpty
          ? rating.reviewerRole
          : (isBorrower ? 'borrower' : 'lender');

      final newRating = rating.copyWith(
        id: ratingId,
        ratingId: ratingId,
        requestId: requestId,
        itemId: itemId,
        reviewerRole: resolvedRole,
      );

      final batch = firestore.batch();
      batch.set(
        firestore.collection('ratings').doc(ratingId),
        newRating.toMap(),
      );

      // Update rated flags on transaction
      final txnUpdate = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (isBorrower) {
        txnUpdate['borrowerRated'] = true;
      }
      if (isOwner) {
        txnUpdate['lenderRated'] = true;
      }
      batch.update(
        firestore.collection('transactions').doc(rating.transactionId),
        txnUpdate,
      );

      // Recalculate recipient rating from actual submitted reviews
      final ratingsSnapshot = await firestore
          .collection('ratings')
          .where('toUserId', isEqualTo: rating.revieweeId)
          .get();

      final existingRatings = ratingsSnapshot.docs
          .where((doc) => doc.id != ratingId)
          .map((doc) => (doc.data()['rating'] as num?)?.toDouble() ?? 0.0)
          .where((r) => r >= 1.0 && r <= 5.0)
          .toList();

      final allRatings = [...existingRatings, newRating.rating];
      final newCount = allRatings.length;
      final sum = allRatings.fold(0.0, (acc, val) => acc + val);
      final rawAvg = newCount > 0 ? (sum / newCount) : 0.0;
      final newAvg = double.parse(rawAvg.clamp(0.0, 5.0).toStringAsFixed(1));

      batch.set(
        firestore.collection('users').doc(rating.revieweeId),
        {
          'ratingAverage': newAvg,
          'ratingsCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Send in-app notification to reviewee
      final notifId = FirestoreIdGenerator.generateId('notifications');
      batch.set(
        firestore.collection('notifications').doc(notifId),
        {
          'id': notifId,
          'recipientId': rating.revieweeId,
          'senderId': rating.reviewerId,
          'senderName': rating.reviewerName,
          'type': 'rating_received',
          'title': 'New Review Received ⭐',
          'message':
              '${rating.reviewerName} gave you a ${newRating.rating.toInt()}-star rating for "$itemName".',
          'relatedId': rating.transactionId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
    } else {
      // InMemoryStore flow
      final txn = InMemoryStore.instance.transactions[rating.transactionId];
      if (txn == null) {
        throw Exception('Transaction not found.');
      }
      final status = txn.status.toLowerCase();
      if (status != 'completed' && status != 'returned') {
        throw Exception(
          'Ratings can only be submitted for completed transactions.',
        );
      }

      final isBorrower = rating.reviewerId == txn.borrowerId;
      final isOwner = rating.reviewerId == txn.ownerId;
      if (!isBorrower && !isOwner) {
        throw Exception(
          'Only verified transaction participants can submit a review.',
        );
      }

      final resolvedRole = rating.reviewerRole.isNotEmpty
          ? rating.reviewerRole
          : (isBorrower ? 'borrower' : 'lender');

      final newRating = rating.copyWith(
        id: ratingId,
        ratingId: ratingId,
        requestId: txn.requestId,
        itemId: txn.itemId,
        reviewerRole: resolvedRole,
      );

      InMemoryStore.instance.ratings[ratingId] = newRating;

      // Update transaction rated flags
      InMemoryStore.instance.transactions[rating.transactionId] = txn.copyWith(
        borrowerRated: isBorrower ? true : txn.borrowerRated,
        lenderRated: isOwner ? true : txn.lenderRated,
      );
      InMemoryStore.instance.notifyTransactions();

      final user = InMemoryStore.instance.users[rating.revieweeId];
      if (user != null) {
        final allScores = InMemoryStore.instance.ratings.values
            .where(
              (r) =>
                  (r.revieweeId == rating.revieweeId ||
                      r.toUserId == rating.revieweeId) &&
                  r.rating >= 1.0 &&
                  r.rating <= 5.0,
            )
            .map((r) => r.rating)
            .toList();

        final newCount = allScores.length;
        final sum = allScores.fold(0.0, (acc, val) => acc + val);
        final rawAvg = newCount > 0 ? (sum / newCount) : 0.0;
        final newAvg = double.parse(rawAvg.clamp(0.0, 5.0).toStringAsFixed(1));

        InMemoryStore.instance.users[rating.revieweeId] = user.copyWith(
          ratingAverage: newAvg,
          ratingsCount: newCount,
        );
        InMemoryStore.instance.notifyUsers();
      }

      // Add notification in InMemoryStore
      final notifId = FirestoreIdGenerator.generateId('notifications');
      final notif = NotificationModel(
        id: notifId,
        recipientId: rating.revieweeId,
        senderId: rating.reviewerId,
        senderName: rating.reviewerName,
        type: 'rating_received',
        title: 'New Review Received ⭐',
        message:
            '${rating.reviewerName} gave you a ${newRating.rating.toInt()}-star rating for "${txn.itemName}".',
        relatedId: rating.transactionId,
      );
      InMemoryStore.instance.notifications[notifId] = notif;
      InMemoryStore.instance.notifyNotifications();
    }
  }

  /// Recalculate and persist user rating average from actual review history.
  /// If the user has 0 valid reviews, sets ratingAverage to 0.0 and ratingsCount to 0.
  Future<void> recalculateUserRating(String userId) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final ratingsSnapshot = await firestore
          .collection('ratings')
          .where('toUserId', isEqualTo: userId)
          .get();

      final validRatings = ratingsSnapshot.docs
          .map((doc) => (doc.data()['rating'] as num?)?.toDouble() ?? 0.0)
          .where((r) => r >= 1.0 && r <= 5.0)
          .toList();

      final count = validRatings.length;
      final sum = validRatings.fold(0.0, (acc, val) => acc + val);
      final avg = count > 0 ? double.parse((sum / count).clamp(0.0, 5.0).toStringAsFixed(1)) : 0.0;

      await firestore.collection('users').doc(userId).set({
        'ratingAverage': avg,
        'ratingsCount': count,
      }, SetOptions(merge: true));
    } else {
      final user = InMemoryStore.instance.users[userId];
      if (user != null) {
        final validRatings = InMemoryStore.instance.ratings.values
            .where((r) => r.toUserId == userId && r.rating >= 1.0 && r.rating <= 5.0)
            .map((r) => r.rating)
            .toList();

        final count = validRatings.length;
        final sum = validRatings.fold(0.0, (acc, val) => acc + val);
        final avg = count > 0 ? double.parse((sum / count).clamp(0.0, 5.0).toStringAsFixed(1)) : 0.0;

        InMemoryStore.instance.users[userId] = user.copyWith(
          ratingAverage: avg,
          ratingsCount: count,
        );
        InMemoryStore.instance.notifyUsers();
      }
    }
  }

  /// Get ratings received by a user
  Future<List<RatingModel>> getUserReviews(String userId) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final snapshot = await firestore
          .collection('ratings')
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc))
          .toList();
    } else {
      return InMemoryStore.instance.ratings.values
          .where((r) => r.toUserId == userId || r.revieweeId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }
}
