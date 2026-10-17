import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../utils/helpers.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'request_received':
        return Icons.inbox_rounded;
      case 'request_approved':
      case 'helper_accepted':
        return Icons.check_circle_rounded;
      case 'help_offered':
      case 'help_offer_received':
        return Icons.volunteer_activism_rounded;
      case 'helper_removed':
      case 'helper_rejected':
      case 'request_rejected':
        return Icons.cancel_rounded;
      case 'new_chat_message':
      case 'chat_message':
        return Icons.chat_bubble_rounded;
      case 'handover_ready':
      case 'handover_confirmed':
        return Icons.handshake_rounded;
      case 'return_requested':
      case 'return_confirmed':
        return Icons.assignment_turned_in_rounded;
      case 'verification_approved':
        return Icons.verified_user_rounded;
      case 'verification_rejected':
        return Icons.gpp_bad_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'request_approved':
      case 'helper_accepted':
      case 'verification_approved':
      case 'return_confirmed':
        return const Color(0xFF10B981);
      case 'request_rejected':
      case 'helper_rejected':
      case 'helper_removed':
      case 'verification_rejected':
        return const Color(0xFFEF4444);
      case 'handover_ready':
      case 'return_requested':
        return const Color(0xFFF59E0B);
      case 'new_chat_message':
      case 'chat_message':
      case 'help_offered':
      case 'help_offer_received':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF1E40AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(notification.type);

    return Material(
      color: notification.isRead
          ? Colors.transparent
          : typeColor.withValues(alpha: 0.04),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: typeColor.withValues(alpha: 0.12),
              child: Icon(
                _getTypeIcon(notification.type),
                color: typeColor,
                size: 20,
              ),
            ),
            if (!notification.isRead)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppHelpers.formatRelativeTime(notification.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
