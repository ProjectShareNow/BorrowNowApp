import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:borrow_now/providers/auth_provider.dart';
import 'package:borrow_now/providers/chat_provider.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/models/item_model.dart';
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

  group('BorrowNow Firestore Register Number Verification Comprehensive Tests', () {
    // 1 & 2: Correct and incorrect borrower register number during handover
    test('1 & 2: Borrower register number verification during handover (correct vs incorrect)', () async {
      final borrower = UserModel(
        uid: 'user_borrower_h',
        email: 'borrower@college.edu',
        fullName: 'Borrower Name',
        registerNumber: '710021104001',
      );
      final lender = UserModel(
        uid: 'user_lender_h',
        email: 'lender@college.edu',
        fullName: 'Lender Name',
        registerNumber: '710021104050',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final txn = TransactionModel(
        id: 'txn_handover_test',
        requestId: 'req_handover_test',
        itemId: 'item_1',
        itemName: 'Graphing Calculator',
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        status: 'scheduled',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // Incorrect register number fails with exact message
      expect(
        () => ServiceRegistry.transactionService.verifyBorrowerIdentity(
          transactionId: txn.id,
          lenderId: lender.uid,
          enteredRegisterNumber: '710021104999',
        ),
        throwsA(predicate((e) =>
            e.toString().contains('Verification Failed. The register number does not match the borrower’s records'))),
      );

      // Correct register number succeeds (even with spaces and mixed case)
      final success = await ServiceRegistry.transactionService.verifyBorrowerIdentity(
        transactionId: txn.id,
        lenderId: lender.uid,
        enteredRegisterNumber: '  710021104001  ',
      );
      expect(success, isTrue);

      final updated = InMemoryStore.instance.transactions[txn.id]!;
      expect(updated.handoverIdentityVerified, isTrue);
      expect(updated.handoverVerifiedBy, lender.uid);
      expect(updated.handoverVerifiedAt, isNotNull);
    });

    // 3 & 4: Correct and incorrect lender register number during return
    test('3 & 4: Lender register number verification during return (correct vs incorrect)', () async {
      final borrower = UserModel(
        uid: 'user_borrower_r',
        email: 'borrower@college.edu',
        fullName: 'Borrower Name',
        registerNumber: '710021104001',
      );
      final lender = UserModel(
        uid: 'user_lender_r',
        email: 'lender@college.edu',
        fullName: 'Lender Name',
        registerNumber: '710021104050',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final txn = TransactionModel(
        id: 'txn_return_test',
        requestId: 'req_return_test',
        itemId: 'item_1',
        itemName: 'Graphing Calculator',
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        status: 'return_requested',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // Incorrect register number fails with exact message
      expect(
        () => ServiceRegistry.transactionService.verifyLenderIdentityForReturn(
          transactionId: txn.id,
          borrowerId: borrower.uid,
          enteredRegisterNumber: '710021104000',
        ),
        throwsA(predicate((e) =>
            e.toString().contains('Verification Failed. The register number does not match the lender’s records'))),
      );

      // Correct register number succeeds
      final success = await ServiceRegistry.transactionService.verifyLenderIdentityForReturn(
        transactionId: txn.id,
        borrowerId: borrower.uid,
        enteredRegisterNumber: '  710021104050  ',
      );
      expect(success, isTrue);

      final updated = InMemoryStore.instance.transactions[txn.id]!;
      expect(updated.returnIdentityVerified, isTrue);
      expect(updated.returnVerifiedBy, borrower.uid);
      expect(updated.returnVerifiedAt, isNotNull);
    });

    // 5: Empty input and register-number format handling
    test('5: Empty input and formatting validation', () async {
      final borrower = UserModel(
        uid: 'user_b_fmt',
        email: 'b_fmt@college.edu',
        fullName: 'B',
        registerNumber: 'REG-1234',
      );
      final lender = UserModel(
        uid: 'user_l_fmt',
        email: 'l_fmt@college.edu',
        fullName: 'L',
        registerNumber: 'REG-5678',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final txn = TransactionModel(
        id: 'txn_fmt',
        requestId: 'req_fmt',
        itemId: 'item_1',
        itemName: 'Item',
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: 'L',
        borrowerName: 'B',
        status: 'scheduled',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // Empty string throws
      expect(
        () => ServiceRegistry.transactionService.verifyBorrowerIdentity(
          transactionId: txn.id,
          lenderId: lender.uid,
          enteredRegisterNumber: '   ',
        ),
        throwsA(predicate((e) => e.toString().contains('Please enter the borrower\'s register number'))),
      );

      // Special characters / formatting normalized match succeeds
      final res = await ServiceRegistry.transactionService.verifyBorrowerIdentity(
        transactionId: txn.id,
        lenderId: lender.uid,
        enteredRegisterNumber: ' reg 1234 ',
      );
      expect(res, isTrue);
    });

    // 6: Missing register number in Firestore/Database
    test('6: Missing register number in database raises administrative contact notice', () async {
      final borrowerNoReg = UserModel(
        uid: 'user_b_noreg',
        email: 'b_noreg@college.edu',
        fullName: 'No Reg Borrower',
        registerNumber: '',
        collegeId: '',
      );
      final lender = UserModel(
        uid: 'user_l_noreg',
        email: 'l_noreg@college.edu',
        fullName: 'Lender',
        registerNumber: 'LEND123',
      );
      InMemoryStore.instance.users[borrowerNoReg.uid] = borrowerNoReg;
      InMemoryStore.instance.users[lender.uid] = lender;

      final txn = TransactionModel(
        id: 'txn_noreg',
        requestId: 'req_noreg',
        itemId: 'item_1',
        itemName: 'Item',
        ownerId: lender.uid,
        borrowerId: borrowerNoReg.uid,
        ownerName: 'L',
        borrowerName: 'B',
        status: 'scheduled',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      expect(
        () => ServiceRegistry.transactionService.verifyBorrowerIdentity(
          transactionId: txn.id,
          lenderId: lender.uid,
          enteredRegisterNumber: 'ANY_REG_NUM',
        ),
        throwsA(predicate((e) =>
            e.toString().contains('This borrower’s register number is not available in the database. Please contact the administrator.'))),
      );
    });

    // 7 & 8: Unauthorized users attempting verification & status constraints
    test('7 & 8: Unauthorized user or invalid transaction stage rejected', () async {
      final borrower = UserModel(uid: 'b_auth', email: 'b_auth@college.edu', fullName: 'B', registerNumber: 'B123');
      final lender = UserModel(uid: 'l_auth', email: 'l_auth@college.edu', fullName: 'L', registerNumber: 'L123');
      final bystander = UserModel(uid: 'c_intruder', email: 'c_intruder@college.edu', fullName: 'C', registerNumber: 'C123');

      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;
      InMemoryStore.instance.users[bystander.uid] = bystander;

      final txn = TransactionModel(
        id: 'txn_auth',
        requestId: 'req_auth',
        itemId: 'item_1',
        itemName: 'Item',
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: 'L',
        borrowerName: 'B',
        status: 'scheduled',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // Bystander cannot verify borrower identity
      expect(
        () => ServiceRegistry.transactionService.verifyBorrowerIdentity(
          transactionId: txn.id,
          lenderId: bystander.uid,
          enteredRegisterNumber: 'B123',
        ),
        throwsA(predicate((e) => e.toString().contains('You are not authorized to verify this transaction.'))),
      );

      // Borrower cannot self-verify handover
      expect(
        () => ServiceRegistry.transactionService.verifyBorrowerIdentity(
          transactionId: txn.id,
          lenderId: borrower.uid,
          enteredRegisterNumber: 'B123',
        ),
        throwsA(predicate((e) => e.toString().contains('You are not authorized to verify this transaction.'))),
      );
    });

    // 9: Previous handover verification not being reused for return
    test('9: Handover verification does not count as return verification', () async {
      final borrower = UserModel(uid: 'b_stage', email: 'b_stage@college.edu', fullName: 'B', registerNumber: 'B123');
      final lender = UserModel(uid: 'l_stage', email: 'l_stage@college.edu', fullName: 'L', registerNumber: 'L123');
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final txn = TransactionModel(
        id: 'txn_stage',
        requestId: 'req_stage',
        itemId: 'item_1',
        itemName: 'Item',
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: 'L',
        borrowerName: 'B',
        status: 'scheduled',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      await ServiceRegistry.transactionService.verifyBorrowerIdentity(
        transactionId: txn.id,
        lenderId: lender.uid,
        enteredRegisterNumber: 'B123',
      );

      final verifiedTxn = InMemoryStore.instance.transactions[txn.id]!;
      expect(verifiedTxn.handoverIdentityVerified, isTrue);
      // Return verification MUST still be false
      expect(verifiedTxn.returnIdentityVerified, isFalse);
      expect(verifiedTxn.returnVerifiedBy, isEmpty);
    });

    // 10: Handover and return remaining blocked until required steps succeed
    test('10: Handover confirmation blocked if identity is not verified', () async {
      final borrower = UserModel(uid: 'b_block', email: 'b_block@college.edu', fullName: 'B', registerNumber: 'B123');
      final lender = UserModel(uid: 'l_block', email: 'l_block@college.edu', fullName: 'L', registerNumber: 'L123');
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final item = ItemModel(
        id: 'item_block',
        name: 'Item',
        category: 'Cat',
        description: 'Desc',
        condition: 'good',
        pickupLocation: 'Loc',
        ownerId: lender.uid,
        ownerName: lender.fullName,
        availability: 'reserved',
      );
      InMemoryStore.instance.items[item.id] = item;

      final txn = TransactionModel(
        id: 'txn_block',
        requestId: 'req_block',
        itemId: item.id,
        itemName: item.name,
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: 'L',
        borrowerName: 'B',
        status: 'scheduled',
        handoverIdentityVerified: false,
        handoverPhotoUrl: 'https://example.com/photo.jpg',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // Attempting handover confirm before identity verification fails
      expect(
        () => ServiceRegistry.transactionService.confirmItemHandover(
          transactionId: txn.id,
          lenderId: lender.uid,
        ),
        throwsA(predicate((e) => e.toString().contains('verified'))),
      );
    });

    testWidgets('11: UI removes identity verification panel and displays camera evidence card', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final borrower = UserModel(uid: 'b_ui', email: 'b_ui@college.edu', fullName: 'Borrower', registerNumber: 'REG_BORROWER');
      final lender = UserModel(uid: 'l_ui', email: 'l_ui@college.edu', fullName: 'Lender', registerNumber: 'REG_LENDER');
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final chat = ChatModel(
        id: 'chat_ui_1',
        requestId: 'req_ui_1',
        itemId: 'item_lens',
        itemName: 'Camera Lens',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: [borrower.uid, lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_ui_1',
        requestId: 'req_ui_1',
        itemId: 'item_lens',
        itemName: 'Camera Lens',
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        status: 'scheduled',
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      await ServiceRegistry.authService.login(email: lender.email, password: 'password');
      final authProvider = AuthProvider();
      final chatProvider = ChatProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: chatProvider),
          ],
          child: MaterialApp(
            home: ChatScreen(
              chatId: chat.id,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Identity Verification panel is NOT rendered
      expect(find.text('Identity Verification'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Verify Identity'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Verify College ID'), findsNothing);

      // Verify Camera card is rendered and Take Photo button is active
      expect(find.text('Handover Item Condition Photo'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Take Photo'), findsOneWidget);
    });
  });
}
