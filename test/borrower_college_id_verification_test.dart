import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:borrow_now/providers/auth_provider.dart';
import 'package:borrow_now/providers/chat_provider.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/models/chat_model.dart';
import 'package:borrow_now/models/borrow_request_model.dart';
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

  group('Borrower College ID Verification in Chat Screen Tests', () {
    testWidgets('1. Matching Borrow request College ID and users collection College ID marks verification as successful', (tester) async {
      final borrower = UserModel(
        uid: 'b_uid_match',
        email: 'borrower@college.edu',
        fullName: 'Borrower Student',
        collegeId: 'COLLEGE_ID_789',
        registerNumber: 'REG_789',
      );
      final lender = UserModel(
        uid: 'l_uid_match',
        email: 'lender@college.edu',
        fullName: 'Lender Student',
        collegeId: 'COLLEGE_ID_456',
        registerNumber: 'REG_456',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      // Stored borrow request with collegeId
      final request = BorrowRequestModel(
        id: 'req_match_1',
        itemId: 'item_1',
        ownerId: lender.uid,
        itemName: 'Digital Multimeter',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        collegeId: 'COLLEGE_ID_789',
        status: 'helper_selected',
        pickupLocation: 'Lab 2',
      );
      InMemoryStore.instance.requests[request.id] = request;

      final chat = ChatModel(
        id: 'chat_match_1',
        requestId: request.id,
        itemId: request.itemId,
        itemName: request.itemName,
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: [borrower.uid, lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_match_1',
        requestId: request.id,
        itemId: request.itemId,
        itemName: request.itemName,
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
          child: MaterialApp(home: ChatScreen(chatId: chat.id)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Enter matching College ID
      await tester.enterText(
        find.widgetWithText(TextField, "Enter Borrower's College ID"),
        'COLLEGE_ID_789',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify College ID'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text("College ID verified successfully. You can now capture the item condition photo."),
        findsOneWidget,
      );

      // Camera button must be enabled
      final takePhotoButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Take Photo'),
      );
      expect(takePhotoButton.onPressed, isNotNull);

      // Verification marked as successful on transaction
      final updatedTxn = InMemoryStore.instance.transactions[txn.id]!;
      expect(updatedTxn.handoverIdentityVerified, isTrue);
      expect(updatedTxn.handoverVerifiedBy, lender.uid);
    });

    testWidgets('2. Mismatched College ID shows exact error: Borrower College ID does not match the registered College ID.', (tester) async {
      final borrower = UserModel(
        uid: 'b_uid_mismatch',
        email: 'borrower2@college.edu',
        fullName: 'Borrower Student 2',
        collegeId: 'REAL_COLLEGE_ID',
      );
      final lender = UserModel(
        uid: 'l_uid_mismatch',
        email: 'lender2@college.edu',
        fullName: 'Lender Student 2',
        collegeId: 'LENDER_ID',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final request = BorrowRequestModel(
        id: 'req_mismatch_2',
        itemId: 'item_2',
        ownerId: lender.uid,
        itemName: 'Soldering Stand',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        collegeId: 'FAKE_COLLEGE_ID',
        status: 'helper_selected',
        pickupLocation: 'Workshop',
      );
      InMemoryStore.instance.requests[request.id] = request;

      final chat = ChatModel(
        id: 'chat_mismatch_2',
        requestId: request.id,
        itemId: request.itemId,
        itemName: request.itemName,
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: [borrower.uid, lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_mismatch_2',
        requestId: request.id,
        itemId: request.itemId,
        itemName: request.itemName,
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
          child: MaterialApp(home: ChatScreen(chatId: chat.id)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Enter mismatched College ID
      await tester.enterText(
        find.widgetWithText(TextField, "Enter Borrower's College ID"),
        'FAKE_COLLEGE_ID',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify College ID'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text("Borrower College ID does not match the registered College ID."),
        findsOneWidget,
      );

      // Camera button must remain disabled
      final takePhotoButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Take Photo'),
      );
      expect(takePhotoButton.onPressed, isNull);
    });

    testWidgets('3. Missing borrower document shows appropriate administrator error (not an internet error)', (tester) async {
      final lender = UserModel(
        uid: 'l_uid_missing_doc',
        email: 'lender3@college.edu',
        fullName: 'Lender Student 3',
        collegeId: 'LENDER_ID_3',
      );
      InMemoryStore.instance.users[lender.uid] = lender;
      // Note: Borrower document is NOT added to users collection!

      final chat = ChatModel(
        id: 'chat_missing_3',
        requestId: 'req_missing_3',
        itemId: 'item_3',
        itemName: 'Drafting Board',
        borrowerId: 'ghost_borrower_uid',
        borrowerName: 'Ghost Borrower',
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: ['ghost_borrower_uid', lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_missing_3',
        requestId: chat.requestId,
        itemId: chat.itemId,
        itemName: chat.itemName,
        ownerId: lender.uid,
        borrowerId: 'ghost_borrower_uid',
        ownerName: lender.fullName,
        borrowerName: 'Ghost Borrower',
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
          child: MaterialApp(home: ChatScreen(chatId: chat.id)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(
        find.widgetWithText(TextField, "Enter Borrower's College ID"),
        'ANY_COLLEGE_ID',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify College ID'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Shows document error, NOT "check your connection"
      expect(find.text("Borrower profile not found in database. Please contact the administrator."), findsOneWidget);
      expect(find.text("Unable to verify the College ID right now. Please check your connection and try again."), findsNothing);

      // Camera button must remain disabled
      final takePhotoButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Take Photo'),
      );
      expect(takePhotoButton.onPressed, isNull);
    });

    testWidgets('4. Missing College ID in user document shows appropriate error (not an internet error)', (tester) async {
      final borrower = UserModel(
        uid: 'b_uid_no_id',
        email: 'b_no_id@college.edu',
        fullName: 'Borrower Without ID',
        collegeId: '',
        registerNumber: '',
      );
      final lender = UserModel(
        uid: 'l_uid_no_id',
        email: 'l_no_id@college.edu',
        fullName: 'Lender 4',
        collegeId: 'LENDER_4',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final chat = ChatModel(
        id: 'chat_no_id_4',
        requestId: 'req_no_id_4',
        itemId: 'item_4',
        itemName: 'Laser Level',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: [borrower.uid, lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_no_id_4',
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

      await ServiceRegistry.authService.login(email: lender.email, password: 'password');
      final authProvider = AuthProvider();
      final chatProvider = ChatProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: chatProvider),
          ],
          child: MaterialApp(home: ChatScreen(chatId: chat.id)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(
        find.widgetWithText(TextField, "Enter Borrower's College ID"),
        'TEST_COLLEGE_ID',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify College ID'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text("The borrower's College ID is not available. Please contact the administrator."),
        findsOneWidget,
      );
      expect(find.text("Unable to verify the College ID right now. Please check your connection and try again."), findsNothing);
    });

    testWidgets('5. Does not compare borrower ID with lender ID or currently logged-in user ID', (tester) async {
      // Lender has College ID: 'LENDER_111'
      // Borrower has College ID: 'BORROWER_222'
      final borrower = UserModel(
        uid: 'b_uid_diff',
        email: 'b_diff@college.edu',
        fullName: 'Borrower Diff',
        collegeId: 'BORROWER_222',
      );
      final lender = UserModel(
        uid: 'l_uid_diff',
        email: 'l_diff@college.edu',
        fullName: 'Lender Diff',
        collegeId: 'LENDER_111',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final chat = ChatModel(
        id: 'chat_diff_5',
        requestId: 'req_diff_5',
        itemId: 'item_5',
        itemName: 'Tripod',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: [borrower.uid, lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_diff_5',
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

      await ServiceRegistry.authService.login(email: lender.email, password: 'password');
      final authProvider = AuthProvider();
      final chatProvider = ChatProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: chatProvider),
          ],
          child: MaterialApp(home: ChatScreen(chatId: chat.id)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Entering lender's own College ID must NOT succeed!
      await tester.enterText(
        find.widgetWithText(TextField, "Enter Borrower's College ID"),
        'LENDER_111',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify College ID'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text("Borrower College ID does not match the registered College ID."),
        findsOneWidget,
      );

      // Entering borrower's College ID succeeds!
      await tester.enterText(
        find.widgetWithText(TextField, "Enter Borrower's College ID"),
        'BORROWER_222',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify College ID'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text("College ID verified successfully. You can now capture the item condition photo."),
        findsOneWidget,
      );
    });
  });
}
