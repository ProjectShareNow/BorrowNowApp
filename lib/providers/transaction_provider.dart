import 'dart:async';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/service_registry.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _activeTransactions = [];
  List<TransactionModel> _historyTransactions = [];

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _activeSub;
  StreamSubscription? _historySub;

  List<TransactionModel> get activeTransactions => _activeTransactions;
  List<TransactionModel> get historyTransactions => _historyTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void listenToUserTransactions(String userId) {
    _activeSub?.cancel();
    _historySub?.cancel();

    _activeSub = ServiceRegistry.transactionService
        .getActiveTransactions(userId)
        .listen(
          (list) {
            _activeTransactions = list;
            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'Unable to load active transactions.';
            notifyListeners();
          },
        );

    _historySub = ServiceRegistry.transactionService
        .getTransactionHistory(userId)
        .listen(
          (list) {
            _historyTransactions = list;
            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'Unable to load transaction history.';
            notifyListeners();
          },
        );
  }

  Future<bool> confirmHandoverReadiness(
    String transactionId,
    String currentUserId,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.transactionService.confirmHandoverReadiness(
        transactionId: transactionId,
        currentUserId: currentUserId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestReturn(String transactionId, String currentUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.transactionService.requestReturn(
        transactionId: transactionId,
        currentUserId: currentUserId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmReturnReceipt(
    String transactionId,
    String currentUserId, {
    bool isAdmin = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.transactionService.confirmReturnReceipt(
        transactionId: transactionId,
        currentUserId: currentUserId,
        isAdmin: isAdmin,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _activeSub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }
}
