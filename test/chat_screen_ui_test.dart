import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:borrow_now/providers/auth_provider.dart';
import 'package:borrow_now/providers/chat_provider.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/models/chat_model.dart';
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
  });

  Future<Widget> createChatScreenApp({
    required UserModel currentUser,
    required String chatId,
  }) async {
    InMemoryStore.instance.users[currentUser.uid] = currentUser;
    await ServiceRegistry.authService.login(email: currentUser.email, password: 'any');
    final authProvider = AuthProvider();
    final chatProvider = ChatProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
      ],
      child: MaterialApp(
        home: ChatScreen(chatId: chatId),
      ),
    );
  }

  testWidgets('ChatScreen renders participants, messages and handles active vs closed state',
      (tester) async {
    final userA = UserModel(
      uid: 'user_a',
      email: 'a@college.edu',
      fullName: 'Rahul Borrower',
    );
    final userB = UserModel(
      uid: 'user_b',
      email: 'b@college.edu',
      fullName: 'Gokul Lender',
    );
    InMemoryStore.instance.users[userB.uid] = userB;

    // Setup active chat
    final chat = ChatModel(
      id: 'chat_test_123',
      requestId: 'req_123',
      itemId: 'item_1',
      itemName: 'Graphing Calculator',
      borrowerId: 'user_a',
      borrowerName: 'Rahul Borrower',
      lenderId: 'user_b',
      lenderName: 'Gokul Lender',
      participants: ['user_a', 'user_b'],
      status: 'active',
      lastMessage: 'Coordinate here',
      lastMessageTime: DateTime.now(),
    );
    InMemoryStore.instance.chats[chat.id] = chat;

    // Pump widget for User A
    final appA = await createChatScreenApp(
      currentUser: userA,
      chatId: chat.id,
    );
    await tester.pumpWidget(appA);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify AppBar shows Gokul Lender and item reference
    expect(find.text('Gokul Lender'), findsOneWidget);
    expect(find.text('Re: Graphing Calculator'), findsOneWidget);

    // Verify empty state initially
    expect(find.text('Say hi to Gokul Lender!'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Enter and send message
    await tester.enterText(find.byType(TextField), 'Hello, where can we meet?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Hello, where can we meet?'), findsOneWidget);
    expect(InMemoryStore.instance.messages[chat.id]!.length, 1);

    // Now test closed chat: update chat status to closed
    InMemoryStore.instance.chats[chat.id] = chat.copyWith(status: 'closed');
    InMemoryStore.instance.notifyChats();

    // Re-pump widget
    final appClosed = await createChatScreenApp(
      currentUser: userA,
      chatId: chat.id,
    );
    await tester.pumpWidget(appClosed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Closed indicator and banner
    expect(find.text('Closed'), findsOneWidget);
    expect(find.textContaining('This chat is closed because the helper was removed'), findsOneWidget);
    expect(find.text('This conversation has been closed.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('ChatScreen restricts access for unauthorized users (User C)',
      (tester) async {
    final userC = UserModel(
      uid: 'user_c',
      email: 'c@college.edu',
      fullName: 'Intruder Student',
    );

    final chat = ChatModel(
      id: 'chat_private_only',
      requestId: 'req_123',
      itemId: 'item_1',
      itemName: 'Scientific Calculator',
      borrowerId: 'user_a',
      borrowerName: 'User A',
      lenderId: 'user_b',
      lenderName: 'User B',
      participants: ['user_a', 'user_b'],
      status: 'active',
    );
    InMemoryStore.instance.chats[chat.id] = chat;

    final appC = await createChatScreenApp(
      currentUser: userC,
      chatId: chat.id,
    );
    await tester.pumpWidget(appC);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Access Denied
    expect(find.text('Access Denied'), findsOneWidget);
    expect(find.textContaining('This is a private conversation between the borrower and the accepted lender'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
