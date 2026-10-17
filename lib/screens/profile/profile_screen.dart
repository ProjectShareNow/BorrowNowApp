import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../app/routes.dart';
import '../../utils/helpers.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildVerificationBadge(BuildContext context, String? status) {
    final s = status?.toLowerCase() ?? 'pending';
    Color badgeBg;
    Color borderColor;
    Color textColor;
    IconData icon;
    String label;

    if (s == 'verified' || s == 'approved') {
      badgeBg = const Color(0xFFDCFCE7);
      borderColor = const Color(0xFF86EFAC);
      textColor = const Color(0xFF16A34A);
      icon = Icons.verified_user_rounded;
      label = 'Verified Student';
    } else if (s == 'rejected') {
      badgeBg = const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFFCA5A5);
      textColor = const Color(0xFFDC2626);
      icon = Icons.gpp_bad_rounded;
      label = 'Verification Rejected';
    } else {
      badgeBg = const Color(0xFFFEF3C7);
      borderColor = const Color(0xFFFCD34D);
      textColor = const Color(0xFFD97706);
      icon = Icons.pending_actions_rounded;
      label = 'Verification Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.editProfile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Card
            Center(
              child: Column(
                children: [
                  UserAvatar(
                    name: user?.fullName ?? 'Student',
                    radius: 46,
                    rating: user?.ratingAverage,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.fullName ?? 'Student User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // College ID Verification Status
                  _buildVerificationBadge(context, user?.verificationStatus),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Items Listed',
                      '${user?.itemsListedCount ?? 0}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Completed Loans',
                      '${user?.borrowedCount ?? 0}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Rating',
                      AppHelpers.formatRatingDisplay(
                        user?.ratingAverage,
                        user?.ratingsCount ?? 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Academic & Verification Details
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verification Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildProfileRow(
                    Icons.pin_outlined,
                    'Register Number',
                    AppHelpers.maskRegisterNumber(user?.registerNumber),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 20),
                  _buildProfileRow(
                    Icons.apartment_rounded,
                    'Department',
                    user?.department.isNotEmpty == true
                        ? user!.department
                        : 'N/A',
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 20),
                  _buildProfileRow(
                    Icons.school_outlined,
                    'Academic Year',
                    user?.academicYear.isNotEmpty == true
                        ? user!.academicYear
                        : 'N/A',
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 20),
                  _buildProfileRow(
                    Icons.calendar_month_outlined,
                    'Semester',
                    user?.semester.isNotEmpty == true
                        ? user!.semester
                        : 'N/A',
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 20),
                  _buildProfileRow(
                    Icons.star_outline_rounded,
                    'Peer Rating',
                    AppHelpers.formatRatingDisplay(
                      user?.ratingAverage,
                      user?.ratingsCount ?? 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Menu Shortcuts (Admin Console for administrators)
            if (user?.isAdmin == true) ...[
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
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
                  child: ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Color(0xFFDB2777),
                    ),
                    title: const Text(
                      'Admin Console',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDB2777),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.adminDashboard,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await AppHelpers.showConfirmDialog(
                  context: context,
                  title: 'Sign Out?',
                  message: 'Are you sure you want to sign out of BorrowNow?',
                  confirmLabel: 'Sign Out',
                  isDestructive: true,
                );
                if (confirm && context.mounted) {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (r) => false,
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                side: const BorderSide(
                  color: Color(0xFFDC2626),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}
