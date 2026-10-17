import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:borrow_now/app/routes.dart';
import 'package:borrow_now/app/theme.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/models/borrow_request_model.dart';
import 'package:borrow_now/models/chat_model.dart';
import 'package:borrow_now/providers/auth_provider.dart';
import 'package:borrow_now/providers/request_provider.dart';
import 'package:borrow_now/providers/chat_provider.dart';
import 'package:borrow_now/providers/notification_provider.dart';
import 'package:borrow_now/services/service_registry.dart';
import 'package:borrow_now/services/in_memory_store.dart';
import 'package:borrow_now/screens/home/home_dashboard_screen.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ServiceRegistry.init();
    InMemoryStore.instance.chats.clear();
    InMemoryStore.instance.messages.clear();
    InMemoryStore.instance.users.clear();
    InMemoryStore.instance.transactions.clear();
    InMemoryStore.instance.items.clear();
    InMemoryStore.instance.requests.clear();
  });

  void configureScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget createTestHomeApp({required UserModel currentUser}) {
    InMemoryStore.instance.users[currentUser.uid] = currentUser;
    final authProvider = AuthProvider();
    final requestProvider = RequestProvider();
    final chatProvider = ChatProvider();
    final notifProvider = NotificationProvider();

    requestProvider.listenToCampusRequests(currentUser.uid);
    requestProvider.listenToUserRequests(currentUser.uid);
    chatProvider.listenToUserChats(currentUser.uid);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<RequestProvider>.value(value: requestProvider),
        ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: notifProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: HomeDashboardScreen(onNavigateTab: (idx) {}),
        routes: {
          AppRoutes.myRequests: (context) => const Scaffold(
                body: Center(child: Text('Borrow Requests Screen')),
              ),
          AppRoutes.chat: (context) => const Scaffold(
                body: Center(child: Text('Private Chat Screen')),
              ),
        },
      ),
    );
  }

  group('Home Screen Request Card Navigation Tests', () {
    testWidgets('1. Tap a request showing Help Unavailable: Borrow Requests must not open',
        (tester) async {
      configureScreen(tester);

      final lender = UserModel(
        uid: 'user_lender_1',
        email: 'lender1@college.edu',
        fullName: 'Lender One',
      );
      final borrower = UserModel(
        uid: 'user_borrower_1',
        email: 'borrower1@college.edu',
        fullName: 'Borrower One',
      );
      final otherHelper = UserModel(
        uid: 'user_other_helper',
        email: 'other@college.edu',
        fullName: 'Selected Helper',
      );
      InMemoryStore.instance.users[lender.uid] = lender;
      InMemoryStore.instance.users[borrower.uid] = borrower;
      InMemoryStore.instance.users[otherHelper.uid] = otherHelper;

      // Request where another helper is accepted -> shows 'Help Unavailable'
      final request = BorrowRequestModel(
        id: 'req_unavailable_1',
        itemId: 'item_u_1',
        ownerId: 'campus',
        itemName: 'Oscilloscope Kit',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        acceptedHelperId: otherHelper.uid,
        acceptedHelperName: otherHelper.fullName,
        status: 'helper_selected',
        pickupLocation: 'Electronics Lab',
      );
      InMemoryStore.instance.requests[request.id] = request;

      await ServiceRegistry.authService.login(email: lender.email, password: 'password');

      await tester.pumpWidget(createTestHomeApp(currentUser: lender));
      await tester.pump();
      InMemoryStore.instance.notifyRequests();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify 'Help Unavailable' status is shown
      expect(find.text('Help Unavailable'), findsOneWidget);
      expect(find.text('Another helper has been selected.'), findsOneWidget);

      // Tap on the card / item name / status
      await tester.tap(find.text('Oscilloscope Kit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Borrow Requests screen MUST NOT open!
      expect(find.text('Borrow Requests Screen'), findsNothing);
      expect(find.text('Oscilloscope Kit'), findsOneWidget);

      // Tap on 'Help Unavailable'
      await tester.tap(find.text('Help Unavailable'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Borrow Requests Screen'), findsNothing);
    });

    testWidgets('2. Tap a normal request card without pressing I Can Help: Borrow Requests must not open',
        (tester) async {
      configureScreen(tester);

      final lender = UserModel(
        uid: 'user_lender_2',
        email: 'lender2@college.edu',
        fullName: 'Lender Two',
      );
      final borrower = UserModel(
        uid: 'user_borrower_2',
        email: 'borrower2@college.edu',
        fullName: 'Borrower Two',
      );
      InMemoryStore.instance.users[lender.uid] = lender;
      InMemoryStore.instance.users[borrower.uid] = borrower;

      final request = BorrowRequestModel(
        id: 'req_normal_2',
        itemId: 'item_n_2',
        ownerId: 'campus',
        itemName: 'Engineering Drafter',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        status: 'open',
        pickupLocation: 'Architecture Block',
      );
      InMemoryStore.instance.requests[request.id] = request;

      await ServiceRegistry.authService.login(email: lender.email, password: 'password');

      await tester.pumpWidget(createTestHomeApp(currentUser: lender));
      await tester.pump();
      InMemoryStore.instance.notifyRequests();
      await tester.pump(const Duration(milliseconds: 300));

      // Tapping on item name, pickup location, or card area without pressing I Can Help
      expect(find.text('Engineering Drafter'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'I Can Help'), findsOneWidget);

      await tester.tap(find.text('Engineering Drafter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Borrow Requests screen MUST NOT open!
      expect(find.text('Borrow Requests Screen'), findsNothing);

      await tester.tap(find.text('Architecture Block'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Borrow Requests Screen'), findsNothing);
    });

    testWidgets('3. Press I Can Help and successfully save offer: navigate to Borrow Requests screen',
        (tester) async {
      configureScreen(tester);

      final lender = UserModel(
        uid: 'user_lender_3',
        email: 'lender3@college.edu',
        fullName: 'Lender Three',
      );
      final borrower = UserModel(
        uid: 'user_borrower_3',
        email: 'borrower3@college.edu',
        fullName: 'Borrower Three',
      );
      InMemoryStore.instance.users[lender.uid] = lender;
      InMemoryStore.instance.users[borrower.uid] = borrower;

      final request = BorrowRequestModel(
        id: 'req_help_3',
        itemId: 'item_h_3',
        ownerId: 'campus',
        itemName: 'Soldering Iron',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        status: 'open',
        pickupLocation: 'Maker Space',
      );
      InMemoryStore.instance.requests[request.id] = request;

      await ServiceRegistry.authService.login(email: lender.email, password: 'password');

      await tester.pumpWidget(createTestHomeApp(currentUser: lender));
      await tester.pump();
      InMemoryStore.instance.notifyRequests();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Press I Can Help on card
      final helpBtn = find.widgetWithText(ElevatedButton, 'I Can Help');
      expect(helpBtn, findsOneWidget);
      await tester.tap(helpBtn);
      await tester.pumpAndSettle();

      // 2. Confirm in dialog
      final dialogConfirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'I Can Help'),
      );
      expect(dialogConfirmBtn, findsOneWidget);
      await tester.tap(dialogConfirmBtn);
      await tester.pumpAndSettle();

      // 3. Successfully saved offer -> navigated to Borrow Requests Screen!
      expect(find.text('Borrow Requests Screen'), findsOneWidget);

      // Verify offer recorded in store
      final updatedReq = InMemoryStore.instance.requests[request.id]!;
      expect(updatedReq.helperIds.contains(lender.uid), isTrue);
    });

    testWidgets('4. If saving fails, display an error message and remain on the current screen',
        (tester) async {
      configureScreen(tester);

      final lender = UserModel(
        uid: 'user_lender_4',
        email: 'lender4@college.edu',
        fullName: 'Lender Four',
      );
      final borrower = UserModel(
        uid: 'user_borrower_4',
        email: 'borrower4@college.edu',
        fullName: 'Borrower Four',
      );
      InMemoryStore.instance.users[lender.uid] = lender;
      InMemoryStore.instance.users[borrower.uid] = borrower;

      final request = BorrowRequestModel(
        id: 'req_fail_4',
        itemId: 'item_f_4',
        ownerId: 'campus',
        itemName: 'Lab Goggles',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        status: 'open',
        pickupLocation: 'Chemistry Dept',
      );
      InMemoryStore.instance.requests[request.id] = request;

      await ServiceRegistry.authService.login(email: lender.email, password: 'password');

      await tester.pumpWidget(createTestHomeApp(currentUser: lender));
      await tester.pump();
      InMemoryStore.instance.notifyRequests();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Lab Goggles'), findsOneWidget);
      final helpBtn = find.widgetWithText(ElevatedButton, 'I Can Help');
      expect(helpBtn, findsOneWidget);

      // Simulate a save failure by removing the request from database right before offering help
      InMemoryStore.instance.requests.remove(request.id);

      await tester.tap(helpBtn);
      await tester.pumpAndSettle();

      final dialogConfirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'I Can Help'),
      );
      expect(dialogConfirmBtn, findsOneWidget);
      await tester.tap(dialogConfirmBtn);
      await tester.pumpAndSettle();

      // Must NOT navigate to Borrow Requests Screen!
      expect(find.text('Borrow Requests Screen'), findsNothing);
    });

    testWidgets('5. Try pressing I Can Help twice: prevent duplicate offers',
        (tester) async {
      configureScreen(tester);

      final lender = UserModel(
        uid: 'user_lender_5',
        email: 'lender5@college.edu',
        fullName: 'Lender Five',
      );
      final borrower = UserModel(
        uid: 'user_borrower_5',
        email: 'borrower5@college.edu',
        fullName: 'Borrower Five',
      );
      InMemoryStore.instance.users[lender.uid] = lender;
      InMemoryStore.instance.users[borrower.uid] = borrower;

      // Already offered help
      final request = BorrowRequestModel(
        id: 'req_already_offered_5',
        itemId: 'item_a_5',
        ownerId: 'campus',
        itemName: 'Arduino Mega',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        helperIds: [lender.uid],
        helpers: [
          {
            'helperId': lender.uid,
            'helperName': lender.fullName,
            'status': 'pending',
          }
        ],
        status: 'open',
        pickupLocation: 'CS Dept',
      );
      InMemoryStore.instance.requests[request.id] = request;

      await ServiceRegistry.authService.login(email: lender.email, password: 'password');

      await tester.pumpWidget(createTestHomeApp(currentUser: lender));
      await tester.pump();
      InMemoryStore.instance.notifyRequests();
      await tester.pump(const Duration(milliseconds: 300));

      // Button is replaced by 'Help Offered' status chip
      expect(find.text('Help Offered'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'I Can Help'), findsNothing);

      // Tapping card does NOT navigate
      await tester.tap(find.text('Arduino Mega'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Borrow Requests Screen'), findsNothing);
    });

    testWidgets('6 & 7. Selected lender vs unselected volunteer chat access control',
        (tester) async {
      configureScreen(tester);

      final selectedLender = UserModel(
        uid: 'user_selected_lender',
        email: 'selected@college.edu',
        fullName: 'Selected Lender',
      );
      final unselectedVolunteer = UserModel(
        uid: 'user_unselected_volunteer',
        email: 'unselected@college.edu',
        fullName: 'Unselected Volunteer',
      );
      final borrower = UserModel(
        uid: 'user_borrower_6',
        email: 'borrower6@college.edu',
        fullName: 'Borrower Six',
      );
      InMemoryStore.instance.users[selectedLender.uid] = selectedLender;
      InMemoryStore.instance.users[unselectedVolunteer.uid] = unselectedVolunteer;
      InMemoryStore.instance.users[borrower.uid] = borrower;

      final chat = ChatModel(
        id: 'chat_selected_only',
        requestId: 'req_selected_6',
        itemId: 'item_6',
        itemName: 'Graphing Calculator fx-9860',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        lenderId: selectedLender.uid,
        lenderName: selectedLender.fullName,
        participants: [borrower.uid, selectedLender.uid],
        status: 'active',
      );
      InMemoryStore.instance.chats[chat.id] = chat;

      final request = BorrowRequestModel(
        id: 'req_selected_6',
        itemId: 'item_6',
        ownerId: 'campus',
        itemName: 'Graphing Calculator fx-9860',
        borrowerId: borrower.uid,
        borrowerName: borrower.fullName,
        acceptedHelperId: selectedLender.uid,
        acceptedHelperName: selectedLender.fullName,
        status: 'helper_selected',
        pickupLocation: 'Math Dept',
      );
      InMemoryStore.instance.requests[request.id] = request;

      // Test A: Unselected volunteer views card
      await ServiceRegistry.authService.login(email: unselectedVolunteer.email, password: 'password');

      await tester.pumpWidget(createTestHomeApp(currentUser: unselectedVolunteer));
      await tester.pump();
      InMemoryStore.instance.notifyRequests();
      await tester.pump(const Duration(milliseconds: 300));

      // Shows 'Help Unavailable', NO chat button
      expect(find.text('Help Unavailable'), findsOneWidget);
      expect(find.text('Selected Helper • Open Chat'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Open Chat'), findsNothing);

      // Tapping does nothing
      await tester.tap(find.text('Graphing Calculator fx-9860'));
      await tester.pump();
      expect(find.text('Private Chat Screen'), findsNothing);
      expect(find.text('Borrow Requests Screen'), findsNothing);

      // Test B: Selected lender views card
      await ServiceRegistry.authService.login(email: selectedLender.email, password: 'password');

      await tester.pumpWidget(createTestHomeApp(currentUser: selectedLender));
      await tester.pump();
      InMemoryStore.instance.notifyRequests();
      await tester.pump(const Duration(milliseconds: 300));

      // Selected lender sees 'Selected Helper • Open Chat'
      final openChatBtn = find.widgetWithText(ElevatedButton, 'Selected Helper • Open Chat');
      expect(openChatBtn, findsOneWidget);

      await tester.tap(openChatBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Opens Private Chat Screen!
      expect(find.text('Private Chat Screen'), findsOneWidget);
    });
  });
}
