import 'dart:async';
import 'package:flutter/material.dart';
import '../models/borrow_request_model.dart';
import '../models/user_model.dart';
import '../services/service_registry.dart';

class RequestProvider extends ChangeNotifier {
  List<BorrowRequestModel> _myRequests = [];
  List<BorrowRequestModel> _incomingRequests = [];
  List<BorrowRequestModel> _campusRequests = [];

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _myRequestsSub;
  StreamSubscription? _incomingRequestsSub;
  StreamSubscription? _campusRequestsSub;

  List<BorrowRequestModel> get myRequests => _myRequests;
  List<BorrowRequestModel> get incomingRequests => _incomingRequests;
  List<BorrowRequestModel> get campusRequests => _campusRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pendingIncomingCount =>
      _incomingRequests.where((r) => r.isPending).length;

  void listenToUserRequests(String userId) {
    _myRequestsSub?.cancel();
    _incomingRequestsSub?.cancel();

    _myRequestsSub = ServiceRegistry.borrowRequestService
        .getMyBorrowRequests(userId)
        .listen(
          (requests) {
            _myRequests = requests;
            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'Unable to load your requests.';
            notifyListeners();
          },
        );

    _incomingRequestsSub = ServiceRegistry.borrowRequestService
        .getIncomingBorrowRequests(userId)
        .listen(
          (requests) {
            _incomingRequests = requests;
            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'Unable to load incoming requests.';
            notifyListeners();
          },
        );
  }

  void listenToCampusRequests(String currentUserId) {
    _campusRequestsSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _campusRequestsSub = ServiceRegistry.borrowRequestService
        .getCampusRequestsStream(currentUserId)
        .listen(
          (requests) {
            _campusRequests = requests;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'Unable to load campus requests.';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<bool> offerHelp({
    required String requestId,
    required UserModel helperUser,
  }) async {
    _errorMessage = null;
    try {
      await ServiceRegistry.borrowRequestService.offerHelp(
        requestId: requestId,
        helperUser: helperUser,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitRequest(BorrowRequestModel request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.borrowRequestService.submitRequest(request);
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

  Future<bool> approveRequest(
    BorrowRequestModel request,
    String currentUserId,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.borrowRequestService.approveRequest(
        request: request,
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

  Future<bool> rejectRequest(
    BorrowRequestModel request,
    String reason,
    String currentUserId,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.borrowRequestService.rejectRequest(
        request: request,
        reason: reason,
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

  Future<bool> cancelRequest(String requestId, String currentUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.borrowRequestService.cancelRequest(
        requestId: requestId,
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

  Future<String?> acceptHelper({
    required String requestId,
    required String requesterId,
    required String helperId,
    required String helperName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final chatId = await ServiceRegistry.borrowRequestService.acceptHelper(
        requestId: requestId,
        requesterId: requesterId,
        helperId: helperId,
        helperName: helperName,
      );
      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> removeAcceptedHelper({
    required String requestId,
    required String requesterId,
    required String helperId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.borrowRequestService.removeAcceptedHelper(
        requestId: requestId,
        requesterId: requesterId,
        helperId: helperId,
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

  Future<bool> rejectHelperOffer({
    required String requestId,
    required String requesterId,
    required String helperId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.borrowRequestService.rejectHelperOffer(
        requestId: requestId,
        requesterId: requesterId,
        helperId: helperId,
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
    _myRequestsSub?.cancel();
    _incomingRequestsSub?.cancel();
    _campusRequestsSub?.cancel();
    super.dispose();
  }
}
