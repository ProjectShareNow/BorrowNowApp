import 'package:flutter/material.dart';
import '../models/borrow_request_model.dart';
import '../utils/helpers.dart';
import 'status_chip.dart';
import 'user_avatar.dart';

class RequestCard extends StatelessWidget {
  final BorrowRequestModel request;
  final bool isIncoming;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final Function(String helperId, String helperName)? onAcceptHelper;
  final Function(String helperId)? onRemoveHelper;
  final Function(String helperId)? onRejectHelper;
  final VoidCallback? onOpenChat;
  final VoidCallback? onTap;

  const RequestCard({
    super.key,
    required this.request,
    this.isIncoming = false,
    this.onApprove,
    this.onReject,
    this.onCancel,
    this.onAcceptHelper,
    this.onRemoveHelper,
    this.onRejectHelper,
    this.onOpenChat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: User details and status chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  UserAvatar(
                    name: isIncoming ? request.borrowerName : 'Owner',
                    imageUrl: request.borrowerPhotoUrl,
                    radius: 18,
                    rating: request.borrowerRating,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isIncoming
                              ? request.borrowerName
                              : 'Request for ${request.itemName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (isIncoming && request.borrowerDepartment.isNotEmpty)
                          Text(
                            request.borrowerDepartment,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  StatusChip(status: request.status),
                ],
              ),
              const Divider(height: 20),

              // Item and Booking Details
              Row(
                children: [
                  const Icon(
                    Icons.bookmark_border_rounded,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              if (request.requiredDate != null ||
                  request.requiredTime.isNotEmpty ||
                  request.duration.isNotEmpty) ...[
                Row(
                  children: [
                    if (request.requiredDate != null ||
                        request.requiredTime.isNotEmpty) ...[
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        request.requiredDate != null
                            ? (request.requiredTime.isNotEmpty
                                ? '${AppHelpers.formatDate(request.requiredDate)} at ${request.requiredTime}'
                                : AppHelpers.formatDate(request.requiredDate))
                            : 'Time: ${request.requiredTime}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if ((request.requiredDate != null ||
                            request.requiredTime.isNotEmpty) &&
                        request.duration.isNotEmpty)
                      const SizedBox(width: 12),
                    if (request.duration.isNotEmpty) ...[
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Duration: ${request.duration}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pickup: ${request.pickupLocation}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),

              // Optional note message
              if (request.message != null && request.message!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '"${request.message}"',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Helpers who offered help (with Single Accepted Helper Locking)
              if (!isIncoming && request.helpers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.volunteer_activism_rounded,
                                size: 16,
                                color: Color(0xFF2563EB),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Helpers',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                          if (request.acceptedHelperId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: const Text(
                                'Helper Locked',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...request.helpers.map((h) {
                        final helperId = h['helperId']?.toString() ?? '';
                        final name = h['name']?.toString() ??
                            h['helperName']?.toString() ??
                            'Student';
                        final dept = h['department']?.toString() ??
                            h['helperDepartment']?.toString() ??
                            '';
                        final isAccepted = request.acceptedHelperId == helperId;
                        final isRejected =
                            request.rejectedHelperIds.contains(helperId) ||
                                h['status'] == 'rejected';
                        final isOtherAccepted =
                            request.acceptedHelperId != null && !isAccepted;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isAccepted
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFE2E8F0),
                              width: isAccepted ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$name ${dept.isNotEmpty ? "($dept)" : ""}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  if (isAccepted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Accepted',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    )
                                  else if (isRejected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Rejected',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    )
                                  else if (isOtherAccepted)
                                    const Text(
                                      'Not Selected',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    )
                                  else
                                    const Text(
                                      'Waiting for your decision',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFD97706),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              if (isAccepted) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            onRemoveHelper?.call(helperId),
                                        icon: const Icon(
                                          Icons.person_remove_outlined,
                                          size: 14,
                                          color: Color(0xFFDC2626),
                                        ),
                                        label: const Text(
                                          'Remove',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFDC2626),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFFFCA5A5),
                                          ),
                                          minimumSize:
                                              const Size.fromHeight(32),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (onOpenChat != null) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: onOpenChat,
                                          icon: const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            'Open Chat',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            minimumSize:
                                                const Size.fromHeight(32),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ] else if (request.acceptedHelperId == null &&
                                  !isRejected) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            onRejectHelper?.call(helperId),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFDC2626),
                                          side: const BorderSide(
                                            color: Color(0xFFFCA5A5),
                                          ),
                                          minimumSize:
                                              const Size.fromHeight(32),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Reject',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => onAcceptHelper?.call(
                                          helperId,
                                          name,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF16A34A),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          minimumSize:
                                              const Size.fromHeight(32),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Accept',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              if (request.isRejected && request.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Reason: ${request.rejectionReason}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // Actions
              if (request.isPending) ...[
                const SizedBox(height: 14),
                if (isIncoming)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            minimumSize: const Size.fromHeight(38),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onApprove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(38),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  )
                else
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300),
                      minimumSize: const Size.fromHeight(38),
                    ),
                    child: const Text('Cancel Request'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
