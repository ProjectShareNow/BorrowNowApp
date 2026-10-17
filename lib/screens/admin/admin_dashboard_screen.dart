import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../app/routes.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<AdminProvider>(context, listen: false).initAdminStreams();
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out from BorrowNow Admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Authorization safeguard: only admin allowed
    if (auth.currentUser == null || !auth.currentUser!.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Administrative authorization required to access this console.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BorrowNow Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. Users & Verification
            _buildSectionHeader(
              'Users & Verification',
              Icons.people_outline_rounded,
            ),
            _buildCardGroup([
              _buildManagementTile(
                title: 'Student Verification',
                subtitle: 'Review student IDs, approve or reject with reason',
                icon: Icons.badge_outlined,
                iconColor: const Color(0xFFD97706),
                iconBgColor: const Color(0xFFFEF3C7),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminVerifications),
              ),
              const Divider(height: 1),
              _buildManagementTile(
                title: 'User Management',
                subtitle:
                    'Search students, history, activate or deactivate accounts',
                icon: Icons.manage_accounts_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFEFF6FF),
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminUsers),
              ),
            ]),
            const SizedBox(height: 18),

            // B. Items & Borrowing
            _buildSectionHeader(
              'Items & Borrowing',
              Icons.inventory_2_outlined,
            ),
            _buildCardGroup([
              _buildManagementTile(
                title: 'Item Management',
                subtitle:
                    'Review photos, details, deactivate inappropriate listings',
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF0D9488),
                iconBgColor: const Color(0xFFCCFBF1),
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminItems),
              ),
              const Divider(height: 1),
              _buildManagementTile(
                title: 'Borrow Requests',
                subtitle:
                    'Monitor pending, accepted, rejected, and cancelled requests',
                icon: Icons.pending_actions_outlined,
                iconColor: const Color(0xFFEA580C),
                iconBgColor: const Color(0xFFFFEDD5),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminBorrowRequests),
              ),
            ]),
            const SizedBox(height: 18),

            // C. Transactions
            _buildSectionHeader('Transactions', Icons.sync_alt_rounded),
            _buildCardGroup([
              _buildManagementTile(
                title: 'Transactions & Returns',
                subtitle:
                    'Active transactions, returned items, and overdue tracking',
                icon: Icons.handshake_outlined,
                iconColor: const Color(0xFF0284C7),
                iconBgColor: const Color(0xFFE0F2FE),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminTransactions),
              ),
            ]),
            const SizedBox(height: 18),

            // D. Safety & Support
            _buildSectionHeader('Safety & Support', Icons.security_rounded),
            _buildCardGroup([
              _buildManagementTile(
                title: 'Reports & Complaints',
                subtitle:
                    'Review evidence, update status, and add resolution notes',
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFFDC2626),
                iconBgColor: const Color(0xFFFEE2E2),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminReports),
              ),
            ]),
            const SizedBox(height: 18),

            // E. Community
            _buildSectionHeader('Community', Icons.groups_outlined),
            _buildCardGroup([
              _buildManagementTile(
                title: 'Leaderboard',
                subtitle: 'Rankings calculated from transactions and ratings',
                icon: Icons.leaderboard_outlined,
                iconColor: const Color(0xFFCA8A04),
                iconBgColor: const Color(0xFFFEF9C3),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminLeaderboard),
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Category section header with icon and uppercase title
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact card container for grouped management tiles
  Widget _buildCardGroup(List<Widget> children) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  /// Compact management navigation tile
  Widget _buildManagementTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: Color(0xFF94A3B8),
      ),
      onTap: onTap,
    );
  }
}
