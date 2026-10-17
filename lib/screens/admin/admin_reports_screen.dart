import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedStatusFilter = 'All';

  void _showResolutionDialog(BuildContext context, ReportModel report) {
    String selectedStatus = report.status;
    final notesController = TextEditingController(
      text: report.adminNotes ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Update Dispute & Report Status'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report ID: ${report.id}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${report.category}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reporter: ${report.reporterName}  |  Against: ${report.reportedUserName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Investigation Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('PENDING'),
                      ),
                      DropdownMenuItem(
                        value: 'under_review',
                        child: Text('UNDER REVIEW'),
                      ),
                      DropdownMenuItem(
                        value: 'resolved',
                        child: Text('RESOLVED'),
                      ),
                      DropdownMenuItem(
                        value: 'dismissed',
                        child: Text('DISMISSED'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedStatus = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Resolution Notes & Notice to Students *',
                      hintText:
                          'e.g. Investigation complete. Item returned / Warning issued to reported user.',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final adminProvider = Provider.of<AdminProvider>(
                    context,
                    listen: false,
                  );
                  final success = await adminProvider.resolveReport(
                    report.id,
                    selectedStatus,
                    notesController.text.trim().isNotEmpty
                        ? notesController.text.trim()
                        : null,
                  );
                  if (context.mounted) {
                    if (success) {
                      AppHelpers.showSnackBar(
                        context,
                        'Report updated and notification sent to students.',
                        isSuccess: true,
                      );
                    } else {
                      AppHelpers.showSnackBar(
                        context,
                        adminProvider.errorMessage ?? 'Update failed.',
                        isError: true,
                      );
                    }
                  }
                },
                child: const Text('Save & Notify'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeactivateReportedUserDialog(
    BuildContext context,
    ReportModel report,
  ) {
    final reasonController = TextEditingController(
      text:
          'Deactivated following investigation of Report ${report.id} (${report.category}).',
    );
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminUid = auth.currentUser?.uid ?? 'admin';
    final adminName = auth.currentUser?.fullName ?? 'Campus Administrator';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Expanded(child: Text('Deactivate Reported Student')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to suspend ${report.reportedUserName}\'s account based on this report?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'A justified reason must be recorded and communicated to the student.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Justification Reason *',
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
                  'Please provide a justification reason.',
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
                uid: report.reportedUserId,
                reason: reason,
                adminUid: adminUid,
                adminName: adminName,
              );

              // Mark report as resolved
              await adminProvider.resolveReport(
                report.id,
                'resolved',
                'Reported account deactivated due to verified violation: $reason',
              );

              if (context.mounted) {
                if (success) {
                  AppHelpers.showSnackBar(
                    context,
                    '${report.reportedUserName}\'s account has been deactivated.',
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

  void _showEvidenceModal(BuildContext context, String evidenceUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Report Evidence Photo'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            InteractiveViewer(
              child: Image.network(
                evidenceUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Unable to load evidence image.'),
                ),
              ),
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
              'Administrative authorization required to access reports.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    final adminProvider = Provider.of<AdminProvider>(context);
    var reports = adminProvider.allReports;

    if (_selectedStatusFilter != 'All') {
      reports = reports
          .where(
            (r) =>
                r.status.toLowerCase() == _selectedStatusFilter.toLowerCase(),
          )
          .toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Review Disputes & Complaints')),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children:
                  ['All', 'pending', 'under_review', 'resolved', 'dismissed']
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              f == 'All'
                                  ? 'All Reports'
                                  : f.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: _selectedStatusFilter == f,
                            onSelected: (sel) {
                              if (sel) {
                                setState(() => _selectedStatusFilter = f);
                              }
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          Expanded(
            child: reports.isEmpty
                ? const EmptyState(
                    icon: Icons.shield_outlined,
                    title: 'No Reports Found',
                    description:
                        'No dispute, unreturned item, or student misconduct reports match the filter.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final r = reports[index];

                      Color statusColor = Colors.orange;
                      if (r.isUnderReview) statusColor = Colors.blue;
                      if (r.isResolved) statusColor = Colors.green;
                      if (r.isDismissed) statusColor = Colors.grey;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top status and category row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.category,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: statusColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      r.status
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
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
                                'Report ID: ${r.id}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const Divider(height: 16),

                              // Reporter & Reported Student
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Reporting Student:',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          r.reporterName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Reported Student:',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          r.reportedUserName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (r.itemId != null && r.itemId!.isNotEmpty) ...[
                                Text(
                                  'Related Item ID: ${r.itemId}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],

                              // Description
                              Text(
                                r.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Evidence image button if available
                              if (r.evidenceUrl != null &&
                                  r.evidenceUrl!.isNotEmpty) ...[
                                OutlinedButton.icon(
                                  onPressed: () => _showEvidenceModal(
                                    context,
                                    r.evidenceUrl!,
                                  ),
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Inspect Submitted Evidence',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                              Text(
                                'Submitted on ${AppHelpers.formatDateTime(r.createdAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),

                              if (r.adminNotes != null &&
                                  r.adminNotes!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Admin Resolution Notes: ${r.adminNotes}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _showResolutionDialog(context, r),
                                      icon: const Icon(
                                        Icons.rate_review_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('Update Status'),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!r.isDismissed && !r.isResolved)
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _showDeactivateReportedUserDialog(
                                            context,
                                            r,
                                          ),
                                      icon: const Icon(
                                        Icons.person_off_rounded,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        'Suspend User',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: Colors.red.shade300,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                ],
                              ),
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
