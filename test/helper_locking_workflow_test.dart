import 'package:flutter_test/flutter_test.dart';
import 'package:borrow_now/services/service_registry.dart';
import 'package:borrow_now/models/borrow_request_model.dart';
import 'package:borrow_now/models/user_model.dart';
import 'package:borrow_now/services/in_memory_store.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ServiceRegistry.init();
    InMemoryStore.instance.requests.clear();
  });

  test('Single Accepted Helper Locking Workflow', () async {
    final requestService = ServiceRegistry.borrowRequestService;

    // User A creates Scientific Calculator request
    final req = BorrowRequestModel(
      id: 'req_123',
      itemId: 'item_calc',
      itemName: 'Scientific Calculator fx-991EX',
      ownerId: 'campus_community',
      borrowerId: 'user_a',
      borrowerName: 'Rahul Verma',
      requiredDate: DateTime.now().add(const Duration(hours: 4)),
      requiredTime: '4:00 PM',
      duration: '1 day',
      pickupLocation: 'College Library',
      status: 'open',
    );

    await requestService.submitRequest(req);

    // Initial state: request is open, acceptedHelperId is null
    var storedReq = InMemoryStore.instance.requests['req_123']!;
    expect(storedReq.status, 'open');
    expect(storedReq.acceptedHelperId, isNull);

    // User B (Gokul) offers help
    final userB = UserModel(
      uid: 'user_b',
      email: 'gokul@cet.ac.in',
      fullName: 'Gokul Pavithran',
      department: 'Computer Applications',
    );

    await requestService.offerHelp(requestId: 'req_123', helperUser: userB);

    storedReq = InMemoryStore.instance.requests['req_123']!;
    expect(storedReq.helperIds.contains('user_b'), isTrue);
    expect(storedReq.helpers.any((h) => h['helperId'] == 'user_b'), isTrue);

    // User C (Anjali) also offers help while open
    final userC = UserModel(
      uid: 'user_c',
      email: 'anjali@cet.ac.in',
      fullName: 'Anjali Nair',
      department: 'Electronics',
    );

    await requestService.offerHelp(requestId: 'req_123', helperUser: userC);

    storedReq = InMemoryStore.instance.requests['req_123']!;
    expect(storedReq.helperIds.length, 2);

    // User A ACCEPTS User B (Gokul)
    await requestService.acceptHelper(
      requestId: 'req_123',
      requesterId: 'user_a',
      helperId: 'user_b',
      helperName: 'Gokul Pavithran',
    );

    storedReq = InMemoryStore.instance.requests['req_123']!;
    expect(storedReq.status, 'helper_selected');
    expect(storedReq.acceptedHelperId, 'user_b');
    expect(storedReq.acceptedHelperName, 'Gokul Pavithran');

    // Attempting to accept User C now must fail because User B is already accepted
    expect(
      () => requestService.acceptHelper(
        requestId: 'req_123',
        requesterId: 'user_a',
        helperId: 'user_c',
        helperName: 'Anjali Nair',
      ),
      throwsA(isA<Exception>()),
    );

    // User D attempts to offer help when helper is already selected -> rejected
    final userD = UserModel(
      uid: 'user_d',
      email: 'vikram@cet.ac.in',
      fullName: 'Vikram S',
    );
    expect(
      () => requestService.offerHelp(requestId: 'req_123', helperUser: userD),
      throwsA(isA<Exception>()),
    );

    // User A removes/rejects User B (Gokul)
    await requestService.removeAcceptedHelper(
      requestId: 'req_123',
      requesterId: 'user_a',
      helperId: 'user_b',
    );

    storedReq = InMemoryStore.instance.requests['req_123']!;
    expect(storedReq.status, 'open');
    expect(storedReq.acceptedHelperId, isNull);
    expect(storedReq.rejectedHelperIds.contains('user_b'), isTrue);

    // Now User C can be accepted!
    await requestService.acceptHelper(
      requestId: 'req_123',
      requesterId: 'user_a',
      helperId: 'user_c',
      helperName: 'Anjali Nair',
    );

    storedReq = InMemoryStore.instance.requests['req_123']!;
    expect(storedReq.status, 'helper_selected');
    expect(storedReq.acceptedHelperId, 'user_c');
    expect(storedReq.acceptedHelperName, 'Anjali Nair');
  });
}
