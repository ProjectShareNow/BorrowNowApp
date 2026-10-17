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
import 'package:borrow_now/widgets/user_avatar.dart';
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

  Widget buildTestApp(AuthProvider authProvider, {int initialIndex = 0}) {
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
        home: MainNavigationScreen(initialIndex: initialIndex),
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }

  testWidgets('1. Bottom navigation shows Home, My Items, History, Notifications, Chat (Profile removed)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final user = UserModel(
      uid: 'user_nav_1',
      fullName: 'Gokul Student',
      email: 'gokul@campus.edu',
      registerNumber: 'REG123456',
    );
    InMemoryStore.instance.users[user.uid] = user;
    await ServiceRegistry.authService.login(email: user.email, password: 'password');

    final authProvider = AuthProvider();
    await tester.pumpWidget(buildTestApp(authProvider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Confirm navigation items in order
    expect(find.text('Home'), findsWidgets);
    expect(find.text('My Items'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Chat'), findsOneWidget);

    // Profile must NOT appear in bottom navigation
    expect(find.widgetWithText(InkWell, 'Profile'), findsNothing);
  });

  testWidgets('2. Chat tab displays accepted conversations list with participant, item, last message, unread badge', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final borrower = UserModel(
      uid: 'borrower_user_1',
      fullName: 'Aarav Patel',
      email: 'aarav@campus.edu',
    );
    final lender = UserModel(
      uid: 'lender_user_2',
      fullName: 'Sneha Sharma',
      email: 'sneha@campus.edu',
    );
    InMemoryStore.instance.users[borrower.uid] = borrower;
    InMemoryStore.instance.users[lender.uid] = lender;

    final acceptedChat = ChatModel(
      id: 'chat_accepted_1',
      requestId: 'req_accepted_1',
      itemId: 'item_1',
      itemName: 'Graphing Calculator',
      borrowerId: borrower.uid,
      borrowerName: borrower.fullName,
      lenderId: lender.uid,
      lenderName: lender.fullName,
      participants: [borrower.uid, lender.uid],
      status: 'active',
      lastMessage: 'I will bring it to the library at 3 PM',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 10)),
      unreadCountBorrower: 2,
    );
    InMemoryStore.instance.chats[acceptedChat.id] = acceptedChat;

    // Login as Borrower
    await ServiceRegistry.authService.login(email: borrower.email, password: 'password');
    final authBorrower = AuthProvider();
    await tester.pumpWidget(buildTestApp(authBorrower));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Chat tab in bottom navigation
    await tester.tap(find.text('Chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Borrower sees the accepted Lender's name, role badge, item name, message preview
    expect(find.text('Sneha Sharma'), findsOneWidget);
    expect(find.text('Lender'), findsOneWidget);
    expect(find.text('Graphing Calculator'), findsOneWidget);
    expect(find.text('I will bring it to the library at 3 PM'), findsOneWidget);
    expect(find.text('2'), findsWidgets); // unread badge

    // Tap conversation card -> Opens ChatScreen
    await tester.tap(find.text('Sneha Sharma'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Sneha Sharma'), findsWidgets);
    expect(find.textContaining('Graphing Calculator'), findsWidgets);
  });

  testWidgets('3. Selected lender sees borrower, and unselected volunteer sees empty state', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final borrower = UserModel(
      uid: 'b_uid',
      fullName: 'Aarav Patel',
      email: 'aarav@campus.edu',
    );
    final lender = UserModel(
      uid: 'l_uid',
      fullName: 'Sneha Sharma',
      email: 'sneha@campus.edu',
    );
    final volunteer = UserModel(
      uid: 'vol_uid',
      fullName: 'Random Student',
      email: 'volunteer@campus.edu',
    );
    InMemoryStore.instance.users[borrower.uid] = borrower;
    InMemoryStore.instance.users[lender.uid] = lender;
    InMemoryStore.instance.users[volunteer.uid] = volunteer;

    final acceptedChat = ChatModel(
      id: 'chat_flow_99',
      requestId: 'req_99',
      itemId: 'item_99',
      itemName: 'Digital Multimeter',
      borrowerId: borrower.uid,
      borrowerName: borrower.fullName,
      lenderId: lender.uid,
      lenderName: lender.fullName,
      participants: [borrower.uid, lender.uid],
      status: 'active',
      lastMessage: 'Meet at block B',
    );
    InMemoryStore.instance.chats[acceptedChat.id] = acceptedChat;

    // Login as Lender: should see Borrower
    await ServiceRegistry.authService.login(email: lender.email, password: 'password');
    final authLender = AuthProvider();
    await tester.pumpWidget(buildTestApp(authLender));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Aarav Patel'), findsOneWidget);
    expect(find.text('Borrower'), findsOneWidget);

    // Login as Volunteer: should see empty state
    await ServiceRegistry.authService.login(email: volunteer.email, password: 'password');
    final authVol = AuthProvider();
    await tester.pumpWidget(buildTestApp(authVol));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Aarav Patel'), findsNothing);
    expect(find.text('Sneha Sharma'), findsNothing);
    expect(find.text('No chats yet'), findsOneWidget);
    expect(find.text('Your accepted borrowing conversations will appear here.'), findsOneWidget);
  });

  testWidgets('4. Profile is still accessible via UserAvatar in Home and My Profile in Chat AppBar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final user = UserModel(
      uid: 'user_profile_access',
      fullName: 'Pooja Reddy',
      email: 'pooja@campus.edu',
      registerNumber: 'REG778899',
      department: 'Electrical Engineering',
      verificationStatus: 'verified',
    );
    InMemoryStore.instance.users[user.uid] = user;
    await ServiceRegistry.authService.login(email: user.email, password: 'password');

    final auth = AuthProvider();
    await tester.pumpWidget(buildTestApp(auth));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Profile avatar on Home screen header
    final avatar = find.byType(UserAvatar).first;
    await tester.tap(avatar);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Profile screen opened
    expect(find.text('Pooja Reddy'), findsWidgets);
    expect(find.text('Electrical Engineering'), findsOneWidget);
  });
}
