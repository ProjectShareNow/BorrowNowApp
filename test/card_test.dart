import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:borrow_now/models/item_model.dart';
import 'package:borrow_now/models/borrow_request_model.dart';
import 'package:borrow_now/widgets/item_card.dart';
import 'package:borrow_now/widgets/request_card.dart';
import 'package:borrow_now/app/theme.dart';

void main() {
  testWidgets('ItemCard: renders vertical item card and handles onTap', (WidgetTester tester) async {
    final item = ItemModel(
      id: 'item_1',
      name: 'Wireless Presenter Pointer',
      category: 'Electronics',
      description: 'Plug and play USB presenter with red laser',
      ownerId: 'owner_1',
      ownerName: 'Gokul',
      availability: 'available',
      pickupLocation: 'Academic Block 3',
      condition: 'Like New',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: ItemCard(
            item: item,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Wireless Presenter Pointer'), findsOneWidget);
    expect(find.text('ELECTRONICS'), findsOneWidget);
    expect(find.text('Academic Block 3'), findsOneWidget);

    await tester.tap(find.text('Wireless Presenter Pointer'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('ItemCard: renders horizontal layout mode cleanly', (WidgetTester tester) async {
    final item = ItemModel(
      id: 'item_2',
      name: 'Lab Coat (Size L)',
      category: 'Clothing',
      description: 'White chemistry lab coat',
      ownerId: 'owner_2',
      ownerName: 'Rahul',
      availability: 'borrowed',
      pickupLocation: 'Chemistry Dept',
      condition: 'Good',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: ItemCard(
            item: item,
            isHorizontal: true,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Lab Coat (Size L)'), findsOneWidget);
    expect(find.text('Clothing'), findsOneWidget);
  });

  testWidgets('RequestCard: renders request details and handles onTap and actions', (WidgetTester tester) async {
    final request = BorrowRequestModel(
      id: 'req_card_1',
      itemId: 'item_card_1',
      itemName: 'Scientific Calculator fx-991EX',
      ownerId: 'campus',
      borrowerId: 'borrower_1',
      borrowerName: 'Sneha Patel',
      borrowerDepartment: 'Civil Engineering',
      requiredDate: DateTime.now().add(const Duration(days: 1)),
      requiredTime: '10:00 AM',
      duration: '2 days',
      pickupLocation: 'Central Library',
      status: 'open',
      message: 'Need for surveying lab exam',
    );

    bool cardTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RequestCard(
              request: request,
              isIncoming: true,
              onTap: () {
                cardTapped = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Scientific Calculator fx-991EX'), findsOneWidget);
    expect(find.text('Sneha Patel'), findsOneWidget);
    expect(find.text('Civil Engineering'), findsOneWidget);
    expect(find.text('Pickup: Central Library'), findsOneWidget);
    expect(find.text('"Need for surveying lab exam"'), findsOneWidget);

    await tester.tap(find.text('Scientific Calculator fx-991EX'));
    await tester.pump();
    expect(cardTapped, isTrue);
  });

  testWidgets('RequestCard: renders helper locking status when helpers offered', (WidgetTester tester) async {
    final requestWithHelpers = BorrowRequestModel(
      id: 'req_card_2',
      itemId: 'item_card_2',
      itemName: 'Digital Multimeter',
      ownerId: 'campus',
      borrowerId: 'me',
      borrowerName: 'My Request',
      requiredDate: DateTime.now().add(const Duration(days: 1)),
      requiredTime: '2:00 PM',
      duration: '1 day',
      pickupLocation: 'ECE Lab',
      status: 'open',
      acceptedHelperId: 'helper_1',
      helpers: [
        {
          'helperId': 'helper_1',
          'name': 'Gokul Pavithran',
          'department': 'Computer Applications',
        },
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RequestCard(
              request: requestWithHelpers,
              isIncoming: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Digital Multimeter'), findsOneWidget);
    expect(find.text('Helpers'), findsOneWidget);
    expect(find.text('Helper Locked'), findsOneWidget);
    expect(find.textContaining('Gokul Pavithran'), findsOneWidget);
  });
}
