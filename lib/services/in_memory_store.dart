import 'dart:async';
import '../models/user_model.dart';
import '../models/item_model.dart';
import '../models/borrow_request_model.dart';
import '../models/transaction_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/rating_model.dart';
import '../models/report_model.dart';

/// In-memory reactive store used when Firebase is not yet initialized.
/// Allows full end-to-end testing of every screen, transition, and workflow.
class InMemoryStore {
  static final InMemoryStore instance = InMemoryStore._internal();
  InMemoryStore._internal() {
    _seedData();
  }

  // Stores
  final Map<String, UserModel> users = {};
  final Map<String, ItemModel> items = {};
  final Map<String, BorrowRequestModel> requests = {};
  final Map<String, TransactionModel> transactions = {};
  final Map<String, ChatModel> chats = {};
  final Map<String, List<MessageModel>> messages = {};
  final Map<String, NotificationModel> notifications = {};
  final Map<String, RatingModel> ratings = {};
  final Map<String, ReportModel> reports = {};

  // Stream Controllers for reactive UI updates
  final _usersStreamController = StreamController<List<UserModel>>.broadcast();
  final _itemsStreamController = StreamController<List<ItemModel>>.broadcast();
  final _requestsStreamController =
      StreamController<List<BorrowRequestModel>>.broadcast();
  final _transactionsStreamController =
      StreamController<List<TransactionModel>>.broadcast();
  final _chatsStreamController = StreamController<List<ChatModel>>.broadcast();
  final _notificationsStreamController =
      StreamController<List<NotificationModel>>.broadcast();
  final _reportsStreamController =
      StreamController<List<ReportModel>>.broadcast();
  final Map<String, StreamController<List<MessageModel>>>
  _chatMessageControllers = {};

  Stream<List<UserModel>> get usersStream async* {
    yield users.values.toList();
    yield* _usersStreamController.stream;
  }
  Stream<List<ItemModel>> get itemsStream async* {
    yield items.values.toList();
    yield* _itemsStreamController.stream;
  }
  Stream<List<BorrowRequestModel>> get requestsStream async* {
    yield requests.values.toList();
    yield* _requestsStreamController.stream;
  }
  Stream<List<TransactionModel>> get transactionsStream async* {
    yield transactions.values.toList();
    yield* _transactionsStreamController.stream;
  }
  Stream<List<ChatModel>> get chatsStream async* {
    yield chats.values.toList();
    yield* _chatsStreamController.stream;
  }
  Stream<List<NotificationModel>> get notificationsStream async* {
    yield notifications.values.toList();
    yield* _notificationsStreamController.stream;
  }
  Stream<List<ReportModel>> get reportsStream async* {
    yield reports.values.toList();
    yield* _reportsStreamController.stream;
  }

  Stream<List<MessageModel>> getChatMessagesStream(String chatId) async* {
    yield List<MessageModel>.from(messages[chatId] ?? []);
    if (!_chatMessageControllers.containsKey(chatId)) {
      _chatMessageControllers[chatId] =
          StreamController<List<MessageModel>>.broadcast();
    }
    yield* _chatMessageControllers[chatId]!.stream;
  }

  void notifyUsers() => _usersStreamController.add(users.values.toList());
  void notifyItems() => _itemsStreamController.add(items.values.toList());
  void notifyRequests() =>
      _requestsStreamController.add(requests.values.toList());
  void notifyTransactions() =>
      _transactionsStreamController.add(transactions.values.toList());
  void notifyChats() => _chatsStreamController.add(chats.values.toList());
  void notifyNotifications() =>
      _notificationsStreamController.add(notifications.values.toList());
  void notifyReports() => _reportsStreamController.add(reports.values.toList());
  void notifyChatMessages(String chatId) {
    _chatMessageControllers[chatId]?.add(List<MessageModel>.from(messages[chatId] ?? []));
  }

  void _seedData() {
    // Preserve Administrator account
    final adminUser = UserModel(
      uid: '0HZHzddi3sgIUXzD850L4C711I22',
      fullName: 'Campus Administrator',
      email: 'admin@college.edu',
      collegeId: 'ADMIN-001',
      registerNumber: 'ADMIN-001',
      department: 'Administration',
      academicYear: 'Staff',
      semester: 'Staff',
      verificationStatus: 'verified',
      isActive: true,
    );
    users[adminUser.uid] = adminUser;
  }
}
