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
import 'package:borrow_now/screens/profile/profile_screen.dart';
import 'package:borrow_now/app/theme.dart';
import 'package:borrow_now/app/routes.dart';
import 'package:borrow_now/services/service_registry.dart';
import 'package:borrow_now/services/in_memory_store.dart';
import 'package:borrow_now/utils/helpers.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ServiceRegistry.init();
    InMemoryStore.instance.users.clear();
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
        home: const ProfileScreen(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }

  testWidgets('Profile Layout: renders user details, verification badge, stats, and shortcuts cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testUser = UserModel(
      uid: 'profile_user_1',
      fullName: 'Aravind Kumar',
      email: 'aravind@campus.edu',
      registerNumber: 'REG2024CS001',
      collegeId: 'COLLEGE-NIT-01',
      department: 'Computer Science & Engineering',
      academicYear: 'Third Year',
      verificationStatus: 'verified',
      itemsListedCount: 4,
      borrowedCount: 7,
      ratingAverage: 4.8,
      ratingsCount: 5,
    );
    InMemoryStore.instance.users[testUser.uid] = testUser;
    await ServiceRegistry.authService.login(email: testUser.email, password: 'password');

    final authProvider = AuthProvider();
    await tester.pumpWidget(buildTestApp(authProvider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify User Header
    expect(find.text('Aravind Kumar'), findsOneWidget);
    expect(find.text('aravind@campus.edu'), findsOneWidget);
    expect(find.text('Verified Student'), findsOneWidget);

    // Verify Statistics
    expect(find.text('Items Listed'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Completed Loans'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Rating'), findsOneWidget);
    expect(find.text('4.8 / 5.0 (5 reviews)'), findsWidgets);

    // Verify Verification Details Card
    expect(find.text('Verification Information'), findsOneWidget);
    expect(find.text('College ID'), findsNothing);
    expect(find.text('Register Number'), findsOneWidget);
    expect(find.text(AppHelpers.maskRegisterNumber('REG2024CS001')), findsOneWidget);
    expect(find.text('Computer Science & Engineering'), findsOneWidget);
    expect(find.text('Third Year'), findsOneWidget);

    // Verify Single Top-Right Edit Icon and No Body Edit Profile button
    expect(find.byTooltip('Edit Profile'), findsOneWidget);
    expect(find.text('Edit Profile'), findsNothing);
    expect(find.text('My Listed Items'), findsNothing);
    expect(find.text('Sign Out'), findsOneWidget);

    // Verify Sign Out button is interactive
    final signOutBtn = find.text('Sign Out');
    expect(signOutBtn, findsOneWidget);
    await tester.tap(signOutBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify confirmation dialog opens
    expect(find.text('Are you sure you want to sign out of BorrowNow?'), findsOneWidget);
    final cancelBtn = find.text('Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('Profile Layout: renders pending verification badge for unverified users', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final pendingUser = UserModel(
      uid: 'profile_user_pending',
      fullName: 'Priya Sharma',
      email: 'priya@campus.edu',
      registerNumber: 'REG2024EC042',
      collegeId: 'COLLEGE-02',
      department: 'Electronics',
      academicYear: 'First Year',
      verificationStatus: 'pending',
    );
    InMemoryStore.instance.users[pendingUser.uid] = pendingUser;
    await ServiceRegistry.authService.login(email: pendingUser.email, password: 'password');

    final authProvider = AuthProvider();
    await tester.pumpWidget(buildTestApp(authProvider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Verification Pending'), findsOneWidget);
  });
}
