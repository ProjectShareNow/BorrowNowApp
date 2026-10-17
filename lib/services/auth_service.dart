import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../utils/id_generator.dart';
import '../app/app_config.dart';
import '../models/user_model.dart';
import 'in_memory_store.dart';

class AuthService {
  final FirebaseAuth? firebaseAuth;
  final FirebaseFirestore? firestore;
  UserModel? _currentUser;

  final _authStateController = StreamController<UserModel?>.broadcast();

  AuthService({this.firebaseAuth, this.firestore});

  Stream<UserModel?> get authStateChanges => _authStateController.stream;
  UserModel? get currentUser => _currentUser;

  /// Initialize current user state
  Future<void> init() async {
    final auth = firebaseAuth;
    if (AppConfig.isFirebaseInitialized && auth != null) {
      final fbUser = auth.currentUser;
      if (fbUser != null) {
        _currentUser = await getUserData(fbUser.uid);
      }
      auth.authStateChanges().listen((fbUser) async {
        if (fbUser != null) {
          _currentUser = await getUserData(fbUser.uid);
        } else {
          _currentUser = null;
        }
        _authStateController.add(_currentUser);
      });
    } else {
      _currentUser = null;
    }
    _authStateController.add(_currentUser);
  }

  /// Fetch user profile from Firestore or In-Memory store
  Future<UserModel?> getUserData(String uid) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      try {
        final doc = await firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          return UserModel.fromFirestore(doc);
        }
        return null;
      } catch (e) {
        AppConfig.log('Error fetching user data: $e');
        return null;
      }
    } else {
      return InMemoryStore.instance.users[uid];
    }
  }

  /// Register new student account
  Future<UserModel> registerStudent({
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
    final auth =
        firebaseAuth ??
        (AppConfig.isFirebaseInitialized ? FirebaseAuth.instance : null);
    final firestore =
        this.firestore ??
        (AppConfig.isFirebaseInitialized ? FirebaseFirestore.instance : null);

    if (AppConfig.isFirebaseInitialized && auth != null && firestore != null) {
      try {
        AppConfig.log(
          '[Register] Step 1: Authenticating in Firebase Auth ($email)...',
        );
        // 1. Create user in Firebase Auth (with auto-recovery if Auth succeeded but Firestore was pending)
        UserCredential credential;
        try {
          credential = await auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            try {
              credential = await auth.signInWithEmailAndPassword(
                email: email.trim(),
                password: password,
              );
            } catch (_) {
              rethrow;
            }
          } else {
            rethrow;
          }
        }

        final uid = credential.user!.uid;
        AppConfig.log('[Register] Step 2: Auth successful. UID: $uid');

        // 2. Create user document in Firestore users/{uid}
        final finalIdCardUrl = idCardImageUrl.trim().isNotEmpty
            ? idCardImageUrl.trim()
            : 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600';
        final regNum = registerNumber.trim();
        final cId = (collegeId != null && collegeId.trim().isNotEmpty)
            ? collegeId.trim()
            : regNum;

        final newUser = UserModel(
          uid: uid,
          fullName: fullName.trim(),
          email: email.trim(),
          department: department.trim(),
          academicYear: academicYear.trim(),
          semester: semester.trim(),
          registerNumber: regNum,
          collegeId: cId,
          idCardImageUrl: finalIdCardUrl,
          verificationStatus: 'pending',
          isActive: true,
          itemsListedCount: 0,
          borrowedCount: 0,
          ratingAverage: 0.0,
          ratingsCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        AppConfig.log(
          '[Register] Step 3: Storing in Firestore collection [users] -> users/$uid',
        );
        await firestore
            .collection('users')
            .doc(uid)
            .set(newUser.toMap(), SetOptions(merge: true));
        AppConfig.log('[Register] ✓ Successfully written users/$uid');

        // 3. Store Device Token for Push Notifications
        try {
          String? fcmToken;
          if (!kIsWeb) {
            try {
              fcmToken = await FirebaseMessaging.instance.getToken();
            } catch (_) {}
          }

          AppConfig.log(
            '[Register] Step 4: Storing in collection [device_tokens] -> device_tokens/$uid',
          );
          await firestore.collection('device_tokens').doc(uid).set({
            'userId': uid,
            'token':
                fcmToken ??
                'token_${uid}_${DateTime.now().millisecondsSinceEpoch}',
            'deviceType': kIsWeb
                ? 'web'
                : (defaultTargetPlatform == TargetPlatform.android
                      ? 'android'
                      : 'ios'),
            'updatedAt': Timestamp.now(),
          }, SetOptions(merge: true));
          AppConfig.log('[Register] ✓ Successfully written device_tokens/$uid');
        } catch (e) {
          AppConfig.log('Device token write warning: $e');
        }

        // 4. Create In-App Welcome Notification
        try {
          final notifId = FirestoreIdGenerator.generateId('notifications');
          AppConfig.log(
            '[Register] Step 5: Storing welcome in collection [notifications] -> notifications/$notifId',
          );
          await firestore.collection('notifications').doc(notifId).set({
            'id': notifId,
            'notificationId': notifId,
            'recipientId': uid,
            'senderId': 'system',
            'senderName': 'Campus Administration',
            'title': '🎓 Welcome to BorrowNow!',
            'message':
                'Welcome to BorrowNow, ${fullName.trim()}! Your account is ready. College ID verification is in progress.',
            'type': 'system',
            'isRead': false,
            'createdAt': Timestamp.now(),
          }, SetOptions(merge: true));
          AppConfig.log(
            '[Register] ✓ Successfully written notifications/$notifId',
          );
        } catch (e) {
          AppConfig.log('Welcome notification write warning: $e');
        }

        _currentUser = newUser;
        _authStateController.add(_currentUser);
        return newUser;
      } on FirebaseAuthException catch (e) {
        AppConfig.log('Firebase registration error: [${e.code}] ${e.message}');
        if (e.code == 'email-already-in-use') {
          throw Exception(
            'An account with this college email already exists. Please sign in.',
          );
        } else if (e.code == 'weak-password') {
          throw Exception(
            'The password is too weak. Please use at least 6 characters.',
          );
        } else if (e.code == 'invalid-email') {
          throw Exception('The email address is invalid.');
        } else if (e.code == 'operation-not-allowed') {
          throw Exception(
            'Email/Password sign-in is disabled in Firebase Console.',
          );
        }
        throw Exception(e.message ?? 'Registration failed.');
      } catch (e) {
        AppConfig.log('Firebase registration error: $e');
        rethrow;
      }
    } else {
      // In-Memory store execution
      final exists = InMemoryStore.instance.users.values.any(
        (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      );
      if (exists) {
        throw Exception('An account with this email address already exists.');
      }

      final uid = FirestoreIdGenerator.generateId('users');
      final regNum = registerNumber.trim();
      final cId = (collegeId != null && collegeId.trim().isNotEmpty)
          ? collegeId.trim()
          : regNum;

      final newUser = UserModel(
        uid: uid,
        fullName: fullName.trim(),
        email: email.trim(),
        department: department.trim(),
        academicYear: academicYear.trim(),
        semester: semester.trim(),
        registerNumber: regNum,
        collegeId: cId,
        idCardImageUrl: idCardImageUrl,
        verificationStatus: 'pending',
        isActive: true,
        itemsListedCount: 0,
        borrowedCount: 0,
        ratingAverage: 0.0,
        ratingsCount: 0,
      );

      InMemoryStore.instance.users[uid] = newUser;
      InMemoryStore.instance.notifyUsers();
      _currentUser = newUser;
      _authStateController.add(_currentUser);
      return newUser;
    }
  }

  /// Login with email or register ID and password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final auth = firebaseAuth;
    final firestore = this.firestore;
    final trimmedIdentifier = email.trim();

    if (AppConfig.isFirebaseInitialized && auth != null && firestore != null) {
      try {
        String targetEmail = trimmedIdentifier;
        if (!targetEmail.contains('@')) {
          // Resolve email by registerNumber in Firestore
          final querySnap = await firestore
              .collection('users')
              .where('registerNumber', isEqualTo: targetEmail)
              .limit(1)
              .get();
          if (querySnap.docs.isEmpty) {
            throw Exception(
              'No account found with Register ID "$targetEmail".',
            );
          }
          final resolved = querySnap.docs.first.data()['email'] as String?;
          if (resolved == null || resolved.isEmpty) {
            throw Exception(
              'No registered email found for Register ID "$targetEmail".',
            );
          }
          targetEmail = resolved;
        }

        final credential = await auth.signInWithEmailAndPassword(
          email: targetEmail,
          password: password,
        );

        var user = await getUserData(credential.user!.uid);
        if (user == null) {
          throw Exception(
            'User profile not found in campus records. Please complete registration.',
          );
        }

        _currentUser = user;
        _authStateController.add(_currentUser);
        return user;
      } on FirebaseAuthException catch (e) {
        AppConfig.log('Firebase login error: [${e.code}] ${e.message}');
        if (e.code == 'invalid-credential' ||
            e.code == 'user-not-found' ||
            e.code == 'wrong-password') {
          throw Exception(
            'Incorrect email or password. Please check your credentials.',
          );
        } else if (e.code == 'user-disabled') {
          throw Exception(
            'This account has been disabled by campus administration.',
          );
        } else if (e.code == 'too-many-requests') {
          throw Exception(
            'Too many failed attempts. Please wait a moment and try again.',
          );
        } else if (e.code == 'operation-not-allowed') {
          throw Exception(
            'Email/Password sign-in is disabled in Firebase Console.',
          );
        }
        throw Exception(e.message ?? 'Authentication failed.');
      } catch (e) {
        AppConfig.log('Firebase login error: $e');
        rethrow;
      }
    } else {
      final identifier = trimmedIdentifier.toLowerCase();
      final matched = InMemoryStore.instance.users.values.where(
        (u) =>
            u.email.toLowerCase() == identifier ||
            u.registerNumber.toLowerCase() == identifier,
      );

      if (matched.isEmpty) {
        throw Exception(
          trimmedIdentifier.contains('@')
              ? 'No account found with this email address.'
              : 'No account found with Register ID "$trimmedIdentifier".',
        );
      }

      final user = matched.first;
      _currentUser = user;
      _authStateController.add(_currentUser);
      return user;
    }
  }

  /// Update user profile (Only permitted fields: department, academic year, semester, full name)
  Future<void> updateProfile({
    required String uid,
    String? fullName,
    String? department,
    String? academicYear,
    String? semester,
  }) async {
    if (_currentUser == null || _currentUser!.uid != uid) {
      throw Exception('Unauthorized profile modification.');
    }

    final updated = _currentUser!.copyWith(
      fullName: fullName,
      department: department,
      academicYear: academicYear,
      semester: semester,
      updatedAt: DateTime.now(),
    );

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final Map<String, dynamic> updates = {'updatedAt': Timestamp.now()};
      if (fullName != null) updates['fullName'] = fullName;
      if (department != null) updates['department'] = department;
      if (academicYear != null) updates['academicYear'] = academicYear;
      if (semester != null) updates['semester'] = semester;
      await firestore.collection('users').doc(uid).update(updates);
    } else {
      InMemoryStore.instance.users[uid] = updated;
      InMemoryStore.instance.notifyUsers();
    }

    _currentUser = updated;
    _authStateController.add(_currentUser);
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = firebaseAuth;
    if (AppConfig.isFirebaseInitialized && auth != null) {
      await auth.sendPasswordResetEmail(email: email.trim());
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      final exists = InMemoryStore.instance.users.values.any(
        (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      );
      if (!exists) {
        throw Exception('No user found with this email.');
      }
    }
  }

  /// Auto-verify current user - STRICT: Only allowed if caller is an administrator
  Future<void> autoVerifyCurrentUser() async {
    if (_currentUser == null) return;
    if (!_currentUser!.isAdmin) {
      throw Exception(
        'Unauthorized: Only college administrators can verify students.',
      );
    }
    final uid = _currentUser!.uid;
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore.collection('users').doc(uid).update({
        'verificationStatus': 'verified',
        'updatedAt': Timestamp.now(),
      });
    } else {
      if (InMemoryStore.instance.users.containsKey(uid)) {
        InMemoryStore.instance.users[uid] = InMemoryStore.instance.users[uid]!
            .copyWith(verificationStatus: 'verified');
        InMemoryStore.instance.notifyUsers();
      }
    }
    _currentUser = _currentUser!.copyWith(
      verificationStatus: 'verified',
      updatedAt: DateTime.now(),
    );
    _authStateController.add(_currentUser);
  }

  /// Logout
  Future<void> logout() async {
    final auth = firebaseAuth;
    if (AppConfig.isFirebaseInitialized && auth != null) {
      await auth.signOut();
    }
    _currentUser = null;
    _authStateController.add(null);
  }
}
