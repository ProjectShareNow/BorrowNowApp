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
import 'package:borrow_now/screens/profile/edit_profile_screen.dart';
import 'package:borrow_now/screens/profile/profile_screen.dart';
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

  testWidgets('Edit Profile: displays existing semester and updates it successfully to profile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testUser = UserModel(
      uid: 'user_semester_test',
      fullName: 'Vikram Patel',
      email: 'vikram@campus.edu',
      registerNumber: 'REG2024CS099',
      collegeId: 'COLLEGE-01',
      department: AppConstants.departments.first,
      academicYear: AppConstants.academicYears.first,
      semester: 'Semester 3',
      verificationStatus: 'verified',
    );
    InMemoryStore.instance.users[testUser.uid] = testUser;
    await ServiceRegistry.authService.login(email: testUser.email, password: 'password');

    final authProvider = AuthProvider();

    // Launch Profile screen first
    await tester.pumpWidget(buildAppWithHome(const ProfileScreen(), authProvider));
    await tester.pumpAndSettle();

    // Verify initial semester displayed on Profile screen
    expect(find.text('Semester 3'), findsOneWidget);

    // Tap Edit Profile shortcut button
    final editProfileButton = find.byTooltip('Edit Profile');
    expect(editProfileButton, findsOneWidget);
    await tester.tap(editProfileButton);
    await tester.pumpAndSettle();

    // Verify Edit Profile page is opened and current semester is selected
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Semester 3'), findsOneWidget);

    // Tap semester dropdown to change semester
    await tester.tap(find.text('Semester 3'));
    await tester.pumpAndSettle();

    // Select 'Semester 5'
    final sem5Item = find.text('Semester 5').last;
    await tester.tap(sem5Item);
    await tester.pumpAndSettle();

    // Click Save Changes button
    final saveButton = find.widgetWithText(ElevatedButton, 'Save Changes');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify snackbar message
    expect(find.text('Profile updated successfully!'), findsOneWidget);

    // Returned back to Profile Screen - verify updated semester appears immediately
    expect(find.text('Semester 5'), findsOneWidget);
    expect(authProvider.currentUser?.semester, equals('Semester 5'));
  });

  testWidgets('Edit Profile: displays Select Semester placeholder when user has no semester', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final newUser = UserModel(
      uid: 'user_no_semester',
      fullName: 'Ananya Rao',
      email: 'ananya@campus.edu',
      registerNumber: 'REG2024IT012',
      collegeId: 'COLLEGE-02',
      department: AppConstants.departments.first,
      academicYear: AppConstants.academicYears.first,
      semester: '',
      verificationStatus: 'verified',
    );
    InMemoryStore.instance.users[newUser.uid] = newUser;
    await ServiceRegistry.authService.login(email: newUser.email, password: 'password');

    final authProvider = AuthProvider();

    await tester.pumpWidget(buildAppWithHome(const EditProfileScreen(), authProvider));
    await tester.pumpAndSettle();

    // Check placeholder hint is shown
    expect(find.text('Select Semester'), findsOneWidget);

    // Tap the semester dropdown form field
    final semesterDropdown = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.decoration.labelText == 'Semester',
    );
    expect(semesterDropdown, findsOneWidget);
    await tester.tap(semesterDropdown);
    await tester.pumpAndSettle();

    final sem1Item = find.text('Semester 1').last;
    await tester.tap(sem1Item);
    await tester.pumpAndSettle();

    // Save Changes
    final saveButton = find.widgetWithText(ElevatedButton, 'Save Changes');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(authProvider.currentUser?.semester, equals('Semester 1'));
  });

  testWidgets('Edit Profile: validates semester selection before saving', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final newUser = UserModel(
      uid: 'user_val_test',
      fullName: 'Rahul Verma',
      email: 'rahul@campus.edu',
      registerNumber: 'REG2024CS050',
      collegeId: 'COLLEGE-03',
      department: AppConstants.departments.first,
      academicYear: AppConstants.academicYears.first,
      semester: '',
      verificationStatus: 'verified',
    );
    InMemoryStore.instance.users[newUser.uid] = newUser;
    await ServiceRegistry.authService.login(email: newUser.email, password: 'password');

    final authProvider = AuthProvider();

    await tester.pumpWidget(buildAppWithHome(const EditProfileScreen(), authProvider));
    await tester.pumpAndSettle();

    // Attempt to save without selecting a semester
    final saveButton = find.widgetWithText(ElevatedButton, 'Save Changes');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify error text is displayed
    expect(find.text('Please select your semester'), findsOneWidget);
    // User semester is still empty
    expect(authProvider.currentUser?.semester, isEmpty);
  });

  testWidgets('Edit Profile: does not contain My Listed Items and Cancel button navigates back without saving', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final user = UserModel(
      uid: 'user_cancel_test',
      fullName: 'Meera Nair',
      email: 'meera@campus.edu',
      registerNumber: 'REG2024EC100',
      collegeId: 'COLLEGE-04',
      department: AppConstants.departments.first,
      academicYear: AppConstants.academicYears.first,
      semester: 'Semester 4',
      verificationStatus: 'verified',
    );
    InMemoryStore.instance.users[user.uid] = user;
    await ServiceRegistry.authService.login(email: user.email, password: 'password');

    final authProvider = AuthProvider();

    // Start on Profile Screen
    await tester.pumpWidget(buildAppWithHome(const ProfileScreen(), authProvider));
    await tester.pumpAndSettle();

    // Open Edit Profile
    final editProfileButton = find.byTooltip('Edit Profile');
    await tester.tap(editProfileButton);
    await tester.pumpAndSettle();

    // 1. Verify "My Listed Items" is NOT present on Edit Profile screen
    expect(find.text('My Listed Items'), findsNothing);

    // 2. Verify Cancel button exists
    final cancelButton = find.widgetWithText(OutlinedButton, 'Cancel');
    expect(cancelButton, findsOneWidget);

    // 3. Change semester dropdown to Semester 8
    final semesterDropdown = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.decoration.labelText == 'Semester',
    );
    await tester.tap(semesterDropdown);
    await tester.pumpAndSettle();

    final sem8Item = find.text('Semester 8').last;
    await tester.tap(sem8Item);
    await tester.pumpAndSettle();

    // 4. Tap Cancel instead of Save Changes
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    // Returned to Profile Screen
    expect(find.text('Profile'), findsOneWidget);
    // Semester should still be 'Semester 4' (unchanged)
    expect(authProvider.currentUser?.semester, equals('Semester 4'));
    expect(find.text('Semester 4'), findsOneWidget);
  });

  testWidgets('Profile Screen: profile editing is accessible ONLY through the single top-right Edit icon', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final user = UserModel(
      uid: 'user_top_icon_only',
      fullName: 'Divya Krishnan',
      email: 'divya@campus.edu',
      registerNumber: 'REG2024CS088',
      collegeId: 'COLLEGE-05',
      department: AppConstants.departments.first,
      academicYear: AppConstants.academicYears.first,
      semester: 'Semester 6',
      verificationStatus: 'verified',
    );
    InMemoryStore.instance.users[user.uid] = user;
    await ServiceRegistry.authService.login(email: user.email, password: 'password');

    final authProvider = AuthProvider();

    await tester.pumpWidget(buildAppWithHome(const ProfileScreen(), authProvider));
    await tester.pumpAndSettle();

    // 1. Exactly ONE edit icon on the entire Profile page (the top-right AppBar action)
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byTooltip('Edit Profile'), findsOneWidget);

    // 2. NO Edit Profile text button, link, or ListTile in the Profile body
    expect(find.text('Edit Profile'), findsNothing);

    // 3. NO My Listed Items on the Profile page
    expect(find.text('My Listed Items'), findsNothing);

    // 4. Information is read-only (no FormField or TextFormField on Profile screen)
    expect(find.byType(TextFormField), findsNothing);

    // 5. Tapping top-right edit icon opens Edit Profile
    await tester.tap(find.byTooltip('Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Divya Krishnan'), findsOneWidget);
    expect(find.text('Semester 6'), findsOneWidget);
  });
}



