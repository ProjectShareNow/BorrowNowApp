import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';

class AdminBorrowRequestsScreen extends StatefulWidget {
  const AdminBorrowRequestsScreen({super.key});

  @override
  State<AdminBorrowRequestsScreen> createState() =>
      _AdminBorrowRequestsScreenState();
}

class _AdminBorrowRequestsScreenState extends State<AdminBorrowRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';

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
    final requests = adminProvider.allBorrowRequests.where((r) {
      if (_selectedStatus != 'All' &&
          r.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return r.itemName.toLowerCase().contains(_searchQuery) ||
            r.borrowerName.toLowerCase().contains(_searchQuery) ||
            r.pickupLocation.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Requests')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by item, borrower, or location...',
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
                            label: Text(
                              f,
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: _selectedStatus == f,
                            onSelected: (sel) {
                              if (sel) setState(() => _selectedStatus = f);
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

          // Requests List
          Expanded(
            child: requests.isEmpty
                ? const EmptyState(
                    icon: Icons.pending_actions_outlined,
                    title: 'No Borrow Requests Found',
                    description: 'No requests match the current criteria.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 14),
                    itemBuilder: (context, index) {
                      final r = requests[index];

                      Color statusColor = Colors.orange;
                      if (r.isApproved || r.isActive) {
                        statusColor = Colors.green;
                      }
                      if (r.isRejected || r.isCancelled) {
                        statusColor = Colors.red;
                      }
                      if (r.isReturned) {
                        statusColor = Colors.blue;
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
                                      r.itemName,
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
                                      color: statusColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
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
                              const SizedBox(height: 8),
                              Text(
                                'Borrower: ${r.borrowerName} (${r.borrowerDepartment})',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
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
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (r.pickupLocation.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Pickup: ${r.pickupLocation}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                              if (r.message != null &&
                                  r.message!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '"${r.message}"',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade700,
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
