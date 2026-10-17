import 'package:flutter_test/flutter_test.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/models/rating_model.dart';
import 'package:borrow_now/models/transaction_model.dart';
import 'package:borrow_now/services/in_memory_store.dart';
import 'package:borrow_now/services/service_registry.dart';
import 'package:borrow_now/utils/helpers.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ServiceRegistry.init();
    InMemoryStore.instance.chats.clear();
    InMemoryStore.instance.messages.clear();
    InMemoryStore.instance.users.clear();
    InMemoryStore.instance.transactions.clear();
    InMemoryStore.instance.items.clear();
    InMemoryStore.instance.requests.clear();
    InMemoryStore.instance.ratings.clear();
  });

  group('BorrowNow Rating System Tests', () {
    test('1. New user initializes ratingAverage at 0.0 and ratingsCount at 0', () {
      final user = UserModel(
        uid: 'user_new_1',
        fullName: 'New Student',
        email: 'newstudent@college.edu',
      );

      expect(user.ratingAverage, 0.0);
      expect(user.ratingsCount, 0);
    });

    test('2. UserModel.fromMap handles legacy 0 reviews safely without 5.0 default', () {
      // Legacy user map with no reviews
      final legacyMap = {
        'uid': 'legacy_user_1',
        'fullName': 'Legacy Student',
        'email': 'legacy@college.edu',
        'ratingAverage': 5.0, // Old default from legacy records
        'ratingsCount': 0,    // 0 actual reviews
      };

      final parsedUser = UserModel.fromMap(legacyMap);
      expect(parsedUser.ratingAverage, 0.0);
      expect(parsedUser.ratingsCount, 0);

      // User with valid reviews preserves their score
      final reviewedMap = {
        'uid': 'reviewed_user_1',
        'fullName': 'Reviewed Student',
        'email': 'reviewed@college.edu',
        'ratingAverage': 4.7,
        'ratingsCount': 3,
      };

      final reviewedUser = UserModel.fromMap(reviewedMap);
      expect(reviewedUser.ratingAverage, 4.7);
      expect(reviewedUser.ratingsCount, 3);
    });

    test('3. AppHelpers formatting correctly displays 0.0 / 5.0 (0 reviews)', () {
      expect(AppHelpers.formatRatingDisplay(0.0, 0), '0.0 / 5.0 (0 reviews)');
      expect(AppHelpers.formatRatingDisplay(null, 0), '0.0 / 5.0 (0 reviews)');
      expect(AppHelpers.formatRatingDisplay(5.0, 0), '0.0 / 5.0 (0 reviews)');
      expect(AppHelpers.formatRatingDisplay(4.5, 2), '4.5 / 5.0 (2 reviews)');
      expect(AppHelpers.formatRatingDisplay(4.0, 3), '4.0 / 5.0 (3 reviews)');
      expect(AppHelpers.formatRatingDisplay(5.0, 1), '5.0 / 5.0 (1 review)');
    });

    test('4. Rating scale validation: rejects 0 and values outside 1-5', () async {
      final ratingZero = RatingModel(
        id: 'r0',
        transactionId: 'txn_test',
        fromUserId: 'user_a',
        fromUserName: 'User A',
        toUserId: 'user_b',
        rating: 0.0,
        review: 'Zero rating',
      );

      expect(
        () => ServiceRegistry.ratingService.submitRating(ratingZero),
        throwsA(isA<Exception>()),
      );

      final ratingSix = RatingModel(
        id: 'r6',
        transactionId: 'txn_test',
        fromUserId: 'user_a',
        fromUserName: 'User A',
        toUserId: 'user_b',
        rating: 6.0,
        review: 'Six rating',
      );

      expect(
        () => ServiceRegistry.ratingService.submitRating(ratingSix),
        throwsA(isA<Exception>()),
      );
    });

    test('5. Exact average calculation matching example progression (4 and 5 -> 4.5; 3, 4, 5 -> 4.0)', () async {
      final targetUser = UserModel(
        uid: 'target_user_1',
        fullName: 'Target Student',
        email: 'target@college.edu',
        ratingAverage: 0.0,
        ratingsCount: 0,
      );
      InMemoryStore.instance.users[targetUser.uid] = targetUser;

      // Initial state
      expect(targetUser.ratingAverage, 0.0);
      expect(targetUser.ratingsCount, 0);
      expect(
        AppHelpers.formatRatingDisplay(targetUser.ratingAverage, targetUser.ratingsCount),
        '0.0 / 5.0 (0 reviews)',
      );

      // Completed transaction 1
      final txn1 = TransactionModel(
        id: 'txn_1',
        requestId: 'req_1',
        itemId: 'item_1',
        itemName: 'Calculator',
        ownerId: targetUser.uid,
        ownerName: targetUser.fullName,
        borrowerId: 'borrower_1',
        borrowerName: 'Borrower 1',
        status: 'completed',
      );
      InMemoryStore.instance.transactions[txn1.id] = txn1;

      // Completed transaction 2
      final txn2 = TransactionModel(
        id: 'txn_2',
        requestId: 'req_2',
        itemId: 'item_2',
        itemName: 'Lab Coat',
        ownerId: targetUser.uid,
        ownerName: targetUser.fullName,
        borrowerId: 'borrower_2',
        borrowerName: 'Borrower 2',
        status: 'completed',
      );
      InMemoryStore.instance.transactions[txn2.id] = txn2;

      // Completed transaction 3
      final txn3 = TransactionModel(
        id: 'txn_3',
        requestId: 'req_3',
        itemId: 'item_3',
        itemName: 'Drafting Board',
        ownerId: targetUser.uid,
        ownerName: targetUser.fullName,
        borrowerId: 'borrower_3',
        borrowerName: 'Borrower 3',
        status: 'completed',
      );
      InMemoryStore.instance.transactions[txn3.id] = txn3;

      // Review 1: Rating of 4.0
      await ServiceRegistry.ratingService.submitRating(
        RatingModel(
          id: '',
          transactionId: txn1.id,
          fromUserId: 'borrower_1',
          fromUserName: 'Borrower 1',
          toUserId: targetUser.uid,
          rating: 4.0,
          review: 'Great lender',
        ),
      );

      var updated = InMemoryStore.instance.users[targetUser.uid]!;
      expect(updated.ratingAverage, 4.0);
      expect(updated.ratingsCount, 1);

      // Review 2: Rating of 5.0 -> Average of 4 and 5 must be 4.5
      await ServiceRegistry.ratingService.submitRating(
        RatingModel(
          id: '',
          transactionId: txn2.id,
          fromUserId: 'borrower_2',
          fromUserName: 'Borrower 2',
          toUserId: targetUser.uid,
          rating: 5.0,
          review: 'Very helpful',
        ),
      );

      updated = InMemoryStore.instance.users[targetUser.uid]!;
      expect(updated.ratingAverage, 4.5);
      expect(updated.ratingsCount, 2);
      expect(
        AppHelpers.formatRatingDisplay(updated.ratingAverage, updated.ratingsCount),
        '4.5 / 5.0 (2 reviews)',
      );

      // Review 3: Rating of 3.0 -> Average of 4, 5, and 3 must be (4+5+3)/3 = 4.0
      await ServiceRegistry.ratingService.submitRating(
        RatingModel(
          id: '',
          transactionId: txn3.id,
          fromUserId: 'borrower_3',
          fromUserName: 'Borrower 3',
          toUserId: targetUser.uid,
          rating: 3.0,
          review: 'Item was okay',
        ),
      );

      updated = InMemoryStore.instance.users[targetUser.uid]!;
      expect(updated.ratingAverage, 4.0);
      expect(updated.ratingsCount, 3);
      expect(
        AppHelpers.formatRatingDisplay(updated.ratingAverage, updated.ratingsCount),
        '4.0 / 5.0 (3 reviews)',
      );
    });

    test('6. Security: Rejects ratings on non-completed transactions', () async {
      final openTxn = TransactionModel(
        id: 'txn_open',
        requestId: 'req_open',
        itemId: 'item_open',
        itemName: 'Book',
        ownerId: 'owner_1',
        ownerName: 'Owner 1',
        borrowerId: 'borrower_1',
        borrowerName: 'Borrower 1',
        status: 'active', // Not completed yet
      );
      InMemoryStore.instance.transactions[openTxn.id] = openTxn;

      expect(
        () => ServiceRegistry.ratingService.submitRating(
          RatingModel(
            id: '',
            transactionId: openTxn.id,
            fromUserId: 'borrower_1',
            fromUserName: 'Borrower 1',
            toUserId: 'owner_1',
            rating: 5.0,
            review: 'Premature review',
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('7. Security: Rejects duplicate reviews from same participant for same transaction', () async {
      final txn = TransactionModel(
        id: 'txn_dup',
        requestId: 'req_dup',
        itemId: 'item_dup',
        itemName: 'Camera',
        ownerId: 'owner_1',
        ownerName: 'Owner 1',
        borrowerId: 'borrower_1',
        borrowerName: 'Borrower 1',
        status: 'completed',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;
      InMemoryStore.instance.users['owner_1'] = UserModel(
        uid: 'owner_1',
        fullName: 'Owner 1',
        email: 'owner@college.edu',
      );

      final rating1 = RatingModel(
        id: '',
        transactionId: txn.id,
        fromUserId: 'borrower_1',
        fromUserName: 'Borrower 1',
        toUserId: 'owner_1',
        rating: 5.0,
        review: 'First review',
      );

      await ServiceRegistry.ratingService.submitRating(rating1);

      // Second review for the same transaction by same user
      final rating2 = RatingModel(
        id: '',
        transactionId: txn.id,
        fromUserId: 'borrower_1',
        fromUserName: 'Borrower 1',
        toUserId: 'owner_1',
        rating: 4.0,
        review: 'Duplicate review',
      );

      expect(
        () => ServiceRegistry.ratingService.submitRating(rating2),
        throwsA(isA<Exception>()),
      );
    });
  });
}
