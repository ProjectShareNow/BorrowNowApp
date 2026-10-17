import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  /// Format DateTime to readable date: e.g. "12 Oct 2026"
  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format DateTime to readable date & time: e.g. "12 Oct 2026, 03:30 PM"
  static String formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  /// Format Time: e.g. "03:30 PM"
  static String formatTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('hh:mm a').format(date);
  }

  /// Relative time e.g., "5m ago", "2h ago", "Yesterday"
  static String formatRelativeTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM').format(date);
    }
  }

  /// Mask college register number for privacy.
  /// Required format: The last 3 characters must always be hidden with '***'.
  /// All preceding characters remain visible.
  /// e.g. "CE20CS1234" -> "CE20CS1***"
  /// If 3 or fewer characters, displays only asterisks for those characters.
  static String maskRegisterNumber(String? regNo) {
    if (regNo == null || regNo.trim().isEmpty) return 'N/A';
    final trimmed = regNo.trim();
    if (trimmed.length <= 3) {
      return '*' * trimmed.length;
    }
    return '${trimmed.substring(0, trimmed.length - 3)}***';
  }

  /// Format user rating display string.
  /// If no reviews, shows "0.0 / 5.0 (0 reviews)".
  /// When reviews exist, shows e.g. "4.5 / 5.0 (2 reviews)".
  static String formatRatingDisplay(double? rating, int count) {
    final validCount = count < 0 ? 0 : count;
    final validRating = (validCount == 0 || rating == null)
        ? 0.0
        : rating.clamp(0.0, 5.0);
    final countLabel = validCount == 1 ? '1 review' : '$validCount reviews';
    return '${validRating.toStringAsFixed(1)} / 5.0 ($countLabel)';
  }

  /// Format short rating score with maximum 5.0, e.g. "0.0 / 5.0" or "4.5 / 5.0"
  static String formatRatingScore(double? rating, [int count = 0]) {
    if (count == 0 || rating == null) return '0.0 / 5.0';
    return '${rating.clamp(0.0, 5.0).toStringAsFixed(1)} / 5.0';
  }

  /// Format Need Until: e.g. "Today, 4:00 PM", "Tomorrow, 10:00 AM", or "12 Oct, 4:00 PM"
  static String formatNeedUntil(DateTime? date, String? time) {
    if (date == null) return time ?? 'N/A';
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow =
        date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;

    final timeStr = (time != null && time.isNotEmpty) ? ', $time' : '';

    if (isToday) {
      return 'Today$timeStr';
    } else if (isTomorrow) {
      return 'Tomorrow$timeStr';
    } else {
      return '${DateFormat('d MMM').format(date)}$timeStr';
    }
  }

  /// Color coding for request & item statuses
  static Color getStatusColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'available':
        return const Color(0xFF10B981); // Emerald
      case 'reserved':
        return const Color(0xFFF59E0B); // Amber
      case 'borrowed':
        return const Color(0xFF3B82F6); // Blue
      case 'inactive':
        return const Color(0xFF94A3B8); // Slate Gray
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'matching':
        return const Color(0xFF06B6D4); // Cyan
      case 'approved':
        return const Color(0xFF10B981); // Emerald
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFEF4444); // Red
      case 'ready_for_pickup':
      case 'scheduled':
        return const Color(0xFF3B82F6); // Blue
      case 'active':
        return const Color(0xFF8B5CF6); // Violet / Purple
      case 'return_pending':
      case 'return_requested':
        return const Color(0xFFF97316); // Orange
      case 'completed':
      case 'returned':
        return const Color(0xFF14B8A6); // Teal
      default:
        return const Color(0xFF64748B);
    }
  }

  /// Human-friendly status label
  static String getStatusLabel(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'available':
        return 'Available';
      case 'reserved':
        return 'Reserved';
      case 'borrowed':
        return 'Borrowed';
      case 'inactive':
        return 'Inactive';
      case 'pending':
        return 'Pending';
      case 'matching':
        return 'Matching';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'ready_for_pickup':
      case 'scheduled':
        return 'Ready for Pickup';
      case 'active':
        return 'Active';
      case 'return_pending':
      case 'return_requested':
        return 'Return Pending';
      case 'completed':
      case 'returned':
        return 'Completed';
      default:
        return status.replaceAll('_', ' ').trim();
    }
  }

  /// Show standard modern snackbars
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : isSuccess
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : isSuccess
            ? const Color(0xFF059669)
            : const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Confirmation dialog modal
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              cancelLabel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? const Color(0xFFDC2626) : null,
              foregroundColor: isDestructive ? Colors.white : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
