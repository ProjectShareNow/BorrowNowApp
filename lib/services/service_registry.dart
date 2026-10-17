import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../app/app_config.dart';
import 'auth_service.dart';
import 'storage_service.dart';
import 'item_service.dart';
import 'borrow_request_service.dart';
import 'transaction_service.dart';
import 'chat_service.dart';
import 'notification_service.dart';
import 'rating_service.dart';
import 'report_service.dart';
import 'admin_service.dart';

import 'user_service.dart';
import 'device_token_service.dart';

class ServiceRegistry {
  static late final AuthService authService;
  static late final UserService userService;
  static late final StorageService storageService;
  static late final ItemService itemService;
  static late final BorrowRequestService borrowRequestService;
  static late final TransactionService transactionService;
  static late final ChatService chatService;
  static late final NotificationService notificationService;
  static late final RatingService ratingService;
  static late final ReportService reportService;
  static late final AdminService adminService;
  static late final DeviceTokenService deviceTokenService;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseAuth? auth;
    FirebaseFirestore? firestore;
    FirebaseStorage? storage;
    FirebaseMessaging? messaging;

    if (AppConfig.isFirebaseInitialized) {
      try {
        auth = FirebaseAuth.instance;
        firestore = FirebaseFirestore.instance;
        storage = FirebaseStorage.instance;
        messaging = FirebaseMessaging.instance;
      } catch (e) {
        AppConfig.log('Firebase services attachment error: $e');
      }
    }

    authService = AuthService(firebaseAuth: auth, firestore: firestore);
    userService = UserService(firestore: firestore);
    storageService = StorageService(firebaseStorage: storage);
    itemService = ItemService(firestore: firestore);
    borrowRequestService = BorrowRequestService(firestore: firestore);
    transactionService = TransactionService(firestore: firestore);
    chatService = ChatService(firestore: firestore);
    notificationService = NotificationService(
      firestore: firestore,
      messaging: messaging,
    );
    ratingService = RatingService(firestore: firestore);
    reportService = ReportService(firestore: firestore);
    adminService = AdminService(firestore: firestore);
    deviceTokenService = DeviceTokenService(
      firestore: firestore,
      messaging: messaging,
    );

    await authService.init();
    await notificationService.initFCM();
  }
}
