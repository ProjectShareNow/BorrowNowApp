import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTab = 'Active'; // Active, Overdue, Returned, All

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.currentUser == null || !auth.currentUser!.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'Administrative authorization required.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final adminProvider = Provider.of<AdminProvider>(context);
    final transactions = adminProvider.allTransactions.where((t) {
      if (_selectedTab == 'Active') {
        if (!t.isActive && !t.isScheduled && !t.isReturnRequested) return false;
      } else if (_selectedTab == 'Overdue') {
        if (!t.isOverdue) return false;
      } else if (_selectedTab == 'Returned') {
        if (!t.isReturned && !t.isCompleted) return false;
      }
      if (_searchQuery.isNotEmpty) {
        return t.itemName.toLowerCase().contains(_searchQuery) ||
            t.borrowerName.toLowerCase().contains(_searchQuery) ||
            t.ownerName.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions & Returns')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by item, borrower, or owner...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: ['Active', 'Overdue', 'Returned', 'All']
                  .map(
                    (tab) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tab, style: const TextStyle(fontSize: 12)),
                        selected: _selectedTab == tab,
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedTab = tab);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Transactions List
          Expanded(
            child: transactions.isEmpty
                ? const EmptyState(
                    icon: Icons.handshake_outlined,
                    title: 'No Transactions Found',
                    description: 'No transactions match the selected filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 14),
                    itemBuilder: (context, index) {
                      final txn = transactions[index];
                      final isOverdue = txn.isOverdue;

                      Color badgeColor = Colors.blue;
                      String badgeText = txn.status.toUpperCase();
                      if (isOverdue) {
                        badgeColor = Colors.red;
                        badgeText = 'OVERDUE';
                      } else if (txn.isCompleted || txn.isReturned) {
                        badgeColor = Colors.green;
                      } else if (txn.isReturnRequested) {
                        badgeColor = Colors.amber.shade800;
                        badgeText = 'RETURN REQUESTED';
                      }

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      txn.itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: badgeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Borrower: ${txn.borrowerName} • Owner: ${txn.ownerName}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Handover: ${txn.pickupTime != null ? AppHelpers.formatDate(txn.pickupTime!) : "Scheduled"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (txn.expectedReturnDate != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event_outlined,
                                      size: 14,
                                      color: isOverdue
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Expected Return: ${AppHelpers.formatDate(txn.expectedReturnDate!)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isOverdue
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isOverdue
                                            ? Colors.red.shade700
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (isOverdue &&
                                  txn.expectedReturnDate != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${DateTime.now().difference(txn.expectedReturnDate!).inDays} days overdue',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
