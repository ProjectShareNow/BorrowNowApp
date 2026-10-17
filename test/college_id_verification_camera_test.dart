import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:borrow_now/providers/auth_provider.dart';
import 'package:borrow_now/providers/chat_provider.dart';
import 'package:borrow_now/models/user_model.dart';
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

  group('BorrowNow Chat Screen: Removed Identity Verification with Preserved Camera Feature', () {
    testWidgets('1. Identity verification UI is removed and camera is immediately enabled for lender', (tester) async {
      final borrower = UserModel(
        uid: 'b_uid_1',
        email: 'borrower1@college.edu',
        fullName: 'Aarav Borrower',
        collegeId: 'COLLEGE_ID_101',
      );
      final lender = UserModel(
        uid: 'l_uid_1',
        email: 'lender1@college.edu',
        fullName: 'Diya Lender',
        collegeId: 'COLLEGE_ID_202',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final chat = ChatModel(
        id: 'chat_test_1',
        requestId: 'req_test_1',
        itemId: 'item_test_1',
        itemName: 'Arduino Kit',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: [borrower.uid, lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_test_1',
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

      // 1. Confirm identity verification UI is NOT present
      expect(find.text("Enter Borrower's College ID"), findsNothing);
      expect(find.text("Enter Register Number"), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Verify College ID'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Verify Identity'), findsNothing);
      expect(find.text('Identity Verification'), findsNothing);
      expect(find.text('Return Identity Verification'), findsNothing);

      // 2. Camera Card is visible
      expect(find.text('Handover Item Condition Photo'), findsOneWidget);

      // 3. Take Photo camera button is immediately ENABLED without requiring identity verification
      final takePhotoButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Take Photo'),
      );
      expect(takePhotoButton.onPressed, isNotNull);
    });

    testWidgets('2. Lender captures live camera photo, previews, retakes, and confirms upload', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final borrower = UserModel(
        uid: 'b_uid_2',
        email: 'b2@college.edu',
        fullName: 'Rohan Borrower',
      );
      final lender = UserModel(
        uid: 'l_uid_2',
        email: 'l2@college.edu',
        fullName: 'Pooja Lender',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final chat = ChatModel(
        id: 'chat_test_2',
        requestId: 'req_test_2',
        itemId: 'item_test_2',
        itemName: 'Chemistry Model Kit',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: [borrower.uid, lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_test_2',
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

      // Simulate capturing photo
      ServiceRegistry.storageService.mockLivePhotoFile = XFile(
        '${Directory.systemTemp.path}/test_evidence.jpg',
      );

      // Tap Take Photo
      await tester.tap(find.widgetWithText(ElevatedButton, 'Take Photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Preview displays Retake Photo and Upload Photo
      expect(find.widgetWithText(OutlinedButton, 'Retake Photo'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Upload Photo'), findsOneWidget);

      // Tap Upload Photo
      await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify photo uploaded and saved to transaction record
      final updatedTxn = InMemoryStore.instance.transactions[txn.id]!;
      expect(updatedTxn.handoverPhotoUrl, isNotEmpty);
      expect(updatedTxn.handoverIdentityVerified, isTrue);
    });

    testWidgets('3. Camera is disabled for borrower during handover stage with appropriate reason', (tester) async {
      final borrower = UserModel(
        uid: 'b_uid_3',
        email: 'b3@college.edu',
        fullName: 'Sneha Borrower',
      );
      final lender = UserModel(
        uid: 'l_uid_3',
        email: 'l3@college.edu',
        fullName: 'Kiran Lender',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final chat = ChatModel(
        id: 'chat_test_3',
        requestId: 'req_test_3',
        itemId: 'item_test_3',
        itemName: 'Microcontroller Board',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: [borrower.uid, lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_test_3',
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

      // Log in as Borrower
      await ServiceRegistry.authService.login(email: borrower.email, password: 'password');
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

      // Button is disabled with reason
      final takePhotoButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Take Photo'),
      );
      expect(takePhotoButton.onPressed, isNull);
      expect(find.text('Only the lender can capture handover photo.'), findsOneWidget);
    });

    testWidgets('4. Return stage: Borrower can capture and confirm return photo without identity verification', (tester) async {
      final borrower = UserModel(
        uid: 'b_uid_4',
        email: 'b4@college.edu',
        fullName: 'Maya Borrower',
      );
      final lender = UserModel(
        uid: 'l_uid_4',
        email: 'l4@college.edu',
        fullName: 'Karthik Lender',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final chat = ChatModel(
        id: 'chat_test_4',
        requestId: 'req_test_4',
        itemId: 'item_test_4',
        itemName: 'Oscilloscope Probe',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: [borrower.uid, lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_test_4',
        requestId: chat.requestId,
        itemId: chat.itemId,
        itemName: chat.itemName,
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        status: 'return_requested',
        handoverPhotoUrl: 'https://example.com/handover.jpg',
        handoverConfirmed: true,
      );
      InMemoryStore.instance.transactions[txn.id] = txn;

      // Log in as Borrower
      await ServiceRegistry.authService.login(email: borrower.email, password: 'password');
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

      // Title shows Return Item Condition Photo
      expect(find.text('Return Item Condition Photo'), findsOneWidget);

      // Camera button is immediately enabled for borrower
      final takePhotoButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Take Photo'),
      );
      expect(takePhotoButton.onPressed, isNotNull);

      // Capture and upload return photo
      ServiceRegistry.storageService.mockLivePhotoFile = XFile(
        '${Directory.systemTemp.path}/return_evidence.jpg',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Take Photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final updatedTxn = InMemoryStore.instance.transactions[txn.id]!;
      expect(updatedTxn.returnPhotoUrl, isNotEmpty);
      expect(updatedTxn.returnIdentityVerified, isTrue);
    });

    testWidgets('5. Existing uploaded photo displays thumbnail with tap to zoom', (tester) async {
      final borrower = UserModel(
        uid: 'b_uid_5',
        email: 'b5@college.edu',
        fullName: 'Varun Borrower',
      );
      final lender = UserModel(
        uid: 'l_uid_5',
        email: 'l5@college.edu',
        fullName: 'Ananya Lender',
      );
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[lender.uid] = lender;

      final chat = ChatModel(
        id: 'chat_test_5',
        requestId: 'req_test_5',
        itemId: 'item_test_5',
        itemName: 'Digital Caliper',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: lender.uid,
        lenderName: lender.fullName,
        participants: [borrower.uid, lender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final txn = TransactionModel(
        id: 'txn_test_5',
        requestId: chat.requestId,
        itemId: chat.itemId,
        itemName: chat.itemName,
        ownerId: lender.uid,
        borrowerId: borrower.uid,
        ownerName: lender.fullName,
        borrowerName: borrower.fullName,
        status: 'scheduled',
        handoverPhotoUrl: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=300',
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

      // Shows Confirmed badge and stored notice
      expect(find.text('Confirmed ✅'), findsOneWidget);
      expect(find.text('Live evidence securely stored'), findsOneWidget);
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
    });
  });
}
