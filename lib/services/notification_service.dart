import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/id_generator.dart';
import '../app/app_config.dart';
import '../models/notification_model.dart';
import 'in_memory_store.dart';

class NotificationService {
  final FirebaseFirestore? firestore;
  final FirebaseMessaging? messaging;

  NotificationService({this.firestore, this.messaging});

  /// Initialize Firebase Cloud Messaging hooks
  Future<void> initFCM() async {
    final msg = messaging;
    if (AppConfig.isFirebaseInitialized && msg != null) {
      try {
        final settings = await msg.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        AppConfig.log('FCM permission status: ${settings.authorizationStatus}');
      } catch (e) {
        AppConfig.log('FCM initialization warning (FCM setup pending): $e');
      }
    } else {
      AppConfig.log('FCM not connected. In-app notifications are active.');
    }
  }

  /// Stream of notifications for a user
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => NotificationModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.notificationsStream.map(
        (list) =>
            list.where((n) => n.recipientId == userId).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Unread notifications count
  Stream<int> getUnreadCountStream(String userId) {
    return getUserNotificationsStream(
      userId,
    ).map((list) => list.where((n) => !n.isRead).length);
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } else {
      final notif = InMemoryStore.instance.notifications[notificationId];
      if (notif != null) {
        InMemoryStore.instance.notifications[notificationId] = notif.copyWith(
          isRead: true,
        );
        InMemoryStore.instance.notifyNotifications();
      }
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final snapshot = await firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } else {
      for (final entry in InMemoryStore.instance.notifications.entries) {
        if (entry.value.recipientId == userId) {
          InMemoryStore.instance.notifications[entry.key] = entry.value
              .copyWith(isRead: true);
        }
      }
      InMemoryStore.instance.notifyNotifications();
    }
  }

  /// Send in-app notification
  Future<void> sendNotification({
    required String recipientId,
    required String senderId,
    String senderName = 'BorrowNow',
    required String type,
    required String title,
    required String message,
    String? relatedId,
  }) async {
    final notifId = FirestoreIdGenerator.generateId('notifications');
    final notif = NotificationModel(
      id: notifId,
      recipientId: recipientId,
      senderId: senderId,
      senderName: senderName,
      type: type,
      title: title,
      message: message,
      relatedId: relatedId,
    );

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore
          .collection('notifications')
          .doc(notifId)
          .set(notif.toMap());
    } else {
      InMemoryStore.instance.notifications[notifId] = notif;
      InMemoryStore.instance.notifyNotifications();
    }
  }
}
