import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/app_config.dart';
import '../models/user_model.dart';
import 'in_memory_store.dart';

class UserService {
  final FirebaseFirestore? firestore;

  UserService({this.firestore});

  /// Stream of a specific user profile
  Stream<UserModel?> getUserStream(String uid) {
    final fs = firestore;
    if (AppConfig.isFirebaseInitialized && fs != null) {
      return fs.collection('users').doc(uid).snapshots().map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      });
    } else {
      return InMemoryStore.instance.usersStream.map(
        (list) => list.cast<UserModel?>().firstWhere(
          (u) => u?.uid == uid,
          orElse: () => null,
        ),
      );
    }
  }

  /// Get single user profile by UID
  Future<UserModel?> getUserById(String uid) async {
    final fs = firestore;
    if (AppConfig.isFirebaseInitialized && fs != null) {
      try {
        final doc = await fs.collection('users').doc(uid).get();
        if (doc.exists) {
          return UserModel.fromFirestore(doc);
        }
        return null;
      } catch (e) {
        AppConfig.log('Error fetching user by ID: $e');
        return null;
      }
    } else {
      return InMemoryStore.instance.users[uid];
    }
  }

  /// Update permitted profile attributes for a student
  Future<void> updateProfile({
    required String uid,
    String? fullName,
    String? department,
    String? academicYear,
    String? semester,
  }) async {
    final fs = firestore;
    if (AppConfig.isFirebaseInitialized && fs != null) {
      final Map<String, dynamic> updates = {'updatedAt': Timestamp.now()};
      if (fullName != null) {
        updates['fullName'] = fullName;
      }
      if (department != null) updates['department'] = department;
      if (academicYear != null) {
        updates['academicYear'] = academicYear;
      }
      if (semester != null) {
        updates['semester'] = semester;
      }

      await fs.collection('users').doc(uid).update(updates);
    } else {
      final user = InMemoryStore.instance.users[uid];
      if (user != null) {
        final updated = user.copyWith(
          fullName: fullName,
          department: department,
          academicYear: academicYear,
          semester: semester,
          updatedAt: DateTime.now(),
        );
        InMemoryStore.instance.users[uid] = updated;
        InMemoryStore.instance.notifyUsers();
      }
    }
  }

  /// Stream of all registered users (for admin directory)
  Stream<List<UserModel>> getAllUsersStream() {
    final fs = firestore;
    if (AppConfig.isFirebaseInitialized && fs != null) {
      return fs
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.usersStream.map(
        (list) =>
            List<UserModel>.from(list)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }
}
