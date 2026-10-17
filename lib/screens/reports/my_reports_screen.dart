import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_registry.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final currentUserId = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports & Disputes')),
      body: StreamBuilder<List<ReportModel>>(
        stream: ServiceRegistry.reportService.getMyReportsStream(currentUserId),
        builder: (context, snapshot) {
          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No Reports Filed',
              description:
                  'You have not submitted any dispute or misconduct reports.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            r.reason,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          _buildStatusPill(r.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Reported: ${r.reportedUserName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        r.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppHelpers.formatDateTime(r.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      if (r.adminNotes != null && r.adminNotes!.isNotEmpty) ...[
                        const Divider(height: 20),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Admin Resolution Notes:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.adminNotes!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
        color = const Color(0xFF10B981);
        break;
      case 'under_review':
        color = const Color(0xFF3B82F6);
        break;
      case 'dismissed':
        color = Colors.grey;
        break;
      default:
        color = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
