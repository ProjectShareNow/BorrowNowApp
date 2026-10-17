import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../app/app_config.dart';
import '../models/device_token_model.dart';

class DeviceTokenService {
  final FirebaseFirestore? firestore;
  final FirebaseMessaging? messaging;

  DeviceTokenService({this.firestore, this.messaging});

  /// Retrieve current platform name
  String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    return 'other';
  }

  /// Register or update FCM device token for authenticated user
  Future<void> registerDeviceToken(String userId) async {
    final msg = messaging;
    final fs = firestore;
    if (!AppConfig.isFirebaseInitialized || msg == null || fs == null || kIsWeb) {
      AppConfig.log(
        'Skipping FCM token registration: Firebase or FCM not active or running on Web',
      );
      return;
    }

    try {
      final token = await msg.getToken();
      if (token != null && token.isNotEmpty) {
        await saveToken(userId: userId, token: token);
      }

      // Listen for token refresh events
      msg.onTokenRefresh.listen((newToken) {
        saveToken(userId: userId, token: newToken);
      });
    } catch (e) {
      AppConfig.log('Error registering FCM device token: $e');
    }
  }

  /// Save token document into Firestore collection `device_tokens/{userId}`
  Future<void> saveToken({
    required String userId,
    required String token,
  }) async {
    final fs = firestore;
    if (!AppConfig.isFirebaseInitialized || fs == null) return;

    try {
      final tokenModel = DeviceTokenModel(
        id: userId,
        userId: userId,
        token: token,
        platform: _platformName,
        updatedAt: DateTime.now(),
      );

      await fs
          .collection('device_tokens')
          .doc(userId)
          .set(tokenModel.toMap(), SetOptions(merge: true));

      AppConfig.log('Device token registered for user: $userId');
    } catch (e) {
      AppConfig.log('Failed to save device token: $e');
    }
  }

  /// Remove device token on logout to prevent misdirected push notifications
  Future<void> removeToken(String userId) async {
    final fs = firestore;
    if (!AppConfig.isFirebaseInitialized || fs == null) return;

    try {
      await fs.collection('device_tokens').doc(userId).delete();
      AppConfig.log('Device token removed on logout for user: $userId');
    } catch (e) {
      AppConfig.log('Error removing device token: $e');
    }
  }
}
