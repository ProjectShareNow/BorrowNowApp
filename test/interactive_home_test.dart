import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/models/borrow_request_model.dart';
import 'package:borrow_now/widgets/user_avatar.dart';
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
    InMemoryStore.instance.requests.clear();
  });

  testWidgets('Comprehensive interactive tests for all Home Screen elements', (WidgetTester tester) async {
    final user = UserModel(
      uid: 'test_user_1',
      fullName: 'Gokul Pavithran',
      email: 'gokul@campus.edu',
      registerNumber: 'REG123456',
      department: 'Computer Science',
      academicYear: 'Final Year',
      collegeId: 'REG123456',
      verificationStatus: 'verified',
    );
    InMemoryStore.instance.users[user.uid] = user;
    await ServiceRegistry.authService.login(email: user.email, password: 'any');

    final req = BorrowRequestModel(
      id: 'req_test_1',
      itemId: 'calc_1',
      itemName: 'Scientific Calculator fx-991EX',
      ownerId: 'campus',
      borrowerId: 'other_student_2',
      borrowerName: 'Sneha Patel',
      borrowerDepartment: 'Civil Engineering',
      requiredDate: DateTime.now().add(const Duration(hours: 3)),
      requiredTime: '2:00 PM',
      duration: '1 day',
      pickupLocation: 'Main Library',
      status: 'open',
    );
    InMemoryStore.instance.requests[req.id] = req;
    InMemoryStore.instance.notifyRequests();

    await tester.pumpWidget(
      MultiProvider(
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
          home: const MainNavigationScreen(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );

    await tester.pump();
    InMemoryStore.instance.notifyRequests();
    await tester.pump(const Duration(milliseconds: 500));

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // TEST 1: Request an Item button is clickable
    final requestBtn = find.text('+ Request an Item');
    expect(requestBtn, findsOneWidget);
    await tester.tap(requestBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Request an Item'), findsWidgets); // navigated to form screen

    // Pop back to Home
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // TEST 2: Campus Request Card does not navigate away when card is tapped
    final cardItemText = find.text('Scientific Calculator fx-991EX');
    expect(cardItemText, findsOneWidget);
    await tester.tap(cardItemText);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Verify still on Home screen
    expect(find.text('Campus Requests'), findsOneWidget);

    // TEST 3: I Can Help button is clickable
    final helpBtn = find.text('I Can Help');
    expect(helpBtn, findsOneWidget);
    await tester.tap(helpBtn);
    await tester.pump(); // confirm dialog opens
    await tester.pump(const Duration(milliseconds: 300));
    final confirmDialogBtn = find.text('I Can Help');
    expect(confirmDialogBtn, findsWidgets);

    // Cancel dialog
    final cancelBtn = find.text('Cancel');
    if (cancelBtn.evaluate().isNotEmpty) {
      await tester.tap(cancelBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    // TEST 4: Bottom navigation tabs are clickable
    // Tap My Items
    await tester.tap(find.text('My Items'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No Items Listed'), findsOneWidget);

    // Tap History
    await tester.tap(find.text('History'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Borrowing History'), findsOneWidget);

    // Tap Notifications
    await tester.tap(find.text('Notifications'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No Notifications Yet'), findsOneWidget);

    // Tap Chat
    await tester.tap(find.text('Chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No chats yet'), findsOneWidget);

    // Tap Home back
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Campus Requests'), findsOneWidget);

    // TEST 5: Top bar notification icon
    final notifIconBtn = find.byTooltip('Notifications');
    expect(notifIconBtn, findsOneWidget);
    await tester.tap(notifIconBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No Notifications Yet'), findsOneWidget);

    // Switch back to Home
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // TEST 6: Top bar UserAvatar
    final userAvatars = find.byType(UserAvatar);
    expect(userAvatars, findsWidgets);
    await tester.tap(userAvatars.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Gokul Pavithran'), findsWidgets);
  });
}
