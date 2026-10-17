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

  group('BorrowNow Chat Identity Verification & Return Workflow Tests', () {
    test('Handover identity verification with correct, incorrect, and masked format', () async {
      final borrower = UserModel(
        uid: 'b_student_1',
        email: 'borrower@college.edu',
        fullName: 'Aarav Kumar',
        registerNumber: 'CE20CS1234',
      );
      final lender = UserModel(
        uid: 'l_student_1',
        email: 'lender@college.edu',
        fullName: 'Diya Sharma',
        registerNumber: 'CE20CS5678',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final txn = TransactionModel(
        id: 'txn_flow_test_1',
        requestId: 'req_flow_test_1',
        itemId: 'item_flow_test_1',
        itemName: 'Digital Multimeter',
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        status: 'scheduled',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // 1. Borrower cannot self-verify handover
      expect(
        () => ServiceRegistry.transactionService.verifyBorrowerIdentity(
          transactionId: txn.id,
          lenderId: borrower.uid,
          enteredRegisterNumber: 'CE20CS1234',
        ),
        throwsA(predicate((e) => e.toString().contains('Unauthorized'))),
      );

      // 2. Incorrect register number fails
      expect(
        () => ServiceRegistry.transactionService.verifyBorrowerIdentity(
          transactionId: txn.id,
          lenderId: lender.uid,
          enteredRegisterNumber: 'WRONGREGNUM',
        ),
        throwsA(predicate((e) =>
            e.toString().contains('does not match the borrower') ||
            e.toString().contains('does not match borrower'))),
      );

      // 3. Correct register number succeeds and sets masked register number
      final verified = await ServiceRegistry.transactionService.verifyBorrowerIdentity(
        transactionId: txn.id,
        lenderId: lender.uid,
        enteredRegisterNumber: 'CE20CS1234',
      );
      expect(verified, isTrue);

      final updatedTxn = InMemoryStore.instance.transactions[txn.id]!;
      expect(updatedTxn.handoverIdentityVerified, isTrue);
      expect(updatedTxn.handoverVerifiedBy, lender.uid);
      expect(updatedTxn.handoverVerifiedAt, isNotNull);
      // Verify masking: CE20CS1234 -> CE20CS1***
      expect(updatedTxn.maskedBorrowerRegisterNumber, 'CE20CS1***');
    });

    test('Return identity verification with correct, incorrect, and masked format', () async {
      final borrower = UserModel(
        uid: 'b_student_2',
        email: 'b2@college.edu',
        fullName: 'Rohan Verma',
        registerNumber: 'ME21ME1111',
      );
      final lender = UserModel(
        uid: 'l_student_2',
        email: 'l2@college.edu',
        fullName: 'Sneha Patel',
        registerNumber: 'EC21EC9999',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final txn = TransactionModel(
        id: 'txn_flow_test_2',
        requestId: 'req_flow_test_2',
        itemId: 'item_flow_test_2',
        itemName: 'Arduino Board',
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        handoverIdentityVerified: true,
        handoverPhotoUrl: 'https://example.com/handover.jpg',
        handoverConfirmed: true,
        status: 'return_requested',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // 1. Lender cannot verify themselves during return
      expect(
        () => ServiceRegistry.transactionService.verifyLenderIdentityForReturn(
          transactionId: txn.id,
          borrowerId: lender.uid,
          enteredRegisterNumber: 'EC21EC9999',
        ),
        throwsA(predicate((e) => e.toString().contains('Unauthorized'))),
      );

      // 2. Incorrect register number fails
      expect(
        () => ServiceRegistry.transactionService.verifyLenderIdentityForReturn(
          transactionId: txn.id,
          borrowerId: borrower.uid,
          enteredRegisterNumber: 'EC21EC0000',
        ),
        throwsA(predicate((e) =>
            e.toString().contains('does not match the lender') ||
            e.toString().contains('does not match lender'))),
      );

      // 3. Correct register number succeeds and sets masked register number
      final verified = await ServiceRegistry.transactionService.verifyLenderIdentityForReturn(
        transactionId: txn.id,
        borrowerId: borrower.uid,
        enteredRegisterNumber: 'EC21EC9999',
      );
      expect(verified, isTrue);

      final updatedTxn = InMemoryStore.instance.transactions[txn.id]!;
      expect(updatedTxn.returnIdentityVerified, isTrue);
      expect(updatedTxn.returnVerifiedBy, borrower.uid);
      expect(updatedTxn.returnVerifiedAt, isNotNull);
      // Verify masking: EC21EC9999 -> EC21EC9***
      expect(updatedTxn.maskedLenderRegisterNumber, 'EC21EC9***');
    });

    test('Damaged item handling does not automatically mark item as available', () async {
      final borrower = UserModel(
        uid: 'b_student_3',
        email: 'b3@college.edu',
        fullName: 'Gokul Borrower',
        registerNumber: 'CS22CS3333',
      );
      final lender = UserModel(
        uid: 'l_student_3',
        email: 'l3@college.edu',
        fullName: 'Pavithran Lender',
        registerNumber: 'CS22CS4444',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final item = ItemModel(
        id: 'item_flow_test_3',
        name: 'Oscilloscope Probe',
        category: 'Lab',
        description: 'Precision probe',
        condition: 'good',
        pickupLocation: 'Electronics Lab',
        ownerId: lender.uid,
        ownerName: lender.fullName,
        availability: 'borrowed',
      );
      InMemoryStore.instance.items[item.id] = item;

      final req = BorrowRequestModel(
        id: 'req_flow_test_3',
        itemId: item.id,
        itemName: item.name,
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        pickupLocation: 'Electronics Lab',
        status: 'active',
      );
      InMemoryStore.instance.requests[req.id] = req;

      final txn = TransactionModel(
        id: 'txn_flow_test_3',
        requestId: req.id,
        itemId: item.id,
        itemName: item.name,
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        handoverIdentityVerified: true,
        handoverPhotoUrl: 'https://example.com/handover3.jpg',
        handoverConfirmed: true,
        status: 'return_requested',
        returnIdentityVerified: true,
        returnPhotoUrl: 'https://example.com/return3.jpg',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // Borrower confirms hand-back
      await ServiceRegistry.transactionService.confirmBorrowerReturnHandback(
        transactionId: txn.id,
        borrowerId: borrower.uid,
      );
      expect(InMemoryStore.instance.transactions[txn.id]!.borrowerReturnConfirmed, isTrue);

      // Lender confirms return with damaged status
      await ServiceRegistry.transactionService.confirmReturnAndComplete(
        transactionId: txn.id,
        currentUserId: lender.uid,
        returnCondition: 'damaged',
        damageReported: true,
        damageDetails: 'Probe tip broken',
      );

      final completedTxn = InMemoryStore.instance.transactions[txn.id]!;
      expect(completedTxn.status, 'completed');
      expect(completedTxn.damageReported, isTrue);
      expect(completedTxn.damageDetails, 'Probe tip broken');
      expect(completedTxn.completedAt, isNotNull);

      // Item must NOT be marked as 'available'; it must be 'inactive' and condition 'damaged'
      final updatedItem = InMemoryStore.instance.items[item.id]!;
      expect(updatedItem.availability, 'inactive');
      expect(updatedItem.condition, 'damaged');
    });

    testWidgets('ChatScreen shows Identity Verification card with Enter Register Number field and Verify Identity button',
        (tester) async {
      final borrower = UserModel(
        uid: 'user_widget_b',
        email: 'wb@college.edu',
        fullName: 'Kavya Borrower',
        registerNumber: 'CE20CS1234',
      );
      final lender = UserModel(
        uid: 'user_widget_l',
        email: 'wl@college.edu',
        fullName: 'Vikram Lender',
        registerNumber: 'CE20CS5678',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final chat = ChatModel(
        id: 'chat_widget_1',
        requestId: 'req_widget_1',
        itemId: 'item_widget_1',
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
        id: 'txn_widget_1',
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

      // Verify Identity Verification card header
      expect(find.text('Identity Verification'), findsOneWidget);
      expect(find.text('Registered Student: Kavya Borrower'), findsOneWidget);

      // Verify "Enter Register Number" label/hint
      expect(find.widgetWithText(TextField, 'Enter Register Number'), findsOneWidget);

      // Verify "Verify Reg No" button
      expect(find.widgetWithText(ElevatedButton, 'Verify Reg No'), findsOneWidget);

      // 1. Enter INCORRECT register number first and verify mismatch status message
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter Register Number'),
        'WRONG_REGISTER_NUMBER',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify Reg No'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Register Number Does Not Match'), findsOneWidget);

      // 2. Enter CORRECT register number and verify success
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter Register Number'),
        'CE20CS1234',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify Reg No'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify success message and masked register number
      expect(find.text('Register number verified successfully! ✅'), findsOneWidget);
      expect(find.text('Masked Register Number: CE20CS1***'), findsOneWidget);

      // Verify Capture Photo button is now active for lender
      expect(find.widgetWithText(ElevatedButton, 'Capture Photo'), findsOneWidget);
    });

    testWidgets('Borrower sees Return Item button during active borrowing and starts return workflow',
        (tester) async {
      final borrower = UserModel(
        uid: 'user_active_b',
        email: 'ab@college.edu',
        fullName: 'Meera Borrower',
        registerNumber: 'EE20EE1001',
      );
      final lender = UserModel(
        uid: 'user_active_l',
        email: 'al@college.edu',
        fullName: 'Naveen Lender',
        registerNumber: 'EE20EE2002',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final chat = ChatModel(
        id: 'chat_active_1',
        requestId: 'req_active_1',
        itemId: 'item_active_1',
        itemName: 'Soldering Station',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: [borrower.uid, lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_active_1',
        requestId: chat.requestId,
        itemId: chat.itemId,
        itemName: chat.itemName,
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        status: 'active',
        handoverIdentityVerified: true,
        handoverPhotoUrl: 'https://example.com/handover.jpg',
        handoverConfirmed: true,
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // Login as borrower
      await ServiceRegistry.authService.login(email: borrower.email, password: 'any');
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

      // Verify Return Item button is visible for borrower
      expect(find.widgetWithText(ElevatedButton, 'Return Item'), findsOneWidget);

      // Tap Return Item
      await tester.tap(find.widgetWithText(ElevatedButton, 'Return Item'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify return confirmation dialog appears
      expect(find.text('Initiate Item Return'), findsOneWidget);
      expect(find.text('Confirm & Start Return'), findsOneWidget);

      // Confirm return
      await tester.tap(find.text('Confirm & Start Return'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify transaction moved to return_requested
      final updatedTxn = InMemoryStore.instance.transactions[txn.id]!;
      expect(updatedTxn.status, 'return_requested');
    });
  });
}
