import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/service_registry.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;
  bool get isVerified => _currentUser?.isVerified ?? false;
  bool get isPending => _currentUser?.isPending ?? false;
  bool get isRejected => _currentUser?.isRejected ?? false;
  bool get isActive => _currentUser?.isActive ?? true;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  AuthProvider() {
    _init();
  }

  void _init() {
    _currentUser = ServiceRegistry.authService.currentUser;
    ServiceRegistry.authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await ServiceRegistry.authService.login(
        email: email,
        password: password,
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

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String department,
    required String academicYear,
    required String semester,
    required String registerNumber,
    String? collegeId,
    required String idCardImageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await ServiceRegistry.authService.registerStudent(
        fullName: fullName,
        email: email,
        password: password,
        department: department,
        academicYear: academicYear,
        semester: semester,
        registerNumber: registerNumber,
        collegeId: collegeId,
        idCardImageUrl: idCardImageUrl,
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

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.authService.sendPasswordResetEmail(email);
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

  Future<bool> updateProfile({
    String? fullName,
    String? department,
    String? academicYear,
    String? semester,
  }) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.authService.updateProfile(
        uid: _currentUser!.uid,
        fullName: fullName,
        department: department,
        academicYear: academicYear,
        semester: semester,
      );
      _currentUser = ServiceRegistry.authService.currentUser;
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

  Future<UserModel?> refreshCurrentUser() async {
    if (_currentUser == null) return null;
    final refreshed = await ServiceRegistry.authService.getUserData(
      _currentUser!.uid,
    );
    if (refreshed != null) {
      _currentUser = refreshed;
      notifyListeners();
    }
    return _currentUser;
  }

  Future<void> autoVerify() async {
    if (_currentUser == null || !_currentUser!.isAdmin) {
      _errorMessage =
          'Unauthorized: Only college administrators can verify accounts.';
      notifyListeners();
      return;
    }
    await ServiceRegistry.authService.autoVerifyCurrentUser();
    _currentUser = ServiceRegistry.authService.currentUser;
    notifyListeners();
  }

  Future<void> logout() async {
    await ServiceRegistry.authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> signOut() => logout();
}
