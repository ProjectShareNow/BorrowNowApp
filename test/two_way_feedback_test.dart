import 'package:flutter_test/flutter_test.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/models/rating_model.dart';
import 'package:borrow_now/models/transaction_model.dart';
import 'package:borrow_now/services/in_memory_store.dart';
import 'package:borrow_now/services/service_registry.dart';

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
    InMemoryStore.instance.notifications.clear();
  });

  group('Two-Way Ratings and Feedback Tests', () {
    test('1. Borrower reviews lender after transaction completion', () async {
      final lender = UserModel(
        uid: 'lender_1',
        fullName: 'Alice Lender',
        email: 'alice@college.edu',
        registerNumber: 'CE20CS1001',
      );
      final borrower = UserModel(
        uid: 'borrower_1',
        fullName: 'Bob Borrower',
        email: 'bob@college.edu',
        registerNumber: 'CE20CS1002',
      );
      InMemoryStore.instance.users['lender_1'] = lender;
      InMemoryStore.instance.users['borrower_1'] = borrower;

      final txn = TransactionModel(
        id: 'txn_100',
        requestId: 'req_100',
        itemId: 'item_100',
        itemName: 'Scientific Calculator',
        borrowerId: 'borrower_1',
        borrowerName: 'Bob Borrower',
        ownerId: 'lender_1',
        ownerName: 'Alice Lender',
        status: 'completed',
      );
      InMemoryStore.instance.transactions['txn_100'] = txn;

      final borrowerReview = RatingModel(
        transactionId: 'txn_100',
        requestId: 'req_100',
        itemId: 'item_100',
        reviewerId: 'borrower_1',
        reviewerName: 'Bob Borrower',
        revieweeId: 'lender_1',
        reviewerRole: 'borrower',
        rating: 5.0,
        feedback: 'Super helpful and on time!',
      );

      await ServiceRegistry.ratingService.submitRating(borrowerReview);

      // Verify stored review
      final review = await ServiceRegistry.ratingService.getReviewForTransaction(
        transactionId: 'txn_100',
        userId: 'borrower_1',
      );
      expect(review, isNotNull);
      expect(review!.rating, 5.0);
      expect(review.feedback, 'Super helpful and on time!');
      expect(review.reviewerRole, 'borrower');

      // Verify transaction flag
      final updatedTxn = InMemoryStore.instance.transactions['txn_100']!;
      expect(updatedTxn.borrowerRated, isTrue);
      expect(updatedTxn.lenderRated, isFalse);
      expect(updatedTxn.hasUserRated('borrower_1'), isTrue);
      expect(updatedTxn.hasOtherPartyRated('borrower_1'), isFalse);
      expect(updatedTxn.hasOtherPartyRated('lender_1'), isTrue);

      // Verify reviewee rating updated
      final updatedLender = InMemoryStore.instance.users['lender_1']!;
      expect(updatedLender.ratingsCount, 1);
      expect(updatedLender.ratingAverage, 5.0);
    });

    test('2. Lender reviews borrower after transaction completion', () async {
      final lender = UserModel(
        uid: 'lender_2',
        fullName: 'Carol Lender',
        email: 'carol@college.edu',
      );
      final borrower = UserModel(
        uid: 'borrower_2',
        fullName: 'Dave Borrower',
        email: 'dave@college.edu',
      );
      InMemoryStore.instance.users['lender_2'] = lender;
      InMemoryStore.instance.users['borrower_2'] = borrower;

      final txn = TransactionModel(
        id: 'txn_200',
        requestId: 'req_200',
        itemId: 'item_200',
        itemName: 'Lab Coat',
        borrowerId: 'borrower_2',
        borrowerName: 'Dave Borrower',
        ownerId: 'lender_2',
        ownerName: 'Carol Lender',
        status: 'completed',
      );
      InMemoryStore.instance.transactions['txn_200'] = txn;

      final lenderReview = RatingModel(
        transactionId: 'txn_200',
        requestId: 'req_200',
        itemId: 'item_200',
        reviewerId: 'lender_2',
        reviewerName: 'Carol Lender',
        revieweeId: 'borrower_2',
        reviewerRole: 'lender',
        rating: 4.0,
        feedback: 'Returned item in clean condition.',
      );

      await ServiceRegistry.ratingService.submitRating(lenderReview);

      final updatedTxn = InMemoryStore.instance.transactions['txn_200']!;
      expect(updatedTxn.lenderRated, isTrue);
      expect(updatedTxn.borrowerRated, isFalse);
      expect(updatedTxn.hasUserRated('lender_2'), isTrue);
      expect(updatedTxn.hasUserRated('borrower_2'), isFalse);

      final updatedBorrower = InMemoryStore.instance.users['borrower_2']!;
      expect(updatedBorrower.ratingsCount, 1);
      expect(updatedBorrower.ratingAverage, 4.0);
    });

    test('3. Both participants review each other independently', () async {
      final lender = UserModel(
        uid: 'lender_3',
        fullName: 'Lender 3',
        email: 'l3@college.edu',
      );
      final borrower = UserModel(
        uid: 'borrower_3',
        fullName: 'Borrower 3',
        email: 'b3@college.edu',
      );
      InMemoryStore.instance.users['lender_3'] = lender;
      InMemoryStore.instance.users['borrower_3'] = borrower;

      final txn = TransactionModel(
        id: 'txn_300',
        requestId: 'req_300',
        itemId: 'item_300',
        itemName: 'Arduino Board',
        borrowerId: 'borrower_3',
        borrowerName: 'Borrower 3',
        ownerId: 'lender_3',
        ownerName: 'Lender 3',
        status: 'completed',
      );
      InMemoryStore.instance.transactions['txn_300'] = txn;

      // Borrower reviews Lender
      await ServiceRegistry.ratingService.submitRating(
        RatingModel(
          transactionId: 'txn_300',
          requestId: 'req_300',
          itemId: 'item_300',
          reviewerId: 'borrower_3',
          reviewerName: 'Borrower 3',
          revieweeId: 'lender_3',
          reviewerRole: 'borrower',
          rating: 4.0,
          feedback: 'Great component!',
        ),
      );

      // Lender reviews Borrower
      await ServiceRegistry.ratingService.submitRating(
        RatingModel(
          transactionId: 'txn_300',
          requestId: 'req_300',
          itemId: 'item_300',
          reviewerId: 'lender_3',
          reviewerName: 'Lender 3',
          revieweeId: 'borrower_3',
          reviewerRole: 'lender',
          rating: 5.0,
          feedback: 'Returned on time and tested.',
        ),
      );

      final updatedTxn = InMemoryStore.instance.transactions['txn_300']!;
      expect(updatedTxn.borrowerRated, isTrue);
      expect(updatedTxn.lenderRated, isTrue);
      expect(updatedTxn.hasUserRated('borrower_3'), isTrue);
      expect(updatedTxn.hasOtherPartyRated('borrower_3'), isTrue);
      expect(updatedTxn.hasUserRated('lender_3'), isTrue);
      expect(updatedTxn.hasOtherPartyRated('lender_3'), isTrue);

      final reviews = await ServiceRegistry.ratingService.getTransactionReviews('txn_300');
      expect(reviews.length, 2);
    });

    test('4. Prevent duplicate review submission for the same participant', () async {
      final lender = UserModel(uid: 'lender_4', fullName: 'L4', email: 'l4@college.edu');
      final borrower = UserModel(uid: 'borrower_4', fullName: 'B4', email: 'b4@college.edu');
      InMemoryStore.instance.users['lender_4'] = lender;
      InMemoryStore.instance.users['borrower_4'] = borrower;

      final txn = TransactionModel(
        id: 'txn_400',
        requestId: 'req_400',
        itemId: 'item_400',
        itemName: 'Textbook',
        borrowerId: 'borrower_4',
        borrowerName: 'B4',
        ownerId: 'lender_4',
        ownerName: 'L4',
        status: 'completed',
      );
      InMemoryStore.instance.transactions['txn_400'] = txn;

      final review = RatingModel(
        transactionId: 'txn_400',
        requestId: 'req_400',
        itemId: 'item_400',
        reviewerId: 'borrower_4',
        reviewerName: 'B4',
        revieweeId: 'lender_4',
        reviewerRole: 'borrower',
        rating: 5.0,
        feedback: 'First review',
      );

      // First submission succeeds
      await ServiceRegistry.ratingService.submitRating(review);

      // Second submission should be rejected
      expect(
        () => ServiceRegistry.ratingService.submitRating(
          review.copyWith(feedback: 'Attempt duplicate review'),
        ),
        throwsA(isA<Exception>()),
      );

      // Ensure review count didn't increment twice
      final updatedLender = InMemoryStore.instance.users['lender_4']!;
      expect(updatedLender.ratingsCount, 1);
    });

    test('5. Reject review when transaction is not completed (scheduled/active/cancelled)', () async {
      final txnActive = TransactionModel(
        id: 'txn_500',
        requestId: 'req_500',
        itemId: 'item_500',
        itemName: 'Drafter',
        borrowerId: 'borrower_5',
        borrowerName: 'B5',
        ownerId: 'lender_5',
        ownerName: 'L5',
        status: 'active',
      );
      InMemoryStore.instance.transactions['txn_500'] = txnActive;

      final review = RatingModel(
        transactionId: 'txn_500',
        requestId: 'req_500',
        itemId: 'item_500',
        reviewerId: 'borrower_5',
        reviewerName: 'B5',
        revieweeId: 'lender_5',
        reviewerRole: 'borrower',
        rating: 5.0,
      );

      expect(
        () => ServiceRegistry.ratingService.submitRating(review),
        throwsA(isA<Exception>()),
      );

      final txnCancelled = txnActive.copyWith(id: 'txn_501', status: 'cancelled');
      InMemoryStore.instance.transactions['txn_501'] = txnCancelled;

      expect(
        () => ServiceRegistry.ratingService.submitRating(
          review.copyWith(transactionId: 'txn_501'),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('6. Reject self-rating or review for unrelated user', () async {
      final txn = TransactionModel(
        id: 'txn_600',
        requestId: 'req_600',
        itemId: 'item_600',
        itemName: 'Microcontroller',
        borrowerId: 'borrower_6',
        borrowerName: 'B6',
        ownerId: 'lender_6',
        ownerName: 'L6',
        status: 'completed',
      );
      InMemoryStore.instance.transactions['txn_600'] = txn;

      // Self-rating attempt
      final selfReview = RatingModel(
        transactionId: 'txn_600',
        requestId: 'req_600',
        itemId: 'item_600',
        reviewerId: 'borrower_6',
        reviewerName: 'B6',
        revieweeId: 'borrower_6',
        reviewerRole: 'borrower',
        rating: 5.0,
      );

      expect(
        () => ServiceRegistry.ratingService.submitRating(selfReview),
        throwsA(isA<Exception>()),
      );

      // Unrelated user attempt
      final unrelatedReview = RatingModel(
        transactionId: 'txn_600',
        requestId: 'req_600',
        itemId: 'item_600',
        reviewerId: 'stranger_user',
        reviewerName: 'Stranger',
        revieweeId: 'lender_6',
        reviewerRole: 'borrower',
        rating: 5.0,
      );

      expect(
        () => ServiceRegistry.ratingService.submitRating(unrelatedReview),
        throwsA(isA<Exception>()),
      );
    });

    test('7. Reject invalid ratings (0, negative, >5)', () async {
      final txn = TransactionModel(
        id: 'txn_700',
        requestId: 'req_700',
        itemId: 'item_700',
        itemName: 'Router',
        borrowerId: 'borrower_7',
        borrowerName: 'B7',
        ownerId: 'lender_7',
        ownerName: 'L7',
        status: 'completed',
      );
      InMemoryStore.instance.transactions['txn_700'] = txn;

      expect(
        () => ServiceRegistry.ratingService.submitRating(
          RatingModel(
            transactionId: 'txn_700',
            requestId: 'req_700',
            itemId: 'item_700',
            reviewerId: 'borrower_7',
            reviewerName: 'B7',
            revieweeId: 'lender_7',
            reviewerRole: 'borrower',
            rating: 0.0,
          ),
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => ServiceRegistry.ratingService.submitRating(
          RatingModel(
            transactionId: 'txn_700',
            requestId: 'req_700',
            itemId: 'item_700',
            reviewerId: 'borrower_7',
            reviewerName: 'B7',
            revieweeId: 'lender_7',
            reviewerRole: 'borrower',
            rating: 6.0,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('8. Rating average calculated correctly across multiple reviews', () async {
      final lender = UserModel(
        uid: 'lender_8',
        fullName: 'L8',
        email: 'l8@college.edu',
      );
      InMemoryStore.instance.users['lender_8'] = lender;

      // Transaction 1
      final txn1 = TransactionModel(
        id: 'txn_801',
        requestId: 'req_801',
        itemId: 'item_801',
        itemName: 'Item 1',
        borrowerId: 'b_1',
        borrowerName: 'B1',
        ownerId: 'lender_8',
        ownerName: 'L8',
        status: 'completed',
      );
      InMemoryStore.instance.transactions['txn_801'] = txn1;

      // Transaction 2
      final txn2 = TransactionModel(
        id: 'txn_802',
        requestId: 'req_802',
        itemId: 'item_802',
        itemName: 'Item 2',
        borrowerId: 'b_2',
        borrowerName: 'B2',
        ownerId: 'lender_8',
        ownerName: 'L8',
        status: 'completed',
      );
      InMemoryStore.instance.transactions['txn_802'] = txn2;

      // Transaction 3
      final txn3 = TransactionModel(
        id: 'txn_803',
        requestId: 'req_803',
        itemId: 'item_803',
        itemName: 'Item 3',
        borrowerId: 'b_3',
        borrowerName: 'B3',
        ownerId: 'lender_8',
        ownerName: 'L8',
        status: 'completed',
      );
      InMemoryStore.instance.transactions['txn_803'] = txn3;

      // Rating 1: 5 stars
      await ServiceRegistry.ratingService.submitRating(
        RatingModel(
          transactionId: 'txn_801',
          requestId: 'req_801',
          itemId: 'item_801',
          reviewerId: 'b_1',
          reviewerName: 'B1',
          revieweeId: 'lender_8',
          reviewerRole: 'borrower',
          rating: 5.0,
        ),
      );
      expect(InMemoryStore.instance.users['lender_8']!.ratingAverage, 5.0);
      expect(InMemoryStore.instance.users['lender_8']!.ratingsCount, 1);

      // Rating 2: 4 stars -> (5 + 4) / 2 = 4.5
      await ServiceRegistry.ratingService.submitRating(
        RatingModel(
          transactionId: 'txn_802',
          requestId: 'req_802',
          itemId: 'item_802',
          reviewerId: 'b_2',
          reviewerName: 'B2',
          revieweeId: 'lender_8',
          reviewerRole: 'borrower',
          rating: 4.0,
        ),
      );
      expect(InMemoryStore.instance.users['lender_8']!.ratingAverage, 4.5);
      expect(InMemoryStore.instance.users['lender_8']!.ratingsCount, 2);

      // Rating 3: 3 stars -> (5 + 4 + 3) / 3 = 4.0
      await ServiceRegistry.ratingService.submitRating(
        RatingModel(
          transactionId: 'txn_803',
          requestId: 'req_803',
          itemId: 'item_803',
          reviewerId: 'b_3',
          reviewerName: 'B3',
          revieweeId: 'lender_8',
          reviewerRole: 'borrower',
          rating: 3.0,
        ),
      );
      expect(InMemoryStore.instance.users['lender_8']!.ratingAverage, 4.0);
      expect(InMemoryStore.instance.users['lender_8']!.ratingsCount, 3);
    });

    test('9. Feedback notifications sent to reviewee upon review submission', () async {
      final lender = UserModel(
        uid: 'lender_9',
        fullName: 'L9',
        email: 'l9@college.edu',
      );
      InMemoryStore.instance.users['lender_9'] = lender;

      final txn = TransactionModel(
        id: 'txn_900',
        requestId: 'req_900',
        itemId: 'item_900',
        itemName: 'Physics Textbook',
        borrowerId: 'borrower_9',
        borrowerName: 'Student Bob',
        ownerId: 'lender_9',
        ownerName: 'L9',
        status: 'completed',
      );
      InMemoryStore.instance.transactions['txn_900'] = txn;

      await ServiceRegistry.ratingService.submitRating(
        RatingModel(
          transactionId: 'txn_900',
          requestId: 'req_900',
          itemId: 'item_900',
          reviewerId: 'borrower_9',
          reviewerName: 'Student Bob',
          revieweeId: 'lender_9',
          reviewerRole: 'borrower',
          rating: 5.0,
          feedback: 'Book in excellent shape!',
        ),
      );

      final notifs = InMemoryStore.instance.notifications.values
          .where((n) => n.userId == 'lender_9')
          .toList();
      expect(notifs.isNotEmpty, isTrue);
      final ratingNotif = notifs.firstWhere((n) => n.type == 'rating_received');
      expect(ratingNotif.title, contains('New Review Received'));
      expect(ratingNotif.message, contains('Student Bob'));
      expect(ratingNotif.message, contains('Physics Textbook'));
      expect(ratingNotif.message, contains('5-star rating'));
    });

    test('10. Feedback request notifications sent to both borrower and lender on return completion', () async {
      final lender = UserModel(uid: 'lender_10', fullName: 'L10', email: 'l10@college.edu');
      final borrower = UserModel(uid: 'borrower_10', fullName: 'B10', email: 'b10@college.edu');
      InMemoryStore.instance.users['lender_10'] = lender;
      InMemoryStore.instance.users['borrower_10'] = borrower;

      final txn = TransactionModel(
        id: 'txn_1000',
        requestId: 'req_1000',
        itemId: 'item_1000',
        itemName: 'Soldering Iron',
        borrowerId: 'borrower_10',
        borrowerName: 'B10',
        ownerId: 'lender_10',
        ownerName: 'L10',
        status: 'return_requested',
        returnIdentityVerified: true,
        returnPhotoUrl: 'https://example.com/photo.jpg',
      );
      InMemoryStore.instance.transactions['txn_1000'] = txn;

      await ServiceRegistry.transactionService.confirmReturnAndComplete(
        transactionId: 'txn_1000',
        currentUserId: 'lender_10',
      );

      final borrowerNotifs = InMemoryStore.instance.notifications.values
          .where((n) => n.recipientId == 'borrower_10' && n.type == 'feedback_request')
          .toList();
      final lenderNotifs = InMemoryStore.instance.notifications.values
          .where((n) => n.recipientId == 'lender_10' && n.type == 'feedback_request')
          .toList();

      expect(borrowerNotifs.isNotEmpty, isTrue);
      expect(lenderNotifs.isNotEmpty, isTrue);
      expect(borrowerNotifs.first.title, contains('Leave Feedback'));
      expect(lenderNotifs.first.title, contains('Leave Feedback'));
      expect(borrowerNotifs.first.relatedId, 'txn_1000');
      expect(lenderNotifs.first.relatedId, 'txn_1000');
    });
  });
}
