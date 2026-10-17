import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/models/item_model.dart';
import 'package:borrow_now/providers/auth_provider.dart';
import 'package:borrow_now/providers/item_provider.dart';
import 'package:borrow_now/providers/request_provider.dart';
import 'package:borrow_now/providers/transaction_provider.dart';
import 'package:borrow_now/providers/chat_provider.dart';
import 'package:borrow_now/providers/notification_provider.dart';
import 'package:borrow_now/providers/admin_provider.dart';
import 'package:borrow_now/screens/items/my_listed_items_screen.dart';
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
    InMemoryStore.instance.items.clear();
  });

  Widget buildTestApp(AuthProvider authProvider, ItemProvider itemProvider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ItemProvider>.value(value: itemProvider),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: const MyListedItemsScreen(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }

  testWidgets('MyListedItemsScreen: Eye icon and View Requests are removed; Edit and Delete are present and functional', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testUser = UserModel(
      uid: 'user_items_test',
      fullName: 'Siddharth V',
      email: 'sid@campus.edu',
      registerNumber: 'REG2024CS077',
      collegeId: 'COLLEGE-07',
      department: AppConstants.departments.first,
      academicYear: AppConstants.academicYears.first,
      semester: 'Semester 5',
      verificationStatus: 'verified',
    );
    InMemoryStore.instance.users[testUser.uid] = testUser;
    await ServiceRegistry.authService.login(email: testUser.email, password: 'password');

    final testItem = ItemModel(
      id: 'item_test_101',
      name: 'Scientific Calculator fx-991EX',
      category: 'Electronics',
      description: 'Casio scientific calculator in working condition',
      condition: 'Like New',
      pickupLocation: 'CS Library 2nd Floor',
      ownerId: testUser.uid,
      ownerName: testUser.fullName,
      ownerDepartment: testUser.department,
      ownerRating: 4.9,
      availability: 'available',
    );
    final authProvider = AuthProvider();
    final itemProvider = ItemProvider();

    await ServiceRegistry.itemService.createItem(testItem);
    itemProvider.listenToUserItems(testUser.uid);

    await tester.pumpWidget(buildTestApp(authProvider, itemProvider));
    InMemoryStore.instance.notifyItems();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify item name is rendered
    expect(find.text('Scientific Calculator fx-991EX'), findsOneWidget);

    // 2. Verify Eye icon (visibility_outlined) is NOT present
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);

    // 3. Verify 'View Requests' text is NOT present
    expect(find.text('View Requests'), findsNothing);

    // 4. Verify 'Edit' button and icon are present
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    // 5. Verify 'Delete' button and icon are present
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    // 6. Test Delete confirmation dialog
    final deleteButton = find.byTooltip('Delete Item');
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Delete Item'), findsOneWidget);
    expect(find.text('Are you sure you want to remove "Scientific Calculator fx-991EX" from your listed items?'), findsOneWidget);

    // Cancel deletion
    final cancelBtn = find.text('Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Item is still present
    expect(find.text('Scientific Calculator fx-991EX'), findsOneWidget);
  });
}
