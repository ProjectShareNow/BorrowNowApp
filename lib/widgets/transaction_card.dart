import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/helpers.dart';
import 'status_chip.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final String currentUserId;
  final VoidCallback onHandoverReady;
  final VoidCallback onReturnRequest;
  final VoidCallback onConfirmReturn;
  final VoidCallback onRate;
  final VoidCallback onOpenChat;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.currentUserId,
    required this.onHandoverReady,
    required this.onReturnRequest,
    required this.onConfirmReturn,
    required this.onRate,
    required this.onOpenChat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = transaction.ownerId == currentUserId;
    final isBorrower = transaction.borrowerId == currentUserId;
    final isUserReady = isOwner
        ? transaction.ownerReady
        : transaction.borrowerReady;

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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOwner
                              ? 'Borrower: ${transaction.borrowerName}'
                              : 'Owner: ${transaction.ownerName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: transaction.status),
                ],
              ),
              const Divider(height: 20),

              // Handover Readiness Indicators (when scheduled)
              if (transaction.isScheduled) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Handover Readiness Check',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReadinessPill(
                            label: 'Owner Ready',
                            isReady: transaction.ownerReady,
                          ),
                          const Icon(
                            Icons.swap_horiz_rounded,
                            color: Colors.grey,
                          ),
                          _buildReadinessPill(
                            label: 'Borrower Ready',
                            isReady: transaction.borrowerReady,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Timestamps
              if (transaction.pickupTime != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Picked up: ${AppHelpers.formatDateTime(transaction.pickupTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

              if (transaction.returnedAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 14,
                        color: Colors.teal.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Returned: ${AppHelpers.formatDateTime(transaction.returnedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

              // Action Buttons
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onOpenChat,
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                    ),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(90, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPrimaryAction(
                      isOwner: isOwner,
                      isBorrower: isBorrower,
                      isUserReady: isUserReady,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadinessPill({required String label, required bool isReady}) {
    return Row(
      children: [
        Icon(
          isReady
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: isReady ? const Color(0xFF10B981) : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isReady ? const Color(0xFF0F766E) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryAction({
    required bool isOwner,
    required bool isBorrower,
    required bool isUserReady,
  }) {
    if (transaction.isScheduled) {
      if (isUserReady) {
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_top_rounded, size: 16),
          label: const Text('Waiting for Other Party'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(38),
          ),
        );
      }
      return ElevatedButton.icon(
        onPressed: onHandoverReady,
        icon: const Icon(Icons.handshake_outlined, size: 16),
        label: const Text('Confirm Ready at Pickup'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E40AF),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(38),
        ),
      );
    }

    if (transaction.isActive) {
      if (isBorrower) {
        return ElevatedButton.icon(
          onPressed: onReturnRequest,
          icon: const Icon(Icons.keyboard_return_rounded, size: 16),
          label: const Text('Request Return'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(38),
          ),
        );
      } else {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Item currently in use',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
    }

    if (transaction.isReturnRequested) {
      if (isOwner) {
        return ElevatedButton.icon(
          onPressed: onConfirmReturn,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Confirm Received Return'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(38),
          ),
        );
      } else {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Text(
            'Return requested. Awaiting owner inspection.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
    }

    if (transaction.isCompleted) {
      final userRated = transaction.hasUserRated(currentUserId);
      final otherRated = transaction.hasOtherPartyRated(currentUserId);
      final isOwnerRole = transaction.ownerId == currentUserId;
      final otherRole = isOwnerRole ? 'Borrower' : 'Lender';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: onRate,
            icon: Icon(
              userRated ? Icons.check_circle_outline_rounded : Icons.star_rate_rounded,
              size: 16,
            ),
            label: Text(userRated ? 'Feedback Submitted ✓' : 'Rate & Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: userRated ? const Color(0xFF0F766E) : Colors.amber.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(38),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            otherRated
                ? '$otherRole submitted feedback'
                : '$otherRole feedback pending',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: otherRated ? const Color(0xFF0F766E) : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
