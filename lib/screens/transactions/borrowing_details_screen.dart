import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../app/routes.dart';
import '../../utils/helpers.dart';
import '../../services/chat_service.dart';
import '../../widgets/status_chip.dart';

class BorrowingDetailsScreen extends StatelessWidget {
  final TransactionModel transaction;

  const BorrowingDetailsScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Open Chat',
            onPressed: () {
              final chatId = ChatService.buildChatId(
                requestId: transaction.requestId,
                borrowerId: transaction.borrowerId,
                helperId: transaction.ownerId,
              );
              Navigator.pushNamed(
                context,
                AppRoutes.chat,
                arguments: chatId,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.report_problem_outlined),
            tooltip: 'Report Issue / Dispute',
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.submitReport,
                arguments: {
                  'itemId': transaction.itemId,
                  'transactionId': transaction.id,
                  'reportedUserId': transaction.borrowerId,
                  'reportedUserName': transaction.borrowerName,
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Item Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TRANSACTION #${transaction.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      StatusChip(status: transaction.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    transaction.itemName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Started on ${AppHelpers.formatDateTime(transaction.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Participants Card
            const Text(
              'Participants',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildParticipantRow(
                    role: 'Item Owner (Lender)',
                    name: transaction.ownerName,
                    icon: Icons.person_rounded,
                    isReady: transaction.ownerReady,
                  ),
                  const Divider(height: 20),
                  _buildParticipantRow(
                    role: 'Borrower (Student)',
                    name: transaction.borrowerName,
                    icon: Icons.school_rounded,
                    isReady: transaction.borrowerReady,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Timeline Steps
            const Text(
              'Borrowing Lifecycle Timeline',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTimelineTile(
              title: 'Request Approved & Scheduled',
              subtitle: AppHelpers.formatDateTime(transaction.createdAt),
              isCompleted: true,
              isFirst: true,
            ),
            _buildTimelineTile(
              title: 'Handover & Pickup Confirmation',
              subtitle: transaction.pickupConfirmed
                  ? 'Confirmed on ${AppHelpers.formatDateTime(transaction.pickupTime)}'
                  : 'Pending both parties confirming readiness at pickup spot',
              isCompleted: transaction.pickupConfirmed,
            ),
            _buildTimelineTile(
              title: 'Return Request',
              subtitle: transaction.returnRequestedAt != null
                  ? 'Requested on ${AppHelpers.formatDateTime(transaction.returnRequestedAt)}'
                  : 'Borrower will initiate return upon completion',
              isCompleted: transaction.returnRequestedAt != null,
            ),
            _buildTimelineTile(
              title: 'Owner Return Inspection & Final Receipt',
              subtitle: transaction.returnedAt != null
                  ? 'Verified returned on ${AppHelpers.formatDateTime(transaction.returnedAt)}'
                  : 'Awaiting owner confirmation to complete transaction',
              isCompleted: transaction.isCompleted,
              isLast: true,
            ),
            const SizedBox(height: 32),

            if (transaction.isCompleted) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.feedback,
                      arguments: transaction,
                    );
                  },
                  icon: const Icon(Icons.star_rate_rounded, size: 18),
                  label: const Text('Ratings & Feedback'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Open Chat Shortcut
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final chatId = ChatService.buildChatId(
                    requestId: transaction.requestId,
                    borrowerId: transaction.borrowerId,
                    helperId: transaction.ownerId,
                  );
                  Navigator.pushNamed(
                    context,
                    AppRoutes.chat,
                    arguments: chatId,
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Open Handover Chat'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantRow({
    required String role,
    required String name,
    required IconData icon,
    required bool isReady,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF1E40AF).withValues(alpha: 0.1),
          child: Icon(icon, size: 18, color: const Color(0xFF1E40AF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isReady ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isReady ? Colors.green.shade200 : Colors.grey.shade300,
            ),
          ),
          child: Text(
            isReady ? 'Ready' : 'Pending',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isReady ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTile({
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? const Color(0xFF0F172A)
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
