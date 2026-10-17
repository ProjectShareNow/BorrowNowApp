import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../app/routes.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).listenToUserTransactions(auth.currentUser!.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final txnProvider = Provider.of<TransactionProvider>(context);
    final currentUserId = authProvider.currentUser?.uid ?? '';

    final allHistory = txnProvider.historyTransactions;
    final borrowingHistory =
        allHistory.where((t) => t.borrowerId == currentUserId).toList();
    final lendingHistory =
        allHistory.where((t) => t.ownerId == currentUserId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2563EB),
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          tabs: [
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Borrowing History'),
                    if (borrowingHistory.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${borrowingHistory.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Lending History'),
                    if (lendingHistory.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${lendingHistory.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Borrowing History Tab
          borrowingHistory.isEmpty
              ? const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No Borrowing History',
                  description:
                      'When you borrow and return items on campus, your records will appear here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: borrowingHistory.length,
                  itemBuilder: (context, index) {
                    final txn = borrowingHistory[index];
                    return _buildHistoryCard(
                      context,
                      transaction: txn,
                      isBorrower: true,
                    );
                  },
                ),

          // Lending History Tab
          lendingHistory.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No Lending History',
                  description:
                      'Items you share with peers and receive back will be safely recorded here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: lendingHistory.length,
                  itemBuilder: (context, index) {
                    final txn = lendingHistory[index];
                    return _buildHistoryCard(
                      context,
                      transaction: txn,
                      isBorrower: false,
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context, {
    required TransactionModel transaction,
    required bool isBorrower,
  }) {
    final otherPartyRole = isBorrower ? 'Owner' : 'Borrower';
    final otherPartyName =
        isBorrower ? transaction.ownerName : transaction.borrowerName;
    final displayDate = transaction.returnedAt ??
        transaction.updatedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.borrowingDetails,
            arguments: transaction,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isBorrower
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isBorrower
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFFDDD6FE),
                      ),
                    ),
                    child: Icon(
                      isBorrower
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: isBorrower
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF7C3AED),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$otherPartyRole: $otherPartyName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: transaction.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.event_available_outlined,
                        size: 15,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Completed: ${AppHelpers.formatDate(displayDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
