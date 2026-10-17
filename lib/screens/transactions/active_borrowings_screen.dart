import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../app/routes.dart';
import '../../utils/helpers.dart';
import '../../services/chat_service.dart';
import '../../widgets/transaction_card.dart';
import '../../widgets/empty_state.dart';

class ActiveBorrowingsScreen extends StatefulWidget {
  const ActiveBorrowingsScreen({super.key});

  @override
  State<ActiveBorrowingsScreen> createState() => _ActiveBorrowingsScreenState();
}

class _ActiveBorrowingsScreenState extends State<ActiveBorrowingsScreen>
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

  void _showRatingModal(TransactionModel transaction, String currentUserId) {
    Navigator.pushNamed(
      context,
      AppRoutes.feedback,
      arguments: transaction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final txnProvider = Provider.of<TransactionProvider>(context);
    final currentUserId = authProvider.currentUser?.uid ?? '';

    final activeList = txnProvider.activeTransactions;
    final historyList = txnProvider.historyTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrowings & Handover'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Active / Scheduled'),
                  if (activeList.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${activeList.length}',
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
            const Tab(text: 'Past History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active List
          activeList.isEmpty
              ? const EmptyState(
                  icon: Icons.handshake_outlined,
                  title: 'No Active Borrowings',
                  description:
                      'You currently have no active item loans or pending handovers. Check your requests to get started.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: activeList.length,
                  itemBuilder: (context, index) {
                    final txn = activeList[index];
                    return TransactionCard(
                      transaction: txn,
                      currentUserId: currentUserId,
                      onHandoverReady: () async {
                        final confirm = await AppHelpers.showConfirmDialog(
                          context: context,
                          title: 'Confirm Handover Readiness',
                          message:
                              'Are you at the agreed campus pickup spot and ready to exchange "${txn.itemName}"?',
                          confirmLabel: 'I am Ready',
                        );
                        if (confirm && context.mounted) {
                          await txnProvider.confirmHandoverReadiness(
                            txn.id,
                            currentUserId,
                          );
                          if (context.mounted) {
                            AppHelpers.showSnackBar(
                              context,
                              'Readiness confirmed!',
                              isSuccess: true,
                            );
                          }
                        }
                      },
                      onReturnRequest: () async {
                        final confirm = await AppHelpers.showConfirmDialog(
                          context: context,
                          title: 'Request Return',
                          message:
                              'Ready to return "${txn.itemName}" to ${txn.ownerName}? The owner will inspect the item and confirm receipt.',
                          confirmLabel: 'Request Return',
                        );
                        if (confirm && context.mounted) {
                          await txnProvider.requestReturn(
                            txn.id,
                            currentUserId,
                          );
                          if (context.mounted) {
                            AppHelpers.showSnackBar(
                              context,
                              'Return requested! Awaiting owner confirmation.',
                              isSuccess: true,
                            );
                          }
                        }
                      },
                      onConfirmReturn: () async {
                        final confirm = await AppHelpers.showConfirmDialog(
                          context: context,
                          title: 'Confirm Return Receipt',
                          message:
                              'Have you inspected "${txn.itemName}" and received it back in proper condition from ${txn.borrowerName}?',
                          confirmLabel: 'Confirm Return',
                        );
                        if (confirm && context.mounted) {
                          await txnProvider.confirmReturnReceipt(
                            txn.id,
                            currentUserId,
                          );
                          if (context.mounted) {
                            AppHelpers.showSnackBar(
                              context,
                              'Return confirmed! Transaction completed.',
                              isSuccess: true,
                            );
                            _showRatingModal(txn, currentUserId);
                          }
                        }
                      },
                      onRate: () => _showRatingModal(txn, currentUserId),
                      onOpenChat: () {
                        final chatId = ChatService.buildChatId(
                          requestId: txn.requestId,
                          borrowerId: txn.borrowerId,
                          helperId: txn.ownerId,
                        );
                        Navigator.pushNamed(
                          context,
                          AppRoutes.chat,
                          arguments: chatId,
                        );
                      },
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.borrowingDetails,
                          arguments: txn,
                        );
                      },
                    );
                  },
                ),

          // History List
          historyList.isEmpty
              ? const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No Completed History',
                  description:
                      'Completed campus borrowings and returned items will be recorded here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    final txn = historyList[index];
                    return TransactionCard(
                      transaction: txn,
                      currentUserId: currentUserId,
                      onHandoverReady: () {},
                      onReturnRequest: () {},
                      onConfirmReturn: () {},
                      onRate: () => _showRatingModal(txn, currentUserId),
                      onOpenChat: () {
                        final chatId = ChatService.buildChatId(
                          requestId: txn.requestId,
                          borrowerId: txn.borrowerId,
                          helperId: txn.ownerId,
                        );
                        Navigator.pushNamed(
                          context,
                          AppRoutes.chat,
                          arguments: chatId,
                        );
                      },
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.borrowingDetails,
                          arguments: txn,
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
