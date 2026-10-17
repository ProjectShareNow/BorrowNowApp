import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../../services/service_registry.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';

class AdminLeaderboardScreen extends StatefulWidget {
  const AdminLeaderboardScreen({super.key});

  @override
  State<AdminLeaderboardScreen> createState() => _AdminLeaderboardScreenState();
}

class _AdminLeaderboardScreenState extends State<AdminLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDepartment = 'All';
  String _selectedPeriod =
      'All Time'; // 'All Time', 'This Month', 'This Semester'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isWithinPeriod(DateTime date) {
    final now = DateTime.now();
    if (_selectedPeriod == 'This Month') {
      return date.year == now.year && date.month == now.month;
    } else if (_selectedPeriod == 'This Semester') {
      // 6-month semester window
      final sixMonthsAgo = now.subtract(const Duration(days: 180));
      return date.isAfter(sixMonthsAgo);
    }
    return true; // All Time
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Sharing Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.emoji_events_rounded),
              text: 'Top Contributors',
            ),
            Tab(icon: Icon(Icons.volunteer_activism), text: 'Top Lenders'),
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Top Borrowers'),
            Tab(icon: Icon(Icons.star_rounded), text: 'Highest Rated'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Bar: Department and Time Period
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Department Dropdown
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Dept: ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedDepartment,
                          isDense: true,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: ['All', ...AppConstants.departments]
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    d,
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedDepartment = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Time Period Dropdown
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Period: ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          isDense: true,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: ['All Time', 'This Month', 'This Semester']
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p,
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPeriod = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Leaderboard Lists
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: ServiceRegistry.adminService.getAllUsersStream(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<List<TransactionModel>>(
                  stream: ServiceRegistry.transactionService
                      .getAllTransactionsStream(),
                  builder: (context, txnSnapshot) {
                    var users = userSnapshot.data ?? [];
                    var txns = txnSnapshot.data ?? [];

                    // Filter out non-students and deactivated accounts
                    users = users
                        .where((u) => !u.isAdmin && u.isActive)
                        .toList();
                    if (_selectedDepartment != 'All') {
                      users = users
                          .where((u) => u.department == _selectedDepartment)
                          .toList();
                    }

                    // Filter completed transactions by period
                    final completedTxns = txns
                        .where(
                          (t) => t.isCompleted && _isWithinPeriod(t.updatedAt),
                        )
                        .toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverallList(users, completedTxns),
                        _buildLendersList(users, completedTxns),
                        _buildBorrowersList(users, completedTxns),
                        _buildRatedList(users),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallList(List<UserModel> users, List<TransactionModel> txns) {
    final Map<String, int> lendCounts = {};
    final Map<String, int> borrowCounts = {};

    for (final t in txns) {
      lendCounts[t.ownerId] = (lendCounts[t.ownerId] ?? 0) + 1;
      borrowCounts[t.borrowerId] = (borrowCounts[t.borrowerId] ?? 0) + 1;
    }

    final sorted = List<UserModel>.from(users)
      ..sort((a, b) {
        final aTotal =
            (lendCounts[a.uid] ?? a.itemsListedCount) +
            (borrowCounts[a.uid] ?? a.borrowedCount);
        final bTotal =
            (lendCounts[b.uid] ?? b.itemsListedCount) +
            (borrowCounts[b.uid] ?? b.borrowedCount);
        if (bTotal != aTotal) return bTotal.compareTo(aTotal);
        return b.ratingAverage.compareTo(a.ratingAverage);
      });

    if (sorted.isEmpty) {
      return const EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No Student Activity',
        description: 'No student transactions recorded in this period.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final u = sorted[i];
        final lCount = lendCounts[u.uid] ?? u.itemsListedCount;
        final bCount = borrowCounts[u.uid] ?? u.borrowedCount;
        final total = lCount + bCount;

        return _buildLeaderboardTile(
          rank: i + 1,
          name: u.fullName,
          department: u.department,
          metricLabel: '$total txns ($lCount lent, $bCount borrowed)',
          rating: u.ratingAverage,
          icon: Icons.stars_rounded,
          iconColor: const Color(0xFFD97706),
        );
      },
    );
  }

  Widget _buildLendersList(List<UserModel> users, List<TransactionModel> txns) {
    final Map<String, int> lendCounts = {};
    for (final t in txns) {
      lendCounts[t.ownerId] = (lendCounts[t.ownerId] ?? 0) + 1;
    }

    final sorted = List<UserModel>.from(users)
      ..sort((a, b) {
        final aCount = lendCounts[a.uid] ?? a.itemsListedCount;
        final bCount = lendCounts[b.uid] ?? b.itemsListedCount;
        return bCount.compareTo(aCount);
      });

    if (sorted.isEmpty) {
      return const EmptyState(
        icon: Icons.volunteer_activism_outlined,
        title: 'No Lenders Found',
        description:
            'No completed lending transactions for the selected filter.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final u = sorted[i];
        final count = lendCounts[u.uid] ?? u.itemsListedCount;
        return _buildLeaderboardTile(
          rank: i + 1,
          name: u.fullName,
          department: u.department,
          metricLabel: '$count completed lends',
          rating: u.ratingAverage,
          icon: Icons.volunteer_activism_rounded,
          iconColor: const Color(0xFF0F766E),
        );
      },
    );
  }

  Widget _buildBorrowersList(
    List<UserModel> users,
    List<TransactionModel> txns,
  ) {
    final Map<String, int> borrowCounts = {};
    for (final t in txns) {
      borrowCounts[t.borrowerId] = (borrowCounts[t.borrowerId] ?? 0) + 1;
    }

    final sorted = List<UserModel>.from(users)
      ..sort((a, b) {
        final aCount = borrowCounts[a.uid] ?? a.borrowedCount;
        final bCount = borrowCounts[b.uid] ?? b.borrowedCount;
        return bCount.compareTo(aCount);
      });

    if (sorted.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No Borrowers Found',
        description:
            'No completed borrowing transactions for the selected filter.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final u = sorted[i];
        final count = borrowCounts[u.uid] ?? u.borrowedCount;
        return _buildLeaderboardTile(
          rank: i + 1,
          name: u.fullName,
          department: u.department,
          metricLabel: '$count completed borrows',
          rating: u.ratingAverage,
          icon: Icons.shopping_bag_rounded,
          iconColor: const Color(0xFF2563EB),
        );
      },
    );
  }

  Widget _buildRatedList(List<UserModel> users) {
    final sorted = List<UserModel>.from(users)
      ..sort((a, b) {
        final cmp = b.ratingAverage.compareTo(a.ratingAverage);
        return cmp != 0 ? cmp : b.ratingsCount.compareTo(a.ratingsCount);
      });

    if (sorted.isEmpty) {
      return const EmptyState(
        icon: Icons.star_border_rounded,
        title: 'No Ratings Recorded',
        description: 'No verified reviews submitted yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final u = sorted[i];
        return _buildLeaderboardTile(
          rank: i + 1,
          name: u.fullName,
          department: u.department,
          metricLabel: '${u.ratingsCount} reviews',
          rating: u.ratingAverage,
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFEAB308),
        );
      },
    );
  }

  Widget _buildLeaderboardTile({
    required int rank,
    required String name,
    required String department,
    required String metricLabel,
    required double rating,
    required IconData icon,
    required Color iconColor,
  }) {
    Color badgeColor;
    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32); // Bronze
    } else {
      badgeColor = Colors.grey.shade200;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: badgeColor,
          foregroundColor: rank <= 3 ? Colors.black87 : Colors.black54,
          radius: 18,
          child: Text(
            '#$rank',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: Color(0xFFEAB308),
                ),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Text(
          department,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: iconColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                metricLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
