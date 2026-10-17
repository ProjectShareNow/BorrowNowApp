import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:borrow_now/models/borrow_request_model.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/providers/auth_provider.dart';
import 'package:borrow_now/providers/item_provider.dart';
import 'package:borrow_now/providers/request_provider.dart';
import 'package:borrow_now/providers/transaction_provider.dart';
import 'package:borrow_now/providers/chat_provider.dart';
import 'package:borrow_now/providers/notification_provider.dart';
import 'package:borrow_now/providers/admin_provider.dart';
import 'package:borrow_now/screens/requests/borrow_request_form_screen.dart';
import 'package:borrow_now/screens/home/main_navigation_screen.dart';
import 'package:borrow_now/widgets/request_card.dart';
import 'package:borrow_now/app/theme.dart';
import 'package:borrow_now/app/routes.dart';
import 'package:borrow_now/services/service_registry.dart';
import 'package:borrow_now/services/in_memory_store.dart';
import 'package:borrow_now/utils/constants.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ServiceRegistry.init();
    InMemoryStore.instance.users.clear();
    InMemoryStore.instance.requests.clear();
  });

  Widget buildAppWithHome(Widget home, AuthProvider authProvider) {
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
        home: home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }

  test('BorrowRequestModel: optional fields do not write placeholders in toMap', () {
    final req = BorrowRequestModel(
      id: 'req_test_101',
      itemId: 'req_test_101',
      itemName: 'Scientific Calculator',
      ownerId: 'campus',
      borrowerId: 'user_1',
      borrowerName: 'Gokul P',
      pickupLocation: 'Central Library',
    );

    final map = req.toMap();
    expect(map.containsKey('requiredDate'), isFalse);
    expect(map.containsKey('needUntil'), isFalse);
    expect(map.containsKey('duration'), isFalse);
    expect(map.containsKey('itemPhotoUrl'), isFalse);
    expect(map.containsKey('itemImageUrl'), isFalse);
    expect(req.requiredDate, isNull);
    expect(req.duration, isEmpty);
    expect(req.itemPhotoUrl, isEmpty);

    // Parsing back from map
    final parsed = BorrowRequestModel.fromMap(map);
    expect(parsed.requiredDate, isNull);
    expect(parsed.duration, isEmpty);
    expect(parsed.itemPhotoUrl, isEmpty);
    expect(parsed.itemName, 'Scientific Calculator');
  });

  testWidgets('BorrowRequestFormScreen: Image Upload, Need Until Date, and Duration are removed', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testUser = UserModel(
      uid: 'user_request_test',
      fullName: 'Aarav Sharma',
      email: 'aarav@campus.edu',
      registerNumber: 'REG2024CS055',
      collegeId: 'COLLEGE-01',
      department: AppConstants.departments.first,
      academicYear: AppConstants.academicYears.first,
      semester: 'Semester 4',
      verificationStatus: 'verified',
    );
    InMemoryStore.instance.users[testUser.uid] = testUser;
    await ServiceRegistry.authService.login(email: testUser.email, password: 'password');

    final authProvider = AuthProvider();

    await tester.pumpWidget(buildAppWithHome(const BorrowRequestFormScreen(), authProvider));
    await tester.pumpAndSettle();

    // 1. Verify removed elements do NOT exist
    expect(find.text('Item Image'), findsNothing);
    expect(find.text('Upload Image'), findsNothing);
    expect(find.text('Need Until Date *'), findsNothing);
    expect(find.text('Need Until Date'), findsNothing);
    expect(find.text('Borrow Duration *'), findsNothing);
    expect(find.text('Borrow Duration'), findsNothing);
    expect(find.text('1 day'), findsNothing);

    // 2. Verify remaining elements DO exist
    expect(find.text('Item Name *'), findsOneWidget);
    expect(find.text('Category *'), findsOneWidget);
    expect(find.text('Need Until Time *'), findsOneWidget);
    expect(find.text('Campus Pickup Location *'), findsOneWidget);
    expect(find.text('Note / Reason (Optional)'), findsOneWidget);
    expect(find.text('Post Request'), findsOneWidget);

    // 3. Fill in item name and submit request
    await tester.enterText(find.widgetWithText(TextField, '').first, 'Digital Oscilloscope');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post Request'));
    await tester.pumpAndSettle();

    // 4. Verify request was stored in memory without image, date, or duration
    expect(InMemoryStore.instance.requests.isNotEmpty, isTrue);
    final createdReq = InMemoryStore.instance.requests.values.first;
    expect(createdReq.itemName, 'Digital Oscilloscope');
    expect(createdReq.requiredDate, isNull);
    expect(createdReq.duration, isEmpty);
    expect(createdReq.itemPhotoUrl, isEmpty);
  });

  testWidgets('RequestCard and HomeDashboardScreen handle missing date, duration, and image safely', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testUser = UserModel(
      uid: 'user_card_consumer',
      fullName: 'Meera Nair',
      email: 'meera@campus.edu',
      registerNumber: 'REG2024CS088',
      collegeId: 'COLLEGE-01',
      department: AppConstants.departments.first,
      academicYear: AppConstants.academicYears.first,
      semester: 'Semester 6',
      verificationStatus: 'verified',
    );
    InMemoryStore.instance.users[testUser.uid] = testUser;
    await ServiceRegistry.authService.login(email: testUser.email, password: 'password');

    final authProvider = AuthProvider();

    final simplifiedRequest = BorrowRequestModel(
      id: 'req_simplified_1',
      itemId: 'item_sim_1',
      itemName: 'Lab Multimeter',
      ownerId: 'campus_community',
      borrowerId: 'other_student_123',
      borrowerName: 'Sneha Patel',
      borrowerDepartment: 'Civil Engineering',
      pickupLocation: 'Central Library',
      requiredTime: '04:00 PM',
      status: 'open',
    );

    // Test RequestCard rendering
    await tester.pumpWidget(
      buildAppWithHome(
        Scaffold(body: RequestCard(request: simplifiedRequest)),
        authProvider,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Request for Lab Multimeter'), findsOneWidget);
    expect(find.text('Pickup: Central Library'), findsOneWidget);
    expect(find.text('Time: 04:00 PM'), findsOneWidget);

    // Test HomeDashboardScreen rendering with this request in the feed
    InMemoryStore.instance.requests[simplifiedRequest.id] = simplifiedRequest;

    await tester.pumpWidget(
      buildAppWithHome(
        const MainNavigationScreen(),
        authProvider,
      ),
    );
    await tester.pump();
    InMemoryStore.instance.notifyRequests();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Lab Multimeter'), findsOneWidget);
    expect(find.text('Central Library'), findsOneWidget);
  });
}
