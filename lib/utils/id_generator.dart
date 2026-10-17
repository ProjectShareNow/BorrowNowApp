import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/app_config.dart';

/// Utility to generate standard, normal 20-character base62 Firestore document IDs.
/// Matches Firebase's native auto-generated document ID format ([A-Za-z0-9]{20}).
class FirestoreIdGenerator {
  static const String _autoIdAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  static final Random _random = Random.secure();

  /// Generates a normal 20-character Firestore auto-ID.
  /// Uses native `collection().doc().id` when Firebase is active,
  /// or an identical 20-char cryptographic base62 algorithm as fallback.
  static String generateId([String collection = '_auto_']) {
    if (AppConfig.isFirebaseInitialized) {
      try {
        return FirebaseFirestore.instance.collection(collection).doc().id;
      } catch (_) {}
    }
    return List.generate(
      20,
      (_) => _autoIdAlphabet[_random.nextInt(_autoIdAlphabet.length)],
    ).join();
  }
}
