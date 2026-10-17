import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:borrow_now/models/user_model.dart';
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
    InMemoryStore.instance.requests.clear();
    InMemoryStore.instance.notifications.clear();
  });

  Widget buildTestApp({int initialIndex = 0}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

  testWidgets('Navigation Layout: renders all 5 bottom navigation tabs and switches tabs correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testUser = UserModel(
      uid: 'nav_test_user',
      fullName: 'Gokul Pavithran',
      email: 'gokul@campus.edu',
      registerNumber: 'REG987654',
      department: 'Computer Science',
      academicYear: 'Final Year',
      collegeId: 'REG987654',
      verificationStatus: 'verified',
    );
    InMemoryStore.instance.users[testUser.uid] = testUser;
    await ServiceRegistry.authService.login(email: testUser.email, password: 'password');

    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify all 5 tab labels are visible in the navigation bar
    expect(find.text('Home'), findsWidgets);
    expect(find.text('My Items'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);

    // Initial tab is Home (index 0)
    expect(find.text('Campus Requests'), findsOneWidget);

    // Tap Tab 1: My Items
    await tester.tap(find.text('My Items'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No Items Listed'), findsOneWidget);

    // Tap Tab 2: History
    await tester.tap(find.text('History'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Borrowing History'), findsOneWidget);

    // Tap Tab 3: Notifications
    await tester.tap(find.text('Notifications').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No Notifications Yet'), findsOneWidget);

    // Tap Tab 4: Chat
    await tester.tap(find.text('Chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No chats yet'), findsOneWidget);

    // Tap Tab 0: Home
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Campus Requests'), findsOneWidget);

    // Verify Profile is accessible via UserAvatar
    final userAvatar = find.byType(UserAvatar).first;
    await tester.tap(userAvatar);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Gokul Pavithran'), findsWidgets);
  });
}
