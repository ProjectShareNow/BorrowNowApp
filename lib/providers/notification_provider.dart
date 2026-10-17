import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/service_registry.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  StreamSubscription? _notifSub;
  StreamSubscription? _unreadSub;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void listenToUserNotifications(String userId) {
    _notifSub?.cancel();
    _unreadSub?.cancel();

    _notifSub = ServiceRegistry.notificationService
        .getUserNotificationsStream(userId)
        .listen(
          (list) {
            _notifications = list;
            notifyListeners();
          },
          onError: (e) {
            // Silently handle stream error
          },
        );

    _unreadSub = ServiceRegistry.notificationService
        .getUnreadCountStream(userId)
        .listen(
          (count) {
            _unreadCount = count;
            notifyListeners();
          },
          onError: (e) {
            // Silently handle stream error
          },
        );
  }

  Future<void> markAsRead(String notificationId) async {
    await ServiceRegistry.notificationService.markAsRead(notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await ServiceRegistry.notificationService.markAllAsRead(userId);
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _unreadSub?.cancel();
    super.dispose();
  }
}
