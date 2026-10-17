import 'package:flutter_test/flutter_test.dart';
import 'package:borrow_now/services/service_registry.dart';
import 'package:borrow_now/models/borrow_request_model.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/services/in_memory_store.dart';
import 'package:borrow_now/services/chat_service.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ServiceRegistry.init();
    InMemoryStore.instance.requests.clear();
    InMemoryStore.instance.chats.clear();
    InMemoryStore.instance.messages.clear();
    InMemoryStore.instance.notifications.clear();
  });

  test('Private Borrower-Lender Chat Lifecycle after Helper Acceptance', () async {
    final requestService = ServiceRegistry.borrowRequestService;
    final chatService = ServiceRegistry.chatService;

    // 1. Borrower (User A) creates item request
    final req = BorrowRequestModel(
      id: 'req_calc',
      itemId: 'item_fx991',
      itemName: 'Casio Scientific Calculator',
      ownerId: 'campus_community',
      borrowerId: 'user_a',
      borrowerName: 'User A (Borrower)',
      requiredDate: DateTime.now().add(const Duration(days: 1)),
      requiredTime: '2:00 PM',
      duration: '1 day',
      pickupLocation: 'College Library',
      status: 'open',
    );

    await requestService.submitRequest(req);
    expect(InMemoryStore.instance.chats.isEmpty, isTrue,
        reason: 'No chat should exist when request is created');

    // 2. User B offers help ("I Can Help")
    final userB = UserModel(
      uid: 'user_b',
      email: 'user_b@college.edu',
      fullName: 'User B (Helper)',
    );

    await requestService.offerHelp(requestId: 'req_calc', helperUser: userB);

    // 3. Verify: Clicking "I Can Help" ONLY creates a help offer, NO CHAT AT THIS STAGE
    expect(InMemoryStore.instance.chats.isEmpty, isTrue,
        reason: 'Chat must NOT be created when a user simply offers help');

    var storedReq = InMemoryStore.instance.requests['req_calc']!;
    expect(storedReq.helperIds.contains('user_b'), isTrue);
    expect(storedReq.acceptedHelperId, isNull);

    // Requester gets notification about the offer
    final offerNotifs = InMemoryStore.instance.notifications.values
        .where((n) => n.recipientId == 'user_a' && n.type == 'help_offered')
        .toList();
    expect(offerNotifs.isNotEmpty, isTrue);

    // 4. User A ACCEPTS User B
    final returnedChatId = await requestService.acceptHelper(
      requestId: 'req_calc',
      requesterId: 'user_a',
      helperId: 'user_b',
      helperName: 'User B (Helper)',
    );

    final expectedChatId = ChatService.buildChatId(
      requestId: 'req_calc',
      borrowerId: 'user_a',
      helperId: 'user_b',
    );
    expect(returnedChatId, expectedChatId);

    // Request is updated with acceptedHelper and chatId
    storedReq = InMemoryStore.instance.requests['req_calc']!;
    expect(storedReq.status, 'helper_selected');
    expect(storedReq.acceptedHelperId, 'user_b');
    expect(storedReq.chatId, expectedChatId);

    // 5. Verify: Private chat is created for ONLY these two users
    expect(InMemoryStore.instance.chats.containsKey(expectedChatId), isTrue);
    final chat = InMemoryStore.instance.chats[expectedChatId]!;
    expect(chat.status, 'active');
    expect(chat.borrowerId, 'user_a');
    expect(chat.lenderId, 'user_b');
    expect(chat.participants, containsAll(['user_a', 'user_b']));
    expect(chat.participants.length, 2);

    // Verify participant helper methods
    expect(chat.isUserParticipant('user_a'), isTrue);
    expect(chat.isUserParticipant('user_b'), isTrue);
    expect(chat.isUserParticipant('user_c'), isFalse);

    // 6. Verify: Accepted helper received notification with deep link to chat
    final acceptNotifs = InMemoryStore.instance.notifications.values
        .where((n) => n.recipientId == 'user_b' && n.type == 'helper_accepted')
        .toList();
    expect(acceptNotifs.isNotEmpty, isTrue);
    expect(acceptNotifs.first.title, "You've been selected to help");
    expect(acceptNotifs.first.relatedId, expectedChatId);

    // 7. Verify real-time messaging: User A sends message
    await chatService.sendMessage(
      chatId: expectedChatId,
      senderId: 'user_a',
      senderName: 'User A',
      text: 'Where should we meet?',
      recipientId: 'user_b',
    );

    var messages = InMemoryStore.instance.messages[expectedChatId]!;
    expect(messages.length, 1);
    expect(messages.first.text, 'Where should we meet?');
    expect(messages.first.senderId, 'user_a');

    // User B sends reply
    await chatService.sendMessage(
      chatId: expectedChatId,
      senderId: 'user_b',
      senderName: 'User B',
      text: 'I can meet near the library.',
      recipientId: 'user_a',
    );

    messages = InMemoryStore.instance.messages[expectedChatId]!;
    expect(messages.length, 2);
    expect(messages.last.text, 'I can meet near the library.');

    // 8. Access control test: User C (unauthorized outsider) attempts to send message
    expect(
      () => chatService.sendMessage(
        chatId: expectedChatId,
        senderId: 'user_c',
        senderName: 'User C',
        text: 'Can I join this chat?',
      ),
      throwsA(isA<Exception>()),
      reason: 'Unauthorized users must NOT be able to send messages',
    );

    // 9. Removal test: User A removes/rejects User B before handover
    await requestService.removeAcceptedHelper(
      requestId: 'req_calc',
      requesterId: 'user_a',
      helperId: 'user_b',
    );

    // Verify chat status is closed
    final closedChat = InMemoryStore.instance.chats[expectedChatId]!;
    expect(closedChat.isClosed, isTrue);
    expect(closedChat.status, 'closed');

    // Verify removed helper cannot send new messages
    expect(
      () => chatService.sendMessage(
        chatId: expectedChatId,
        senderId: 'user_b',
        senderName: 'User B',
        text: 'Wait, why was I removed?',
      ),
      throwsA(isA<Exception>()),
      reason: 'Messages cannot be sent in closed chat',
    );

    // Verify removed helper receives removal notification
    final removeNotifs = InMemoryStore.instance.notifications.values
        .where((n) => n.recipientId == 'user_b' && n.type == 'helper_removed')
        .toList();
    expect(removeNotifs.isNotEmpty, isTrue);
    expect(removeNotifs.first.message,
        'You are no longer selected for this borrowing request.');

    // Verify request is reopened
    storedReq = InMemoryStore.instance.requests['req_calc']!;
    expect(storedReq.status, 'open');
    expect(storedReq.acceptedHelperId, isNull);
    expect(storedReq.rejectedHelperIds, contains('user_b'));

    // 10. Another user (User C) can now offer help
    final userC = UserModel(
      uid: 'user_c',
      email: 'user_c@college.edu',
      fullName: 'User C (New Helper)',
    );

    await requestService.offerHelp(requestId: 'req_calc', helperUser: userC);

    // User A can accept User C, creating a distinct new private chat
    final newChatId = await requestService.acceptHelper(
      requestId: 'req_calc',
      requesterId: 'user_a',
      helperId: 'user_c',
      helperName: 'User C (New Helper)',
    );

    expect(newChatId, isNot(equals(expectedChatId)));
    final newChat = InMemoryStore.instance.chats[newChatId]!;
    expect(newChat.status, 'active');
    expect(newChat.participants, containsAll(['user_a', 'user_c']));
    expect(newChat.participants, isNot(contains('user_b')));
  });
}
