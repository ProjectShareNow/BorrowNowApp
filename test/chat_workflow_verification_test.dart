import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:borrow_now/providers/auth_provider.dart';
import 'package:borrow_now/providers/chat_provider.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/models/item_model.dart';
import 'package:borrow_now/models/borrow_request_model.dart';
import 'package:borrow_now/models/chat_model.dart';
import 'package:borrow_now/models/transaction_model.dart';
import 'package:borrow_now/services/service_registry.dart';
import 'package:borrow_now/services/in_memory_store.dart';
import 'package:borrow_now/screens/chat/chat_screen.dart';

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
  });

  group('BorrowNow Live Identity Verification & Return Workflow Service Tests', () {
    test('Lender verifies borrower identity with correct register number', () async {
      final borrower = UserModel(
        uid: 'borrower_1',
        email: 'borrower@college.edu',
        fullName: 'Aarav Borrower',
        registerNumber: '710021104001',
      );
      final lender = UserModel(
        uid: 'lender_1',
        email: 'lender@college.edu',
        fullName: 'Diya Lender',
        registerNumber: '710021104050',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final txn = TransactionModel(
        id: 'txn_101',
        requestId: 'req_101',
        itemId: 'item_101',
        itemName: 'Scientific Calculator',
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        status: 'scheduled',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // 1. Borrower cannot self-verify
      expect(
        () => ServiceRegistry.transactionService.verifyBorrowerIdentity(
          transactionId: txn.id,
          lenderId: borrower.uid,
          enteredRegisterNumber: '710021104001',
        ),
        throwsA(predicate((e) => e.toString().contains('Unauthorized'))),
      );

      // 2. Incorrect register number fails
      expect(
        () => ServiceRegistry.transactionService.verifyBorrowerIdentity(
          transactionId: txn.id,
          lenderId: lender.uid,
          enteredRegisterNumber: '999999999999',
        ),
        throwsA(predicate((e) =>
            e.toString().contains('does not match the borrower') ||
            e.toString().contains('does not match borrower'))),
      );

      // 3. Correct register number (with spaces and case normalization) succeeds
      final verified = await ServiceRegistry.transactionService.verifyBorrowerIdentity(
        transactionId: txn.id,
        lenderId: lender.uid,
        enteredRegisterNumber: '  710021104001  ',
      );
      expect(verified, isTrue);

      final updatedTxn = InMemoryStore.instance.transactions[txn.id]!;
      expect(updatedTxn.handoverIdentityVerified, isTrue);
      expect(updatedTxn.handoverVerifiedBy, lender.uid);
      expect(updatedTxn.handoverVerifiedAt, isNotNull);
    });

    test('Complete Handover cycle: Identity verification -> Photo upload -> Handover confirmation', () async {
      final borrower = UserModel(
        uid: 'borrower_2',
        email: 'b2@college.edu',
        fullName: 'Rahul Borrower',
        registerNumber: 'REG_B_123',
      );
      final lender = UserModel(
        uid: 'lender_2',
        email: 'l2@college.edu',
        fullName: 'Priya Lender',
        registerNumber: 'REG_L_456',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final item = ItemModel(
        id: 'item_202',
        name: 'Lab Apron',
        category: 'Lab',
        description: 'Cotton lab apron',
        condition: 'good',
        pickupLocation: 'Chemistry Lab',
        ownerId: lender.uid,
        ownerName: lender.fullName,
        availability: 'reserved',
      );
      InMemoryStore.instance.items[item.id] = item;

      final request = BorrowRequestModel(
        id: 'req_202',
        itemId: item.id,
        itemName: item.name,
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        pickupLocation: 'Chemistry Lab',
        status: 'approved',
      );
      InMemoryStore.instance.requests[request.id] = request;

      final txn = TransactionModel(
        id: 'txn_202',
        requestId: request.id,
        itemId: item.id,
        itemName: item.name,
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        status: 'scheduled',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // Cannot confirm handover before verification and photo
      expect(
        () => ServiceRegistry.transactionService.confirmItemHandover(
          transactionId: txn.id,
          lenderId: lender.uid,
        ),
        throwsA(predicate((e) => e.toString().contains('Borrower identity has not been verified'))),
      );

      // Verify identity
      await ServiceRegistry.transactionService.verifyBorrowerIdentity(
        transactionId: txn.id,
        lenderId: lender.uid,
        enteredRegisterNumber: 'reg_b_123',
      );

      // Cannot confirm photo if not lender
      expect(
        () => ServiceRegistry.transactionService.confirmHandoverPhoto(
          transactionId: txn.id,
          lenderId: borrower.uid,
          photoUrl: 'https://example.com/handover.jpg',
          storagePath: 'handover_evidence/txn_202/handover.jpg',
        ),
        throwsA(predicate((e) => e.toString().contains('Unauthorized'))),
      );

      // Lender confirms handover photo
      await ServiceRegistry.transactionService.confirmHandoverPhoto(
        transactionId: txn.id,
        lenderId: lender.uid,
        photoUrl: 'https://example.com/handover.jpg',
        storagePath: 'handover_evidence/txn_202/handover.jpg',
      );

      // Lender confirms handover
      await ServiceRegistry.transactionService.confirmItemHandover(
        transactionId: txn.id,
        lenderId: lender.uid,
      );

      final activeTxn = InMemoryStore.instance.transactions[txn.id]!;
      expect(activeTxn.status, 'active');
      expect(activeTxn.handoverConfirmed, isTrue);
      expect(activeTxn.pickupConfirmed, isTrue);

      // Check item and request consistency
      expect(InMemoryStore.instance.items[item.id]!.availability, 'borrowed');
      expect(InMemoryStore.instance.requests[request.id]!.status, 'active');
    });

    test('Complete Return workflow: Request return -> Lender ID verification -> Fresh photo -> Condition check & complete', () async {
      final borrower = UserModel(
        uid: 'borrower_3',
        email: 'b3@college.edu',
        fullName: 'Kiran Borrower',
        registerNumber: 'REG_B_333',
        borrowedCount: 2,
      );
      final lender = UserModel(
        uid: 'lender_3',
        email: 'l3@college.edu',
        fullName: 'Ananya Lender',
        registerNumber: 'REG_L_999',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final item = ItemModel(
        id: 'item_303',
        name: 'Arduino Kit',
        category: 'Electronics',
        description: 'Arduino Uno starter kit',
        condition: 'good',
        pickupLocation: 'Tech Park',
        ownerId: lender.uid,
        ownerName: lender.fullName,
        availability: 'borrowed',
      );
      InMemoryStore.instance.items[item.id] = item;

      final request = BorrowRequestModel(
        id: 'req_303',
        itemId: item.id,
        itemName: item.name,
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        pickupLocation: 'Tech Park',
        status: 'active',
      );
      InMemoryStore.instance.requests[request.id] = request;

      final txn = TransactionModel(
        id: 'txn_303',
        requestId: request.id,
        itemId: item.id,
        itemName: item.name,
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        handoverIdentityVerified: true,
        handoverPhotoUrl: 'https://example.com/handover303.jpg',
        handoverConfirmed: true,
        status: 'active',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // 1. Borrower requests return
      await ServiceRegistry.transactionService.requestReturn(
        transactionId: txn.id,
        currentUserId: borrower.uid,
      );

      var updated = InMemoryStore.instance.transactions[txn.id]!;
      expect(updated.status, 'return_requested');
      expect(updated.returnRequestedAt, isNotNull);

      // 2. Borrower verifies lender's register number (person receiving item back)
      // Incorrect number fails
      expect(
        () => ServiceRegistry.transactionService.verifyLenderIdentityForReturn(
          transactionId: txn.id,
          borrowerId: borrower.uid,
          enteredRegisterNumber: 'WRONG_REG',
        ),
        throwsA(predicate((e) =>
            e.toString().contains('does not match the lender') ||
            e.toString().contains('does not match lender'))),
      );

      // Correct number succeeds
      await ServiceRegistry.transactionService.verifyLenderIdentityForReturn(
        transactionId: txn.id,
        borrowerId: borrower.uid,
        enteredRegisterNumber: 'reg_l_999',
      );

      updated = InMemoryStore.instance.transactions[txn.id]!;
      expect(updated.returnIdentityVerified, isTrue);
      expect(updated.returnVerifiedBy, borrower.uid);

      // 3. Fresh photo required: cannot reuse handover photo!
      expect(
        () => ServiceRegistry.transactionService.confirmReturnPhoto(
          transactionId: txn.id,
          currentUserId: borrower.uid,
          photoUrl: 'https://example.com/handover303.jpg', // Same as handover
          storagePath: 'same_path',
        ),
        throwsA(predicate((e) => e.toString().contains('fresh return photo must be captured'))),
      );

      // Fresh return photo uploads cleanly
      await ServiceRegistry.transactionService.confirmReturnPhoto(
        transactionId: txn.id,
        currentUserId: borrower.uid,
        photoUrl: 'https://example.com/return_fresh_303.jpg',
        storagePath: 'return_evidence/txn_303/fresh.jpg',
      );

      // 4. Lender confirms condition & completes return
      await ServiceRegistry.transactionService.confirmReturnAndComplete(
        transactionId: txn.id,
        currentUserId: lender.uid,
        returnCondition: 'good',
        damageReported: false,
      );

      final completedTxn = InMemoryStore.instance.transactions[txn.id]!;
      expect(completedTxn.status, 'completed');
      expect(completedTxn.isCompleted, isTrue);
      expect(completedTxn.returnedAt, isNotNull);
      expect(completedTxn.returnCondition, 'good');

      // Check item availability is back to available
      expect(InMemoryStore.instance.items[item.id]!.availability, 'available');
      // Check request status is returned
      expect(InMemoryStore.instance.requests[request.id]!.status, 'returned');
      // Check borrower borrowedCount incremented from 2 to 3
      expect(InMemoryStore.instance.users[borrower.uid]!.borrowedCount, 3);
    });
  });

  group('ChatScreen UI Workflow Tests', () {
    testWidgets('ChatScreen shows Borrower Identity Verification panel for scheduled transaction',
        (tester) async {
      final borrower = UserModel(
        uid: 'user_u1',
        email: 'u1@college.edu',
        fullName: 'Kavya Borrower',
        registerNumber: '710022104005',
      );
      final lender = UserModel(
        uid: 'user_u2',
        email: 'u2@college.edu',
        fullName: 'Vikram Lender',
        registerNumber: '710022104099',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final chat = ChatModel(
        id: 'chat_flow_1',
        requestId: 'req_flow_1',
        itemId: 'item_flow_1',
        itemName: 'Engineering Drafter',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: [borrower.uid, lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_flow_1',
        requestId: chat.requestId,
        itemId: chat.itemId,
        itemName: chat.itemName,
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        status: 'scheduled',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // Pump as Lender
      await ServiceRegistry.authService.login(email: lender.email, password: 'any');
      final authProvider = AuthProvider();
      final chatProvider = ChatProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
          ],
          child: MaterialApp(
            home: ChatScreen(chatId: chat.id),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Identity Verification section is visible
      expect(find.text('Identity Verification'), findsOneWidget);
      expect(find.text('Registered Student: Kavya Borrower'), findsOneWidget);
      expect(find.text('Verify Reg No'), findsOneWidget);

      // Enter register number and verify
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter Register Number'),
        '710022104005',
      );
      await tester.tap(find.text('Verify Reg No'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check success state
      expect(find.text('Register number verified successfully! ✅'), findsOneWidget);
      expect(find.text('Verified ✅'), findsWidgets);
    });
  });
}
