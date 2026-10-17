import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/models/borrow_request_model.dart';
import 'package:borrow_now/models/transaction_model.dart';
import 'package:borrow_now/providers/auth_provider.dart';
import 'package:borrow_now/providers/chat_provider.dart';
import 'package:borrow_now/services/service_registry.dart';
import 'package:borrow_now/services/in_memory_store.dart';
import 'package:borrow_now/services/chat_service.dart';
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

  group('BorrowNow Private Chat Isolation Tests', () {
    test('1-4: Chat A and Chat B isolation — messages never leak across conversations', () async {
      // Participant setup for Conversation A
      final borrowerA = UserModel(
        uid: 'user_borrower_a',
        email: 'borrower_a@college.edu',
        fullName: 'Aarav Borrower',
      );
      final lenderB = UserModel(
        uid: 'user_lender_b',
        email: 'lender_b@college.edu',
        fullName: 'Bhavna Lender',
      );

      // Participant setup for Conversation B
      final borrowerC = UserModel(
        uid: 'user_borrower_c',
        email: 'borrower_c@college.edu',
        fullName: 'Chirag Borrower',
      );
      final lenderD = UserModel(
        uid: 'user_lender_d',
        email: 'lender_d@college.edu',
        fullName: 'Divya Lender',
      );

      InMemoryStore.instance.users[borrowerA.uid] = borrowerA;
      InMemoryStore.instance.users[lenderB.uid] = lenderB;
      InMemoryStore.instance.users[borrowerC.uid] = borrowerC;
      InMemoryStore.instance.users[lenderD.uid] = lenderD;

      // Create Chat A
      final chatA = await ServiceRegistry.chatService.createOrGetChat(
        requestId: 'req_alpha',
        itemId: 'item_calc',
        itemName: 'Graphing Calculator',
        borrowerId: borrowerA.uid,
        borrowerName: borrowerA.fullName,
        lenderId: lenderB.uid,
        lenderName: lenderB.fullName,
      );

      // Create Chat B
      final chatB = await ServiceRegistry.chatService.createOrGetChat(
        requestId: 'req_beta',
        itemId: 'item_apron',
        itemName: 'Chemistry Apron',
        borrowerId: borrowerC.uid,
        borrowerName: borrowerC.fullName,
        lenderId: lenderD.uid,
        lenderName: lenderD.fullName,
      );

      expect(chatA.id != chatB.id, isTrue);

      // 1. User A sends message in Chat A
      await ServiceRegistry.chatService.sendMessage(
        chatId: chatA.id,
        senderId: borrowerA.uid,
        senderName: borrowerA.fullName,
        text: 'Private message in Chat A: Meet at library 3pm',
      );

      // 2. Confirm messages in Chat A
      final msgsA = await ServiceRegistry.chatService.getMessagesStream(chatA.id).first;
      expect(msgsA.length, 1);
      expect(msgsA.first.text, 'Private message in Chat A: Meet at library 3pm');
      expect(msgsA.first.senderId, borrowerA.uid);

      // 3. Confirm Chat B has ZERO messages from Chat A
      final msgsBInitial = await ServiceRegistry.chatService.getMessagesStream(chatB.id).first;
      expect(msgsBInitial.isEmpty, isTrue);

      // 4. Send message in Chat B and confirm it does not appear in Chat A
      await ServiceRegistry.chatService.sendMessage(
        chatId: chatB.id,
        senderId: borrowerC.uid,
        senderName: borrowerC.fullName,
        text: 'Private message in Chat B: Lab coat available outside room 204',
      );

      final msgsBUpdated = await ServiceRegistry.chatService.getMessagesStream(chatB.id).first;
      expect(msgsBUpdated.length, 1);
      expect(msgsBUpdated.first.text, 'Private message in Chat B: Lab coat available outside room 204');

      final msgsAAfter = await ServiceRegistry.chatService.getMessagesStream(chatA.id).first;
      expect(msgsAAfter.length, 1);
      expect(msgsAAfter.first.text, 'Private message in Chat A: Meet at library 3pm');
    });

    test('5 & 6: Unselected volunteers and unauthorized users cannot access private chat or send messages', () async {
      final borrower = UserModel(
        uid: 'user_borrower_1',
        email: 'b1@college.edu',
        fullName: 'Borrower One',
      );
      final selectedLender = UserModel(
        uid: 'user_lender_selected',
        email: 'l_sel@college.edu',
        fullName: 'Selected Lender',
      );
      final unselectedVolunteer = UserModel(
        uid: 'user_volunteer_unselected',
        email: 'v_unsel@college.edu',
        fullName: 'Unselected Volunteer',
      );

      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[selectedLender.uid] = selectedLender;
      InMemoryStore.instance.users[unselectedVolunteer.uid] = unselectedVolunteer;

      // Borrow request with an accepted helper and an unselected helper
      final request = BorrowRequestModel(
        id: 'req_selection_test',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        itemId: 'item_drafter',
        itemName: 'Mini Drafter',
        ownerId: selectedLender.uid,
        pickupLocation: 'Library',
        status: 'helper_selected',
        acceptedHelperId: selectedLender.uid,
        acceptedHelperName: selectedLender.fullName,
        helpers: [
          {'helperId': selectedLender.uid, 'helperName': selectedLender.fullName, 'status': 'accepted'},
          {'helperId': unselectedVolunteer.uid, 'helperName': unselectedVolunteer.fullName, 'status': 'offered'},
        ],
      );
      InMemoryStore.instance.requests[request.id] = request;

      // Create private chat for the accepted helper
      final chat = await ServiceRegistry.chatService.createOrGetChat(
        requestId: request.id,
        itemId: request.itemId,
        itemName: request.itemName,
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: selectedLender.uid,
        lenderName: selectedLender.fullName,
      );

      // Unselected volunteer cannot resolve or ensure chat for this request
      final resolvedForVolunteer = await ServiceRegistry.chatService.ensureChatForRequest(
        requestId: request.id,
        currentUserId: unselectedVolunteer.uid,
      );
      expect(resolvedForVolunteer, isNull);

      final resolvedChatIdForVolunteer = await ServiceRegistry.chatService.resolveChatId(
        relatedIdOrChatId: chat.id,
        currentUserId: unselectedVolunteer.uid,
      );
      expect(resolvedChatIdForVolunteer, isNull);

      // Unselected volunteer cannot send messages in this private chat
      expect(
        () => ServiceRegistry.chatService.sendMessage(
          chatId: chat.id,
          senderId: unselectedVolunteer.uid,
          senderName: unselectedVolunteer.fullName,
          text: 'Intruder trying to send message',
        ),
        throwsA(predicate((e) => e.toString().contains('Unauthorized'))),
      );
    });

    test('7: Real-time metadata, latest message preview, and unread counts are strictly isolated', () async {
      final borrower1 = UserModel(uid: 'b_meta_1', email: 'b1@edu', fullName: 'B1');
      final lender1 = UserModel(uid: 'l_meta_1', email: 'l1@edu', fullName: 'L1');
      final borrower2 = UserModel(uid: 'b_meta_2', email: 'b2@edu', fullName: 'B2');
      final lender2 = UserModel(uid: 'l_meta_2', email: 'l2@edu', fullName: 'L2');

      final chat1 = await ServiceRegistry.chatService.createOrGetChat(
        requestId: 'req_m1',
        itemId: 'item_1',
        itemName: 'Item 1',
        borrowerId: borrower1.uid,
        borrowerName: borrower1.fullName,
        lenderId: lender1.uid,
        lenderName: lender1.fullName,
      );

      final chat2 = await ServiceRegistry.chatService.createOrGetChat(
        requestId: 'req_m2',
        itemId: 'item_2',
        itemName: 'Item 2',
        borrowerId: borrower2.uid,
        borrowerName: borrower2.fullName,
        lenderId: lender2.uid,
        lenderName: lender2.fullName,
      );

      // Send in Chat 1
      await ServiceRegistry.chatService.sendMessage(
        chatId: chat1.id,
        senderId: borrower1.uid,
        senderName: borrower1.fullName,
        text: 'Latest message for Chat 1 only',
      );

      final updatedChat1 = InMemoryStore.instance.chats[chat1.id]!;
      final updatedChat2 = InMemoryStore.instance.chats[chat2.id]!;

      // Chat 1 has updated latest message and unread count for lender1
      expect(updatedChat1.lastMessage, 'Latest message for Chat 1 only');
      expect(updatedChat1.getUnreadCount(lender1.uid), 1);

      // Chat 2 remains completely pristine and untouched
      expect(updatedChat2.lastMessage, isNot('Latest message for Chat 1 only'));
      expect(updatedChat2.getUnreadCount(lender2.uid), 0);
    });

    test('8: Notification deep link resolution accurately routes requests and transactions to authorized chats', () async {
      final borrower = UserModel(uid: 'b_link', email: 'blink@edu', fullName: 'Borrower Link');
      final lender = UserModel(uid: 'l_link', email: 'llink@edu', fullName: 'Lender Link');
      final intruder = UserModel(uid: 'intruder_link', email: 'int@edu', fullName: 'Intruder');

      final request = BorrowRequestModel(
        id: 'req_link_101',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        itemId: 'item_link',
        itemName: 'Item Link',
        ownerId: lender.uid,
        pickupLocation: 'Library',
        status: 'helper_selected',
        acceptedHelperId: lender.uid,
        acceptedHelperName: lender.fullName,
      );
      InMemoryStore.instance.requests[request.id] = request;

      final txn = TransactionModel(
        id: 'txn_link_202',
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

      final expectedChatId = ChatService.buildChatId(
        requestId: request.id,
        borrowerId: borrower.uid,
        helperId: lender.uid,
      );

      // Borrower resolves via transaction ID (e.g. from notification)
      final resolvedFromTxn = await ServiceRegistry.chatService.resolveChatId(
        relatedIdOrChatId: txn.id,
        currentUserId: borrower.uid,
      );
      expect(resolvedFromTxn, expectedChatId);

      // Lender resolves via request ID
      final resolvedFromReq = await ServiceRegistry.chatService.resolveChatId(
        relatedIdOrChatId: request.id,
        currentUserId: lender.uid,
      );
      expect(resolvedFromReq, expectedChatId);

      // Intruder attempting to resolve via txn.id or req.id gets null
      final intruderFromTxn = await ServiceRegistry.chatService.resolveChatId(
        relatedIdOrChatId: txn.id,
        currentUserId: intruder.uid,
      );
      expect(intruderFromTxn, isNull);

      final intruderFromReq = await ServiceRegistry.chatService.resolveChatId(
        relatedIdOrChatId: request.id,
        currentUserId: intruder.uid,
      );
      expect(intruderFromReq, isNull);
    });

    test('9: Simultaneous opening by both participants yields deterministic, duplicate-free chat', () async {
      final borrower = UserModel(uid: 'b_sim', email: 'bsim@edu', fullName: 'B Sim');
      final lender = UserModel(uid: 'l_sim', email: 'lsim@edu', fullName: 'L Sim');

      // Both open concurrently
      final futures = await Future.wait([
        ServiceRegistry.chatService.createOrGetChat(
          requestId: 'req_sim_1',
          itemId: 'item_sim',
          itemName: 'Sim Item',
          borrowerId: borrower.uid,
          borrowerName: borrower.fullName,
          lenderId: lender.uid,
          lenderName: lender.fullName,
        ),
        ServiceRegistry.chatService.createOrGetChat(
          requestId: 'req_sim_1',
          itemId: 'item_sim',
          itemName: 'Sim Item',
          borrowerId: borrower.uid,
          borrowerName: borrower.fullName,
          lenderId: lender.uid,
          lenderName: lender.fullName,
        ),
      ]);

      expect(futures[0].id, futures[1].id);
      expect(futures[0].id, ChatService.buildChatId(
        requestId: 'req_sim_1',
        borrowerId: borrower.uid,
        helperId: lender.uid,
      ));
      expect(InMemoryStore.instance.chats.length, 1);
    });

    testWidgets('10: Navigating between chats resets state and never displays stale messages', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final userA = UserModel(uid: 'user_a_nav', email: 'a_nav@edu', fullName: 'User A');
      final userB = UserModel(uid: 'user_b_nav', email: 'b_nav@edu', fullName: 'User B');
      final userC = UserModel(uid: 'user_c_nav', email: 'c_nav@edu', fullName: 'User C');

      InMemoryStore.instance.users[userA.uid] = userA;
      InMemoryStore.instance.users[userB.uid] = userB;
      InMemoryStore.instance.users[userC.uid] = userC;

      // Chat 1: User A & User B
      final chat1 = await ServiceRegistry.chatService.createOrGetChat(
        requestId: 'req_nav_1',
        itemId: 'item_n1',
        itemName: 'First Item',
        borrowerId: userA.uid,
        borrowerName: userA.fullName,
        lenderId: userB.uid,
        lenderName: userB.fullName,
      );

      // Chat 2: User A & User C
      final chat2 = await ServiceRegistry.chatService.createOrGetChat(
        requestId: 'req_nav_2',
        itemId: 'item_n2',
        itemName: 'Second Item',
        borrowerId: userA.uid,
        borrowerName: userA.fullName,
        lenderId: userC.uid,
        lenderName: userC.fullName,
      );

      // Seed message in Chat 1
      await ServiceRegistry.chatService.sendMessage(
        chatId: chat1.id,
        senderId: userB.uid,
        senderName: userB.fullName,
        text: 'Secret Message for Chat 1',
      );

      // Seed message in Chat 2
      await ServiceRegistry.chatService.sendMessage(
        chatId: chat2.id,
        senderId: userC.uid,
        senderName: userC.fullName,
        text: 'Different Content in Chat 2',
      );

      await ServiceRegistry.authService.login(email: userA.email, password: 'password');
      final authProvider = AuthProvider();
      final chatProvider = ChatProvider();

      // Open Chat 1
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: chatProvider),
          ],
          child: MaterialApp(
            home: ChatScreen(
              key: ValueKey('chat_screen_${chat1.id}'),
              chatId: chat1.id,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Secret Message for Chat 1'), findsOneWidget);
      expect(find.text('Different Content in Chat 2'), findsNothing);

      // Now navigate to Chat 2
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: chatProvider),
          ],
          child: MaterialApp(
            home: ChatScreen(
              key: ValueKey('chat_screen_${chat2.id}'),
              chatId: chat2.id,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Chat 1 message is gone; Chat 2 message is displayed
      expect(find.text('Different Content in Chat 2'), findsOneWidget);
      expect(find.text('Secret Message for Chat 1'), findsNothing);
    });
  });
}
