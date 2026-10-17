import 'dart:async';
import 'package:flutter/material.dart';
import '../app/app_config.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../models/item_model.dart';
import '../models/transaction_model.dart';
import '../models/borrow_request_model.dart';
import '../services/admin_service.dart';
import '../services/service_registry.dart';

class AdminProvider extends ChangeNotifier {
  AdminDashboardStats? _stats;
  List<UserModel> _pendingStudents = [];
  List<UserModel> _allUsers = [];
  List<ReportModel> _allReports = [];
  List<ItemModel> _allItems = [];
  List<TransactionModel> _allTransactions = [];
  List<BorrowRequestModel> _allBorrowRequests = [];

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _pendingSub;
  StreamSubscription? _usersSub;
  StreamSubscription? _reportsSub;
  StreamSubscription? _itemsSub;
  StreamSubscription? _transactionsSub;
  StreamSubscription? _requestsSub;

  AdminDashboardStats? get stats => _stats;
  List<UserModel> get pendingStudents => _pendingStudents;
  List<UserModel> get allUsers => _allUsers;
  List<ReportModel> get allReports => _allReports;
  List<ItemModel> get allItems => _allItems;
  List<TransactionModel> get allTransactions => _allTransactions;
  List<BorrowRequestModel> get allBorrowRequests => _allBorrowRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void initAdminStreams() {
    _pendingSub?.cancel();
    _usersSub?.cancel();
    _reportsSub?.cancel();
    _itemsSub?.cancel();
    _transactionsSub?.cancel();
    _requestsSub?.cancel();

    _pendingSub = ServiceRegistry.adminService
        .getPendingVerificationsStream()
        .listen(
          (list) {
            _pendingStudents = list;
            refreshStats();
            notifyListeners();
          },
          onError: (e) {
            AppConfig.log('Admin pending verifications stream error: $e');
          },
        );

    _usersSub = ServiceRegistry.adminService.getAllUsersStream().listen(
      (list) {
        _allUsers = list;
        refreshStats();
        notifyListeners();
      },
      onError: (e) {
        AppConfig.log('Admin all users stream error: $e');
      },
    );

    _reportsSub = ServiceRegistry.reportService.getAllReportsStream().listen(
      (list) {
        _allReports = list;
        refreshStats();
        notifyListeners();
      },
      onError: (e) {
        AppConfig.log('Admin reports stream error: $e');
      },
    );

    _itemsSub = ServiceRegistry.itemService.getAllItemsStream().listen(
      (list) {
        _allItems = list;
        refreshStats();
        notifyListeners();
      },
      onError: (e) {
        AppConfig.log('Admin items stream error: $e');
      },
    );

    _transactionsSub = ServiceRegistry.transactionService
        .getAllTransactionsStream()
        .listen(
          (list) {
            _allTransactions = list;
            refreshStats();
            notifyListeners();
          },
          onError: (e) {
            AppConfig.log('Admin transactions stream error: $e');
          },
        );

    _requestsSub = ServiceRegistry.borrowRequestService
        .getAllBorrowRequestsStream()
        .listen(
          (list) {
            _allBorrowRequests = list;
            refreshStats();
            notifyListeners();
          },
          onError: (e) {
            AppConfig.log('Admin borrow requests stream error: $e');
          },
        );

    refreshStats();
  }

  Future<void> refreshStats() async {
    try {
      _stats = await ServiceRegistry.adminService.getDashboardStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<bool> approveStudent(String uid, String adminUid) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ServiceRegistry.adminService.approveStudentVerification(
        uid: uid,
        adminUid: adminUid,
      );
      await refreshStats();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectStudent(String uid, String reason, String adminUid) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ServiceRegistry.adminService.rejectStudentVerification(
        uid: uid,
        reason: reason,
        adminUid: adminUid,
      );
      await refreshStats();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateStudent({
    required String uid,
    required String reason,
    required String adminUid,
    String adminName = 'Campus Administrator',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ServiceRegistry.adminService.deactivateAccount(
        uid: uid,
        reason: reason,
        adminUid: adminUid,
        adminName: adminName,
      );
      await refreshStats();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reactivateStudent({
    required String uid,
    required String adminUid,
    String adminName = 'Campus Administrator',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ServiceRegistry.adminService.reactivateAccount(
        uid: uid,
        adminUid: adminUid,
        adminName: adminName,
      );
      await refreshStats();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleUserStatus(
    String uid,
    bool isActive, {
    String? reason,
    String adminUid = 'admin',
    String adminName = 'Campus Administrator',
  }) async {
    if (isActive) {
      return reactivateStudent(
        uid: uid,
        adminUid: adminUid,
        adminName: adminName,
      );
    } else {
      return deactivateStudent(
        uid: uid,
        reason: reason ?? 'Account suspended by administrator.',
        adminUid: adminUid,
        adminName: adminName,
      );
    }
  }

  Future<bool> adminDeactivateItem({
    required String itemId,
    required String reason,
    required String adminUid,
    String adminName = 'Campus Administrator',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ServiceRegistry.itemService.adminDeactivateItem(
        itemId: itemId,
        reason: reason,
        adminUid: adminUid,
        adminName: adminName,
      );
      await refreshStats();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resolveReport(
    String reportId,
    String status,
    String? adminNotes,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ServiceRegistry.reportService.updateReportStatus(
        reportId: reportId,
        status: status,
        adminNotes: adminNotes,
      );
      await refreshStats();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _pendingSub?.cancel();
    _usersSub?.cancel();
    _reportsSub?.cancel();
    _itemsSub?.cancel();
    _transactionsSub?.cancel();
    _requestsSub?.cancel();
    super.dispose();
  }
}
