import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/models/chat_model.dart';
import 'package:borrow_now/providers/auth_provider.dart';
import 'package:borrow_now/providers/item_provider.dart';
import 'package:borrow_now/providers/request_provider.dart';
import 'package:borrow_now/providers/transaction_provider.dart';
import 'package:borrow_now/providers/chat_provider.dart';
import 'package:borrow_now/providers/notification_provider.dart';
import 'package:borrow_now/providers/admin_provider.dart';
import 'package:borrow_now/screens/home/main_navigation_screen.dart';
import 'package:borrow_now/app/theme.dart';
import 'package:borrow_now/app/routes.dart';
import 'package:borrow_now/services/service_registry.dart';
import 'package:borrow_now/services/in_memory_store.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ServiceRegistry.init();
    InMemoryStore.instance.chats.clear();
    InMemoryStore.instance.messages.clear();
    InMemoryStore.instance.users.clear();
    InMemoryStore.instance.requests.clear();
    InMemoryStore.instance.transactions.clear();
    InMemoryStore.instance.items.clear();
    InMemoryStore.instance.notifications.clear();
  });

  Widget buildTestApp(AuthProvider authProvider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: const MainNavigationScreen(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }

  testWidgets('1. Home screen displays Chats section with empty state when user has no accepted chats', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final user = UserModel(
      uid: 'user_borrower_1',
      fullName: 'Rahul Sharma',
      email: 'rahul@campus.edu',
    );
    InMemoryStore.instance.users[user.uid] = user;
    await ServiceRegistry.authService.login(email: user.email, password: 'password');

    final authProvider = AuthProvider();
    await tester.pumpWidget(buildTestApp(authProvider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Chats section header is present
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Accepted requests and active conversations'), findsOneWidget);

    // Verify empty state is displayed
    expect(find.text('No chats yet'), findsOneWidget);
    expect(
      find.text('Your accepted borrowing conversations will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('2. Borrower sees accepted lender in Home Chats list, and selected lender sees borrower', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final borrower = UserModel(
      uid: 'borrower_id_10',
      fullName: 'Ananya Roy',
      email: 'ananya@campus.edu',
    );
    final lender = UserModel(
      uid: 'lender_id_20',
      fullName: 'Vikram Singh',
      email: 'vikram@campus.edu',
    );
    final unrelatedUser = UserModel(
      uid: 'volunteer_id_30',
      fullName: 'Karthik Rao',
      email: 'karthik@campus.edu',
    );
    InMemoryStore.instance.users[borrower.uid] = borrower;
    InMemoryStore.instance.users[lender.uid] = lender;
    InMemoryStore.instance.users[unrelatedUser.uid] = unrelatedUser;

    final chat = ChatModel(
      id: 'chat_req10_borrower10_lender20',
      requestId: 'req_10',
      itemId: 'item_10',
      itemName: 'Scientific Calculator fx-991EX',
      borrowerId: borrower.uid,
      borrowerName: borrower.fullName,
      lenderId: lender.uid,
      lenderName: lender.fullName,
      participants: [borrower.uid, lender.uid],
      status: 'active',
      lastMessage: 'I will bring the calculator to the library at 2 PM.',
      lastMessageTime: DateTime.now(),
      unreadCountBorrower: 1,
      unreadCountOwner: 0,
    );
    InMemoryStore.instance.chats[chat.id] = chat;
    InMemoryStore.instance.notifyChats();

    // --- TEST AS BORROWER ---
    await ServiceRegistry.authService.login(email: borrower.email, password: 'password');
    final authBorrower = AuthProvider();
    await tester.pumpWidget(buildTestApp(authBorrower));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Borrower should see Vikram Singh (Lender)
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Vikram Singh'), findsOneWidget);
    expect(find.text('Lender'), findsOneWidget);
    expect(find.text('Scientific Calculator fx-991EX'), findsWidgets);
    expect(find.text('I will bring the calculator to the library at 2 PM.'), findsOneWidget);

    // --- TEST AS SELECTED LENDER ---
    await ServiceRegistry.authService.login(email: lender.email, password: 'password');
    final authLender = AuthProvider();
    await tester.pumpWidget(buildTestApp(authLender));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Lender should see Ananya Roy (Borrower)
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Ananya Roy'), findsOneWidget);
    expect(find.text('Borrower'), findsOneWidget);
    expect(find.text('Scientific Calculator fx-991EX'), findsWidgets);

    // --- TEST AS UNRELATED / UNSELECTED VOLUNTEER ---
    await ServiceRegistry.authService.login(email: unrelatedUser.email, password: 'password');
    final authVolunteer = AuthProvider();
    await tester.pumpWidget(buildTestApp(authVolunteer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Unrelated volunteer should NOT see this conversation
    expect(find.text('Ananya Roy'), findsNothing);
    expect(find.text('Vikram Singh'), findsNothing);
    expect(find.text('No chats yet'), findsOneWidget);
  });

  testWidgets('3. Tapping a chat card in Home screen opens the private Chat Screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final borrower = UserModel(
      uid: 'borrower_id_50',
      fullName: 'Pooja Hegde',
      email: 'pooja@campus.edu',
    );
    final lender = UserModel(
      uid: 'lender_id_60',
      fullName: 'Rohan Mehra',
      email: 'rohan@campus.edu',
    );
    InMemoryStore.instance.users[borrower.uid] = borrower;
    InMemoryStore.instance.users[lender.uid] = lender;

    final chat = ChatModel(
      id: 'chat_test_tap_1',
      requestId: 'req_50',
      itemId: 'item_50',
      itemName: 'Lab Coat XL',
      borrowerId: borrower.uid,
      borrowerName: borrower.fullName,
      lenderId: lender.uid,
      lenderName: lender.fullName,
      participants: [borrower.uid, lender.uid],
      status: 'active',
      lastMessage: 'Ready for handover!',
      lastMessageTime: DateTime.now(),
    );
    InMemoryStore.instance.chats[chat.id] = chat;
    InMemoryStore.instance.notifyChats();

    await ServiceRegistry.authService.login(email: borrower.email, password: 'password');
    final auth = AuthProvider();
    await tester.pumpWidget(buildTestApp(auth));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap the chat card
    final chatCard = find.text('Rohan Mehra');
    expect(chatCard, findsOneWidget);
    await tester.tap(chatCard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Chat screen is pushed (app bar shows recipient name and item)
    expect(find.text('Rohan Mehra'), findsWidgets);
    expect(find.textContaining('Lab Coat XL'), findsWidgets);
  });
}
