import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/id_generator.dart';
import '../utils/constants.dart';
import '../app/app_config.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../models/transaction_model.dart';
import 'in_memory_store.dart';

class AdminDashboardStats {
  final int totalUsers;
  final int pendingVerifications;
  final int approvedUsers;
  final int rejectedUsers;
  final int deactivatedAccounts;
  final int totalItems;
  final int pendingBorrowRequests;
  final int activeTransactions;
  final int overdueReturns;
  final int unresolvedComplaints;

  AdminDashboardStats({
    required this.totalUsers,
    required this.pendingVerifications,
    required this.approvedUsers,
    required this.rejectedUsers,
    required this.deactivatedAccounts,
    required this.totalItems,
    required this.pendingBorrowRequests,
    required this.activeTransactions,
    required this.overdueReturns,
    required this.unresolvedComplaints,
  });

  // Backward compatibility getters
  int get activeBorrowings => activeTransactions;
  int get openReports => unresolvedComplaints;
  int get openComplaints => unresolvedComplaints;
}

class AdminService {
  final FirebaseFirestore? firestore;

  AdminService({this.firestore});

  /// Fetch overview dashboard metrics with live Firestore counts
  Future<AdminDashboardStats> getDashboardStats() async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final usersSnap = await firestore.collection('users').get();
      final itemsSnap = await firestore.collection('items').get();
      final borrowRequestsSnap = await firestore
          .collection('borrow_requests')
          .get();
      final transactionsSnap = await firestore.collection('transactions').get();
      final reportsSnap = await firestore.collection('reports').get();

      int pendingVerifications = 0;
      int approvedUsers = 0;
      int rejectedUsers = 0;
      int deactivatedAccounts = 0;

      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final status = (data['verificationStatus'] ?? 'pending')
            .toString()
            .toLowerCase();
        final isActive = data['isActive'] ?? true;
        if (status == 'pending') pendingVerifications++;
        if (status == 'verified' || status == 'approved') approvedUsers++;
        if (status == 'rejected') rejectedUsers++;
        if (isActive == false) deactivatedAccounts++;
      }

      int pendingRequests = 0;
      for (final doc in borrowRequestsSnap.docs) {
        final status = (doc.data()['status'] ?? '').toString().toLowerCase();
        if (status == 'pending') pendingRequests++;
      }

      int activeTxns = 0;
      int overdueReturns = 0;
      for (final doc in transactionsSnap.docs) {
        final txn = TransactionModel.fromFirestore(doc);
        if (txn.isActive || txn.isScheduled || txn.isReturnRequested) {
          activeTxns++;
          if (txn.isOverdue) {
            overdueReturns++;
          }
        }
      }

      int unresolvedComplaints = 0;
      for (final doc in reportsSnap.docs) {
        final status = (doc.data()['status'] ?? '').toString().toLowerCase();
        if (status == 'pending' || status == 'under_review') {
          unresolvedComplaints++;
        }
      }

      return AdminDashboardStats(
        totalUsers: usersSnap.docs.length,
        pendingVerifications: pendingVerifications,
        approvedUsers: approvedUsers,
        rejectedUsers: rejectedUsers,
        deactivatedAccounts: deactivatedAccounts,
        totalItems: itemsSnap.docs.length,
        pendingBorrowRequests: pendingRequests,
        activeTransactions: activeTxns,
        overdueReturns: overdueReturns,
        unresolvedComplaints: unresolvedComplaints,
      );
    } else {
      final store = InMemoryStore.instance;
      final usersList = store.users.values.toList();
      final pendingVerifications = usersList
          .where((u) => u.verificationStatus == 'pending')
          .length;
      final approvedUsers = usersList.where((u) => u.isVerified).length;
      final rejectedUsers = usersList
          .where((u) => u.verificationStatus == 'rejected')
          .length;
      final deactivatedAccounts = usersList.where((u) => !u.isActive).length;
      final pendingBorrowRequests = store.requests.values
          .where((r) => r.isPending)
          .length;
      final activeTransactions = store.transactions.values
          .where((t) => t.isActive || t.isScheduled || t.isReturnRequested)
          .length;
      final overdueReturns = store.transactions.values
          .where(
            (t) =>
                (t.isActive || t.isScheduled || t.isReturnRequested) &&
                t.isOverdue,
          )
          .length;
      final unresolvedComplaints = store.reports.values
          .where((r) => r.isPending || r.isUnderReview)
          .length;

      return AdminDashboardStats(
        totalUsers: usersList.length,
        pendingVerifications: pendingVerifications,
        approvedUsers: approvedUsers,
        rejectedUsers: rejectedUsers,
        deactivatedAccounts: deactivatedAccounts,
        totalItems: store.items.length,
        pendingBorrowRequests: pendingBorrowRequests,
        activeTransactions: activeTransactions,
        overdueReturns: overdueReturns,
        unresolvedComplaints: unresolvedComplaints,
      );
    }
  }

  /// Stream of students pending ID card verification
  Stream<List<UserModel>> getPendingVerificationsStream() {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('users')
          .where('verificationStatus', isEqualTo: 'pending')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.usersStream.map(
        (list) => list.where((u) => u.verificationStatus == 'pending').toList(),
      );
    }
  }

  /// Stream of all registered users
  Stream<List<UserModel>> getAllUsersStream() {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('users')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.usersStream;
    }
  }

  /// Approve student ID card verification
  /// STRICT: Only authorized college administrators can approve student verification
  Future<void> approveStudentVerification({
    required String uid,
    required String adminUid,
  }) async {
    final firestore = this.firestore;
    String adminName = 'Campus Administrator';

    if (AppConfig.isFirebaseInitialized && firestore != null) {
      // 1. Authorization check: Caller must be an authenticated administrator
      final adminDoc = await firestore.collection('users').doc(adminUid).get();
      final adminEmail = (adminDoc.data()?['email'] ?? '').toString().trim().toLowerCase();
      final isAuthorizedAdmin = AppConstants.adminEmails.contains(adminEmail) || adminEmail.startsWith('admin@');
      if (!adminDoc.exists || !isAuthorizedAdmin) {
        throw Exception(
          'Unauthorized: Only college administrators can approve student verifications.',
        );
      }
      adminName = adminDoc.data()?['fullName'] ?? 'Campus Administrator';

      final notif = NotificationModel(
        id: FirestoreIdGenerator.generateId('notifications'),
        recipientId: uid,
        senderId: adminUid,
        senderName: adminName,
        type: 'verification_approved',
        title: 'College ID Verified! 🎓',
        message:
            'Your student ID card has been verified by the college administration. Welcome to BorrowNow! You can now borrow and lend items.',
      );

      final batch = firestore.batch();
      batch.update(firestore.collection('users').doc(uid), {
        'verificationStatus': 'verified',
        'rejectionReason': null,
        'updatedAt': Timestamp.now(),
      });
      batch.set(
        firestore.collection('notifications').doc(notif.id),
        notif.toMap(),
      );
      await batch.commit();
      AppConfig.log(
        '[AdminService] ✓ Approved student $uid by admin $adminUid.',
      );
    } else {
      final admin = InMemoryStore.instance.users[adminUid];
      if (admin == null || !admin.isAdmin) {
        throw Exception(
          'Unauthorized: Only college administrators can approve student verifications.',
        );
      }
      adminName = admin.fullName;

      final notif = NotificationModel(
        id: FirestoreIdGenerator.generateId('notifications'),
        recipientId: uid,
        senderId: adminUid,
        senderName: adminName,
        type: 'verification_approved',
        title: 'College ID Verified! 🎓',
        message:
            'Your student ID card has been verified by the college administration. Welcome to BorrowNow! You can now borrow and lend items.',
      );

      final user = InMemoryStore.instance.users[uid];
      if (user != null) {
        InMemoryStore.instance.users[uid] = user.copyWith(
          verificationStatus: 'verified',
          rejectionReason: null,
          updatedAt: DateTime.now(),
        );
      }
      InMemoryStore.instance.notifications[notif.id] = notif;
      InMemoryStore.instance.notifyUsers();
      InMemoryStore.instance.notifyNotifications();
    }
  }

  /// Reject student ID card verification
  /// STRICT: Only authorized college administrators can reject student verification
  Future<void> rejectStudentVerification({
    required String uid,
    required String reason,
    required String adminUid,
  }) async {
    final firestore = this.firestore;
    String adminName = 'Campus Administrator';

    if (AppConfig.isFirebaseInitialized && firestore != null) {
      // 1. Authorization check: Caller must be an authenticated administrator
      final adminDoc = await firestore.collection('users').doc(adminUid).get();
      final adminEmail = (adminDoc.data()?['email'] ?? '').toString().trim().toLowerCase();
      final isAuthorizedAdmin = AppConstants.adminEmails.contains(adminEmail) || adminEmail.startsWith('admin@');
      if (!adminDoc.exists || !isAuthorizedAdmin) {
        throw Exception(
          'Unauthorized: Only college administrators can reject student verifications.',
        );
      }
      adminName = adminDoc.data()?['fullName'] ?? 'Campus Administrator';

      final notif = NotificationModel(
        id: FirestoreIdGenerator.generateId('notifications'),
        recipientId: uid,
        senderId: adminUid,
        senderName: adminName,
        type: 'verification_rejected',
        title: 'Verification Declined',
        message:
            'Your ID card verification was declined: $reason. Please update your document or contact the administration.',
      );

      final batch = firestore.batch();
      batch.update(firestore.collection('users').doc(uid), {
        'verificationStatus': 'rejected',
        'rejectionReason': reason.trim(),
        'updatedAt': Timestamp.now(),
      });
      batch.set(
        firestore.collection('notifications').doc(notif.id),
        notif.toMap(),
      );
      await batch.commit();
      AppConfig.log(
        '[AdminService] ✗ Declined verification for student $uid by admin $adminUid. Reason: $reason.',
      );
    } else {
      final admin = InMemoryStore.instance.users[adminUid];
      if (admin == null || !admin.isAdmin) {
        throw Exception(
          'Unauthorized: Only college administrators can reject student verifications.',
        );
      }
      adminName = admin.fullName;

      final notif = NotificationModel(
        id: FirestoreIdGenerator.generateId('notifications'),
        recipientId: uid,
        senderId: adminUid,
        senderName: adminName,
        type: 'verification_rejected',
        title: 'Verification Declined',
        message:
            'Your ID card verification was declined: $reason. Please update your document or contact the administration.',
      );

      final user = InMemoryStore.instance.users[uid];
      if (user != null) {
        InMemoryStore.instance.users[uid] = user.copyWith(
          verificationStatus: 'rejected',
          rejectionReason: reason.trim(),
          updatedAt: DateTime.now(),
        );
      }
      InMemoryStore.instance.notifications[notif.id] = notif;
      InMemoryStore.instance.notifyUsers();
      InMemoryStore.instance.notifyNotifications();
    }
  }

  /// Stream of approved/verified students
  Stream<List<UserModel>> getApprovedVerificationsStream() {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('users')
          .where('verificationStatus', isEqualTo: 'verified')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.usersStream.map(
        (list) => list.where((u) => u.isVerified).toList(),
      );
    }
  }

  /// Stream of rejected students
  Stream<List<UserModel>> getRejectedVerificationsStream() {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('users')
          .where('verificationStatus', isEqualTo: 'rejected')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.usersStream.map(
        (list) =>
            list.where((u) => u.verificationStatus == 'rejected').toList(),
      );
    }
  }

  /// Deactivate account with mandatory reason and notification
  Future<void> deactivateAccount({
    required String uid,
    required String reason,
    required String adminUid,
    String adminName = 'Campus Administrator',
  }) async {
    if (reason.trim().isEmpty) {
      throw Exception('A valid reason is required to deactivate an account.');
    }

    final firestore = this.firestore;
    final notifId = FirestoreIdGenerator.generateId('notifications');

    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final notif = NotificationModel(
        id: notifId,
        recipientId: uid,
        senderId: adminUid,
        senderName: adminName,
        type: 'admin_notice',
        title: 'Account Deactivated by Administration',
        message:
            'Your BorrowNow student account has been temporarily deactivated: $reason. Please contact the campus admin office for questions.',
      );

      final batch = firestore.batch();
      batch.update(firestore.collection('users').doc(uid), {
        'isActive': false,
        'rejectionReason': reason.trim(),
        'updatedAt': Timestamp.now(),
      });
      batch.set(
        firestore.collection('notifications').doc(notifId),
        notif.toMap(),
      );
      await batch.commit();
    } else {
      final user = InMemoryStore.instance.users[uid];
      if (user != null) {
        InMemoryStore.instance.users[uid] = user.copyWith(
          isActive: false,
          rejectionReason: reason.trim(),
          updatedAt: DateTime.now(),
        );
        final notif = NotificationModel(
          id: notifId,
          recipientId: uid,
          senderId: adminUid,
          senderName: adminName,
          type: 'admin_notice',
          title: 'Account Deactivated by Administration',
          message:
              'Your BorrowNow student account has been temporarily deactivated: $reason. Please contact the campus admin office for questions.',
        );
        InMemoryStore.instance.notifications[notifId] = notif;
        InMemoryStore.instance.notifyUsers();
        InMemoryStore.instance.notifyNotifications();
      }
    }
  }

  /// Reactivate an account with notification
  Future<void> reactivateAccount({
    required String uid,
    required String adminUid,
    String adminName = 'Campus Administrator',
  }) async {
    final firestore = this.firestore;
    final notifId = FirestoreIdGenerator.generateId('notifications');

    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final notif = NotificationModel(
        id: notifId,
        recipientId: uid,
        senderId: adminUid,
        senderName: adminName,
        type: 'admin_notice',
        title: 'Account Reactivated! 🎉',
        message:
            'Your BorrowNow student account has been reactivated by the campus administration. You can now access borrowing and lending services.',
      );

      final batch = firestore.batch();
      batch.update(firestore.collection('users').doc(uid), {
        'isActive': true,
        'rejectionReason': null,
        'updatedAt': Timestamp.now(),
      });
      batch.set(
        firestore.collection('notifications').doc(notifId),
        notif.toMap(),
      );
      await batch.commit();
    } else {
      final user = InMemoryStore.instance.users[uid];
      if (user != null) {
        InMemoryStore.instance.users[uid] = user.copyWith(
          isActive: true,
          updatedAt: DateTime.now(),
        );
        final notif = NotificationModel(
          id: notifId,
          recipientId: uid,
          senderId: adminUid,
          senderName: adminName,
          type: 'admin_notice',
          title: 'Account Reactivated! 🎉',
          message:
              'Your BorrowNow student account has been reactivated by the campus administration.',
        );
        InMemoryStore.instance.notifications[notifId] = notif;
        InMemoryStore.instance.notifyUsers();
        InMemoryStore.instance.notifyNotifications();
      }
    }
  }

  /// Toggle user active status (deactivate / reactivate)
  Future<void> toggleUserActiveStatus({
    required String uid,
    required bool isActive,
    String? reason,
    String adminUid = 'admin',
    String adminName = 'Campus Administrator',
  }) async {
    if (isActive) {
      await reactivateAccount(
        uid: uid,
        adminUid: adminUid,
        adminName: adminName,
      );
    } else {
      await deactivateAccount(
        uid: uid,
        reason: reason ?? 'Account suspended by administrator.',
        adminUid: adminUid,
        adminName: adminName,
      );
    }
  }
}
