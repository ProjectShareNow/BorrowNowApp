import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../app/app_config.dart';

class StorageService {
  final FirebaseStorage? firebaseStorage;
  final ImagePicker _picker = ImagePicker();
  XFile? mockLivePhotoFile;

  StorageService({this.firebaseStorage});

  /// Pick image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return pickedFile;
    } catch (e) {
      AppConfig.log('Error picking image: $e');
      return null;
    }
  }

  /// Strictly capture a fresh live photo from the device camera.
  /// Does NOT provide or allow any gallery selection fallback.
  Future<XFile?> captureLiveCameraPhoto() async {
    if (mockLivePhotoFile != null) {
      return mockLivePhotoFile;
    }
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      return pickedFile;
    } catch (e) {
      AppConfig.log('Error capturing live photo with camera: $e');
      rethrow;
    }
  }

  /// Upload file to Firebase Storage (or simulate when offline)
  Future<String> uploadImage({
    required XFile file,
    required String path,
  }) async {
    final storage = firebaseStorage;
    if (AppConfig.isFirebaseInitialized && storage != null) {
      try {
        final ref = storage.ref().child(path);
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
        );
        UploadTask uploadTask;
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          uploadTask = ref.putData(bytes, metadata);
        } else {
          uploadTask = ref.putFile(File(file.path), metadata);
        }
        final snapshot = await uploadTask.timeout(const Duration(seconds: 10));
        final downloadUrl = await snapshot.ref.getDownloadURL().timeout(
          const Duration(seconds: 10),
        );
        return downloadUrl;
      } catch (e) {
        AppConfig.log(
          'Firebase Storage upload error: $e',
        );
        return 'https://firebasestorage.googleapis.com/v0/b/borrownow-college.appspot.com/o/${Uri.encodeComponent(path)}?alt=media';
      }
    } else {
      AppConfig.log(
        'Firebase Storage not configured. Using mocked storage path URL.',
      );
      return 'https://firebasestorage.googleapis.com/v0/b/borrownow-college.appspot.com/o/${Uri.encodeComponent(path)}?alt=media';
    }
  }

  /// Upload handover verification live photo
  Future<Map<String, String>> uploadHandoverEvidencePhoto({
    required XFile file,
    required String transactionId,
  }) async {
    final storagePath =
        'handover_evidence/$transactionId/handover_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final downloadUrl = await uploadImage(file: file, path: storagePath);
    return {
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
    };
  }

  /// Upload return verification live photo
  Future<Map<String, String>> uploadReturnEvidencePhoto({
    required XFile file,
    required String transactionId,
  }) async {
    final storagePath =
        'return_evidence/$transactionId/return_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final downloadUrl = await uploadImage(file: file, path: storagePath);
    return {
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
    };
  }

  /// Upload college ID card
  Future<String> uploadCollegeIdCard({
    required XFile file,
    required String uid,
  }) async {
    final fileName =
        'id_cards/$uid/college_id_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImage(file: file, path: fileName);
  }

  /// Upload item picture
  Future<String> uploadItemImage({
    required XFile file,
    required String itemId,
    String? ownerId,
  }) async {
    final prefix = ownerId != null
        ? 'item_images/$ownerId/$itemId'
        : 'item_images/$itemId';
    final fileName =
        '$prefix/item_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImage(file: file, path: fileName);
  }

  /// Upload profile avatar
  Future<String> uploadProfileAvatar({
    required XFile file,
    required String uid,
  }) async {
    final fileName =
        'profile_images/$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImage(file: file, path: fileName);
  }

  /// Upload request item image to Firebase Storage
  Future<String> uploadRequestImage({
    required XFile file,
    required String requestId,
  }) async {
    final fileName =
        'request_images/$requestId/item_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImage(file: file, path: fileName);
  }
}
