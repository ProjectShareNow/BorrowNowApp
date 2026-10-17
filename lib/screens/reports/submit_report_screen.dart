import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_registry.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SubmitReportScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const SubmitReportScreen({super.key, this.initialData});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedReason = AppConstants.reportReasons.first;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      AppHelpers.showSnackBar(
        context,
        'Please log in to submit a report.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final report = ReportModel(
        id: '',
        reporterId: user.uid,
        reporterName: user.fullName,
        reportedUserId: widget.initialData?['reportedUserId'] ?? 'unspecified',
        reportedUserName:
            widget.initialData?['reportedUserName'] ?? 'Campus User',
        itemId: widget.initialData?['itemId'],
        transactionId: widget.initialData?['transactionId'],
        reason: _selectedReason,
        description: _descriptionController.text.trim(),
        status: 'pending',
      );

      await ServiceRegistry.reportService.submitReport(report);

      setState(() => _isSubmitting = false);

      if (!mounted) return;

      AppHelpers.showSnackBar(
        context,
        'Report submitted to campus administration. We will review it promptly.',
        isSuccess: true,
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Failed to submit report: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportedUserName = widget.initialData?['reportedUserName'];

    return Scaffold(
      appBar: AppBar(title: const Text('File a Report / Dispute')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Reports are reviewed directly by college administration to maintain safety and trust on campus.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (reportedUserName != null) ...[
                  Text(
                    'Subject: Report regarding $reportedUserName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Reason dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Report *',
                    prefixIcon: Icon(Icons.report_problem_outlined, size: 20),
                  ),
                  items: AppConstants.reportReasons
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
                const SizedBox(height: 20),

                // Description
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Detailed Explanation *',
                  hintText:
                      'Please detail what happened, item condition, missing accessories, or time delays...',
                  maxLines: 5,
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Please provide at least 10 characters explaining the issue.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit button
                CustomButton(
                  text: 'Submit Report to Admin',
                  backgroundColor: const Color(0xFFDC2626),
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
