import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item_model.dart';
import '../../models/borrow_request_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';

class AdminItemsTransactionsScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdminItemsTransactionsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AdminItemsTransactionsScreen> createState() =>
      _AdminItemsTransactionsScreenState();
}

class _AdminItemsTransactionsScreenState
    extends State<AdminItemsTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedItemFilter = 'All';
  String _selectedRequestFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showDeactivateItemDialog(BuildContext context, ItemModel item) {
    final reasonController = TextEditingController();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminUid = auth.currentUser?.uid ?? 'admin';
    final adminName = auth.currentUser?.fullName ?? 'Campus Administrator';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Expanded(child: Text('Deactivate Listing')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remove "${item.name}" from the campus sharing catalog?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Listed by: ${item.ownerName} (${item.ownerDepartment})',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for Deactivation *',
                hintText:
                    'e.g. Inappropriate item, prohibited equipment, duplicate listing...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                AppHelpers.showSnackBar(
                  context,
                  'Please specify a reason for deactivating this listing.',
                  isError: true,
                );
                return;
              }
              Navigator.pop(ctx);
              final adminProvider = Provider.of<AdminProvider>(
                context,
                listen: false,
              );
              final success = await adminProvider.adminDeactivateItem(
                itemId: item.id,
                reason: reason,
                adminUid: adminUid,
                adminName: adminName,
              );
              if (context.mounted) {
                if (success) {
                  AppHelpers.showSnackBar(
                    context,
                    'Listing "${item.name}" deactivated successfully.',
                    isSuccess: true,
                  );
                } else {
                  AppHelpers.showSnackBar(
                    context,
                    adminProvider.errorMessage ??
                        'Failed to deactivate listing.',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Confirm Deactivation'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);

    // Safeguard
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

    final allItems = adminProvider.allItems;
    final allRequests = adminProvider.allBorrowRequests;
    final allTransactions = adminProvider.allTransactions;
    final overdueTransactions = allTransactions
        .where((t) => t.isOverdue)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Items & Transactions'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_outlined, size: 20),
              text: 'Listings (${allItems.length})',
            ),
            Tab(
              icon: const Icon(Icons.pending_actions_outlined, size: 20),
              text: 'Requests (${allRequests.length})',
            ),
            Tab(
              icon: const Icon(Icons.handshake_outlined, size: 20),
              text:
                  'Active (${allTransactions.where((t) => t.isActive || t.isScheduled || t.isReturnRequested).length})',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: overdueTransactions.isNotEmpty,
                label: Text('${overdueTransactions.length}'),
                child: const Icon(Icons.alarm_off_outlined, size: 20),
              ),
              text: 'Overdue (${overdueTransactions.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items, students, locations...',
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

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemsTab(allItems),
                _buildRequestsTab(allRequests),
                _buildActiveTransactionsTab(allTransactions),
                _buildOverdueTab(overdueTransactions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: ALL ITEMS ---
  Widget _buildItemsTab(List<ItemModel> items) {
    var filtered = items.where((item) {
      if (_selectedItemFilter != 'All' &&
          item.availability.toLowerCase() !=
              _selectedItemFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return item.name.toLowerCase().contains(_searchQuery) ||
            item.description.toLowerCase().contains(_searchQuery) ||
            item.ownerName.toLowerCase().contains(_searchQuery) ||
            item.category.toLowerCase().contains(_searchQuery) ||
            item.pickupLocation.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: ['All', 'Available', 'Reserved', 'Borrowed', 'Inactive']
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      selected: _selectedItemFilter == f,
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedItemFilter = f);
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No Items Found',
                  description: 'No item listings match the current filter.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isInactive = item.isInactive;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey.shade200,
                                child: item.photoUrl.isNotEmpty
                                    ? Image.network(
                                        item.photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.image_outlined,
                                                ),
                                      )
                                    : const Icon(Icons.image_outlined),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isInactive
                                              ? Colors.red.shade50
                                              : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          item.availability.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isInactive
                                                ? Colors.red.shade700
                                                : Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.category} • ${item.condition}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Owner: ${item.ownerName} (${item.ownerDepartment})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (!isInactive)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _showDeactivateItemDialog(
                                              context,
                                              item,
                                            ),
                                        icon: const Icon(
                                          Icons.block_rounded,
                                          size: 14,
                                          color: Colors.red,
                                        ),
                                        label: const Text(
                                          'Deactivate Listing',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: Colors.red.shade200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 2: BORROW REQUESTS ---
  Widget _buildRequestsTab(List<BorrowRequestModel> requests) {
    var filtered = requests.where((r) {
      if (_selectedRequestFilter != 'All' &&
          r.status.toLowerCase() != _selectedRequestFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return r.itemName.toLowerCase().contains(_searchQuery) ||
            r.borrowerName.toLowerCase().contains(_searchQuery) ||
            r.pickupLocation.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children:
                [
                      'All',
                      'Pending',
                      'Approved',
                      'Rejected',
                      'Cancelled',
                      'Active',
                      'Returned',
                    ]
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f, style: const TextStyle(fontSize: 12)),
                          selected: _selectedRequestFilter == f,
                          onSelected: (sel) {
                            if (sel) setState(() => _selectedRequestFilter = f);
                          },
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.pending_actions_outlined,
                  title: 'No Borrow Requests',
                  description: 'No requests match the selected status.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 14),
                  itemBuilder: (context, index) {
                    final r = filtered[index];
                    Color statusColor = Colors.orange;
                    if (r.isApproved || r.isActive) statusColor = Colors.green;
                    if (r.isRejected || r.isCancelled) statusColor = Colors.red;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    r.itemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    r.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Borrower: ${r.borrowerName} (${r.borrowerDepartment})',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              () {
                                final parts = <String>[];
                                if (r.requiredDate != null) {
                                  parts.add(r.requiredTime.isNotEmpty
                                      ? 'Required: ${AppHelpers.formatDate(r.requiredDate)} at ${r.requiredTime}'
                                      : 'Required: ${AppHelpers.formatDate(r.requiredDate)}');
                                } else if (r.requiredTime.isNotEmpty) {
                                  parts.add('Required at ${r.requiredTime}');
                                }
                                if (r.duration.isNotEmpty) {
                                  parts.add('(${r.duration})');
                                }
                                return parts.isNotEmpty ? parts.join(' ') : 'Required: Flexible';
                              }(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (r.message != null && r.message!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '"${r.message}"',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade700,
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
    );
  }

  // --- TAB 3: ACTIVE TRANSACTIONS ---
  Widget _buildActiveTransactionsTab(List<TransactionModel> transactions) {
    final activeList = transactions.where((t) {
      final isRelevant = t.isActive || t.isScheduled || t.isReturnRequested;
      if (!isRelevant) return false;
      if (_searchQuery.isNotEmpty) {
        return t.itemName.toLowerCase().contains(_searchQuery) ||
            t.borrowerName.toLowerCase().contains(_searchQuery) ||
            t.ownerName.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return activeList.isEmpty
        ? const EmptyState(
            icon: Icons.handshake_outlined,
            title: 'No Active Transactions',
            description: 'There are currently no items checked out on campus.',
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activeList.length,
            separatorBuilder: (ctx, i) => const Divider(height: 14),
            itemBuilder: (context, index) {
              final txn = activeList[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              color: txn.isOverdue
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              txn.isOverdue
                                  ? 'OVERDUE'
                                  : txn.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: txn.isOverdue
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Borrower: ${txn.borrowerName}  |  Owner: ${txn.ownerName}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Picked Up: ${txn.pickupTime != null ? AppHelpers.formatDate(txn.pickupTime!) : "Scheduled"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (txn.expectedReturnDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Expected Return: ${AppHelpers.formatDate(txn.expectedReturnDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: txn.isOverdue
                                ? Colors.red.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
  }

  // --- TAB 4: OVERDUE RETURNS ---
  Widget _buildOverdueTab(List<TransactionModel> overdueList) {
    final filtered = overdueList.where((t) {
      if (_searchQuery.isNotEmpty) {
        return t.itemName.toLowerCase().contains(_searchQuery) ||
            t.borrowerName.toLowerCase().contains(_searchQuery) ||
            t.ownerName.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return filtered.isEmpty
        ? const EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'No Overdue Returns!',
            description:
                'Great! All borrowed campus items are on schedule and returned promptly.',
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (ctx, i) => const Divider(height: 14),
            itemBuilder: (context, index) {
              final txn = filtered[index];
              final expected =
                  txn.expectedReturnDate ??
                  txn.pickupTime?.add(const Duration(days: 3)) ??
                  DateTime.now();
              final overdueDays = DateTime.now()
                  .difference(expected)
                  .inDays
                  .clamp(1, 999);

              return Card(
                color: Colors.red.shade50.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              txn.itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$overdueDays DAYS OVERDUE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Borrower: ${txn.borrowerName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Owner / Lender: ${txn.ownerName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due date was: ${AppHelpers.formatDate(expected)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
