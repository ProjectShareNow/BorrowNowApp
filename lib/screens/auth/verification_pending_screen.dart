import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../app/routes.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Pending'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (r) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pending_actions_rounded,
                    size: 72,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'College ID Under Review',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thank you for registering, ${user?.fullName ?? "Student"}! Your college ID card is currently awaiting approval by the college administration team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('College ID', AppHelpers.maskRegisterNumber(user?.collegeId)),
                    const SizedBox(height: 8),
                    _buildInfoRow('Academic Year', user?.academicYear ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Department', user?.department ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Register No',
                      AppHelpers.maskRegisterNumber(user?.registerNumber),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Status',
                      'Pending Administrative Review',
                      isStatus: true,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Refresh status from Firestore
              CustomButton(
                text: 'Check Verification Status',
                onPressed: () async {
                  AppHelpers.showSnackBar(
                    context,
                    'Checking verification status from campus administration...',
                  );
                  final refreshed = await authProvider.refreshCurrentUser();
                  if (!context.mounted) return;
                  if (refreshed != null && refreshed.isVerified) {
                    AppHelpers.showSnackBar(
                      context,
                      'Account verified by Admin! Welcome to campus.',
                      isSuccess: true,
                    );
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  } else if (refreshed != null && refreshed.isRejected) {
                    AppHelpers.showSnackBar(
                      context,
                      'Your verification was declined by the administrator.',
                      isError: true,
                    );
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.accountRejected,
                    );
                  } else {
                    AppHelpers.showSnackBar(
                      context,
                      'Your verification is still pending review by the campus administrator.',
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              // Administrative Verification Assurance Notice
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'College Admin Verification: Only designated college administrators can inspect and approve or decline student ID cards.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Sign Out',
                isOutlined: true,
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (r) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isStatus ? Colors.amber.shade800 : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
