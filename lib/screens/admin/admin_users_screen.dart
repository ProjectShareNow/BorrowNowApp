import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String _filter =
      'All'; // 'All', 'Active', 'Deactivated', 'Verified', 'Pending', 'Rejected'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeactivateDialog(BuildContext context, UserModel user) {
    final reasonController = TextEditingController();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminUid = auth.currentUser?.uid ?? 'admin';
    final adminName = auth.currentUser?.fullName ?? 'Campus Administrator';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_off_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Expanded(child: Text('Deactivate Student Account')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temporarily deactivate ${user.fullName}\'s account? They will be locked out of borrowing and lending features.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for Deactivation *',
                hintText:
                    'e.g. Unresolved dispute, repeated misconduct, suspended by dean',
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
                  'Please specify a reason for deactivation.',
                  isError: true,
                );
                return;
              }

              Navigator.pop(ctx);
              final adminProvider = Provider.of<AdminProvider>(
                context,
                listen: false,
              );
              final success = await adminProvider.deactivateStudent(
                uid: user.uid,
                reason: reason,
                adminUid: adminUid,
                adminName: adminName,
              );
              if (context.mounted) {
                if (success) {
                  AppHelpers.showSnackBar(
                    context,
                    'Account deactivated and student notified.',
                    isSuccess: true,
                  );
                } else {
                  AppHelpers.showSnackBar(
                    context,
                    adminProvider.errorMessage ?? 'Deactivation failed.',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Deactivate Account'),
          ),
        ],
      ),
    );
  }

  void _showReactivateDialog(BuildContext context, UserModel user) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminUid = auth.currentUser?.uid ?? 'admin';
    final adminName = auth.currentUser?.fullName ?? 'Campus Administrator';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reactivate Student Account?'),
        content: Text(
          'Allow ${user.fullName} to access BorrowNow campus borrowing and lending features again?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final adminProvider = Provider.of<AdminProvider>(
                context,
                listen: false,
              );
              final success = await adminProvider.reactivateStudent(
                uid: user.uid,
                adminUid: adminUid,
                adminName: adminName,
              );
              if (context.mounted) {
                if (success) {
                  AppHelpers.showSnackBar(
                    context,
                    'Account reactivated successfully.',
                    isSuccess: true,
                  );
                } else {
                  AppHelpers.showSnackBar(
                    context,
                    adminProvider.errorMessage ?? 'Reactivation failed.',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );
  }

  void _showUserDetailsModal(BuildContext context, UserModel user) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final userItems = adminProvider.allItems
        .where((i) => i.ownerId == user.uid)
        .toList();
    final borrowingHistory = adminProvider.allTransactions
        .where((t) => t.borrowerId == user.uid)
        .toList();
    final lendingHistory = adminProvider.allTransactions
        .where((t) => t.ownerId == user.uid)
        .toList();
    final relatedReports = adminProvider.allReports
        .where((r) => r.reportedUserId == user.uid || r.reporterId == user.uid)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0] : 'S',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: user.isVerified
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.verificationStatus.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: user.isVerified
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: user.isActive
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.isActive ? 'ACTIVE' : 'DEACTIVATED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: user.isActive
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Academic & Verification Details
              const Text(
                'Student Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              if (user.collegeId.isNotEmpty)
                _buildDetailRow('College ID', AppHelpers.maskRegisterNumber(user.collegeId)),
              _buildDetailRow('Department', user.department),
              if (user.academicYear.isNotEmpty)
                _buildDetailRow('Academic Year', user.academicYear),
              if (user.semester.isNotEmpty)
                _buildDetailRow('Semester', user.semester),
              _buildDetailRow('Register Number', AppHelpers.maskRegisterNumber(user.registerNumber)),
              if (user.rejectionReason != null && user.rejectionReason!.isNotEmpty)
                _buildDetailRow('Rejection Reason', user.rejectionReason!),
              _buildDetailRow(
                'Joined Date',
                AppHelpers.formatDate(user.createdAt),
              ),
              _buildDetailRow(
                'Average Rating',
                AppHelpers.formatRatingDisplay(user.ratingAverage, user.ratingsCount),
              ),

              const SizedBox(height: 20),

              // History statistics cards
              Row(
                children: [
                  _buildStatTile(
                    'Listed Items',
                    '${userItems.length}',
                    Icons.inventory_2_outlined,
                    Colors.teal,
                  ),
                  const SizedBox(width: 8),
                  _buildStatTile(
                    'Borrowed',
                    '${borrowingHistory.length}',
                    Icons.shopping_bag_outlined,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildStatTile(
                    'Lent',
                    '${lendingHistory.length}',
                    Icons.volunteer_activism_outlined,
                    Colors.indigo,
                  ),
                  const SizedBox(width: 8),
                  _buildStatTile(
                    'Reports',
                    '${relatedReports.length}',
                    Icons.shield_outlined,
                    Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Listed Items List Preview
              Text(
                'Listed Items (${userItems.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              if (userItems.isEmpty)
                const Text(
                  'No items listed by this student.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )
              else
                ...userItems
                    .take(5)
                    .map(
                      (i) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.teal,
                        ),
                        title: Text(
                          i.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${i.category} • ${i.availability}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),

              const SizedBox(height: 20),

              // Reports Section Preview
              if (relatedReports.isNotEmpty) ...[
                Text(
                  'Associated Reports (${relatedReports.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...relatedReports.map(
                  (r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reason: ${r.reason} [${r.status.toUpperCase()}]',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.description,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isActive
                        ? Colors.red.shade600
                        : Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(
                    user.isActive
                        ? Icons.person_off_rounded
                        : Icons.person_rounded,
                  ),
                  label: Text(
                    user.isActive
                        ? 'Deactivate Student Account'
                        : 'Reactivate Student Account',
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (user.isActive) {
                      _showDeactivateDialog(context, user);
                    } else {
                      _showReactivateDialog(context, user);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.currentUser == null || !auth.currentUser!.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Administrative authorization required to access this screen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    final adminProvider = Provider.of<AdminProvider>(context);
    final users = adminProvider.allUsers.where((u) {
      if (u.isAdmin) return false; // Show student accounts

      // Apply filter chip
      if (_filter == 'Active' && !u.isActive) return false;
      if (_filter == 'Deactivated' && u.isActive) return false;
      if (_filter == 'Verified' && !u.isVerified) return false;
      if (_filter == 'Pending' && !u.isPending) return false;
      if (_filter == 'Rejected' && !u.isRejected) return false;

      // Apply search
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.registerNumber.toLowerCase().contains(q) ||
            u.department.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Registered Students')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, roll no, or department...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _search = val.trim()),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children:
                  [
                        'All',
                        'Active',
                        'Deactivated',
                        'Verified',
                        'Pending',
                        'Rejected',
                      ]
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              f,
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: _filter == f,
                            onSelected: (sel) {
                              if (sel) setState(() => _filter = f);
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          Expanded(
            child: users.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No Students Found',
                    description:
                        'No students match the search and filter query.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: users.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final u = users[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        onTap: () => _showUserDetailsModal(context, u),
                        leading: CircleAvatar(
                          backgroundColor: u.isActive
                              ? (u.isVerified
                                    ? Colors.green.shade100
                                    : Colors.blue.shade100)
                              : Colors.red.shade100,
                          child: Icon(
                            u.isActive
                                ? Icons.person
                                : Icons.person_off_rounded,
                            color: u.isActive
                                ? (u.isVerified
                                      ? Colors.green.shade800
                                      : const Color(0xFF1E40AF))
                                : Colors.red.shade800,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                u.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: u.isVerified
                                    ? Colors.green.shade50
                                    : (u.isRejected
                                          ? Colors.red.shade50
                                          : Colors.orange.shade50),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                u.verificationStatus.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: u.isVerified
                                      ? Colors.green.shade800
                                      : (u.isRejected
                                            ? Colors.red.shade800
                                            : Colors.orange.shade800),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${u.department} • ${AppHelpers.maskRegisterNumber(u.registerNumber)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  u.isActive
                                      ? '● Active Account'
                                      : '● Deactivated',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: u.isActive
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '• ${u.email}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            u.isActive
                                ? Icons.toggle_on_rounded
                                : Icons.toggle_off_rounded,
                            color: u.isActive ? Colors.green : Colors.grey,
                            size: 38,
                          ),
                          tooltip: u.isActive
                              ? 'Deactivate Account'
                              : 'Reactivate Account',
                          onPressed: () {
                            if (u.isActive) {
                              _showDeactivateDialog(context, u);
                            } else {
                              _showReactivateDialog(context, u);
                            }
                          },
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
