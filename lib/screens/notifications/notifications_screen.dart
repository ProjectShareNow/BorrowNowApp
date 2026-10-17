import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/service_registry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../app/routes.dart';
import '../../widgets/notification_card.dart';
import '../../widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final currentUserId = auth.currentUser?.uid ?? '';
    final notifications = notifProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => notifProvider.markAllAsRead(currentUserId),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No Notifications Yet',
              description:
                  'You\'re all caught up! Updates regarding borrow requests, handovers, and campus alerts will appear here.',
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return NotificationCard(
                  notification: notif,
                  onTap: () async {
                    notifProvider.markAsRead(notif.id);

                    final type = notif.type.toLowerCase();
                    if (type == 'helper_accepted' ||
                        type == 'new_chat_message' ||
                        type == 'chat_message' ||
                        type.contains('chat')) {
                      final rawRelatedId = notif.relatedId ?? '';
                      if (rawRelatedId.isNotEmpty) {
                        final chatId = await ServiceRegistry.chatService.resolveChatId(
                          relatedIdOrChatId: rawRelatedId,
                          currentUserId: currentUserId,
                        );
                        if (chatId != null && chatId.isNotEmpty && context.mounted) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chat,
                            arguments: chatId,
                          );
                        }
                      }
                    } else if (type == 'help_offered' ||
                        type == 'help_offer_received') {
                      Navigator.pushNamed(context, AppRoutes.myRequests);
                    } else if (type == 'helper_removed' ||
                        type == 'helper_rejected') {
                      Navigator.pushNamed(context, AppRoutes.home);
                    } else if (type.contains('request')) {
                      Navigator.pushNamed(context, AppRoutes.myRequests);
                    } else if (type == 'feedback_request') {
                      final txnId = notif.relatedId ?? '';
                      if (txnId.isNotEmpty) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.feedback,
                          arguments: txnId,
                        );
                      } else {
                        Navigator.pushNamed(context, AppRoutes.activeBorrowings);
                      }
                    } else if (type == 'rating_received') {
                      Navigator.pushNamed(context, AppRoutes.profile);
                    } else if (type.contains('handover') ||
                        type.contains('return')) {
                      Navigator.pushNamed(context, AppRoutes.activeBorrowings);
                    }
                  },
                );
              },
            ),
    );
  }
}
