import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';

class AdminVerificationsScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdminVerificationsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AdminVerificationsScreen> createState() =>
      _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends State<AdminVerificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && args >= 0 && args < 4) {
      if (_tabController.index != args) {
        _tabController.index = args;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showImageModal(BuildContext context, UserModel student) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                elevation: 0,
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'College ID Card Inspector',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${student.fullName} • ${AppHelpers.maskRegisterNumber(student.registerNumber)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF1F5F9),
                  alignment: Alignment.center,
                  child: _buildIdCardContent(student),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.zoom_in_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Pinch to zoom / double tap to inspect',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdCardContent(UserModel student) {
    final url = student.idCardImageUrl.trim();

    // 1. Base64 Data URI
    if (url.startsWith('data:image')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Data = commaIndex != -1
            ? url.substring(commaIndex + 1)
            : url;
        final bytes = base64Decode(base64Data);
        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.5,
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _buildFallbackDigitalId(student),
          ),
        );
      } catch (_) {
        return _buildFallbackDigitalId(student);
      }
    }

    // 2. HTTP / HTTPS Network URL or Web Blob
    if (url.startsWith('http://') ||
        url.startsWith('https://') ||
        (kIsWeb && url.startsWith('blob:'))) {
      return InteractiveViewer(
        minScale: 1.0,
        maxScale: 3.5,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (_, _, _) => _buildFallbackDigitalId(student),
        ),
      );
    }

    // 3. Local File Path (non-web)
    if (!kIsWeb && url.isNotEmpty) {
      final file = File(url);
      if (file.existsSync()) {
        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.5,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _buildFallbackDigitalId(student),
          ),
        );
      }
    }

    // 4. Default Fallback Digital ID
    return _buildFallbackDigitalId(student);
  }

  Widget _buildFallbackDigitalId(UserModel student) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF1E3A8A),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.collegeId.isNotEmpty
                          ? student.collegeId.toUpperCase()
                          : 'CAMPUS STUDENT ID',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const Text(
                      'STUDENT IDENTITY VERIFICATION CREDENTIAL',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(
                  0xFF2563EB,
                ).withValues(alpha: 0.15),
                child: Text(
                  student.fullName.isNotEmpty
                      ? student.fullName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _idBadgeRow('Register No', student.registerNumber),
                    _idBadgeRow('Department', student.department),
                    _idBadgeRow(
                      'Year',
                      student.semester.isNotEmpty
                          ? '${student.academicYear} • ${student.semester}'
                          : student.academicYear,
                    ),
                    _idBadgeRow('Email', student.email),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: student.isVerified
                  ? Colors.green.shade50
                  : student.isRejected
                  ? Colors.red.shade50
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: student.isVerified
                    ? Colors.green.shade400
                    : student.isRejected
                    ? Colors.red.shade400
                    : const Color(0xFFF59E0B),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  student.isVerified
                      ? Icons.verified_rounded
                      : student.isRejected
                      ? Icons.cancel_rounded
                      : Icons.pending_actions_rounded,
                  size: 16,
                  color: student.isVerified
                      ? Colors.green.shade700
                      : student.isRejected
                      ? Colors.red.shade700
                      : const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Text(
                  student.isVerified
                      ? 'Verified Student Identity'
                      : student.isRejected
                      ? 'Verification Declined'
                      : 'Awaiting College ID Verification Approval',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: student.isVerified
                        ? Colors.green.shade800
                        : student.isRejected
                        ? Colors.red.shade800
                        : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _idBadgeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    UserModel student,
    String adminUid,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.gpp_bad_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Expanded(child: Text('Decline Verification')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A mandatory reason is required to decline ${student.fullName}\'s student verification. This reason will be recorded and notified to the student.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                hintText:
                    'e.g. ID card photo is blurry, name mismatch, expired ID card',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                AppHelpers.showSnackBar(
                  context,
                  'Please enter a reason for declining verification.',
                  isError: true,
                );
                return;
              }

              Navigator.pop(ctx);

              final adminProvider = Provider.of<AdminProvider>(
                context,
                listen: false,
              );
              final success = await adminProvider.rejectStudent(
                student.uid,
                reason,
                adminUid,
              );
              if (context.mounted) {
                if (success) {
                  AppHelpers.showSnackBar(
                    context,
                    'Verification declined. Student has been notified.',
                    isSuccess: true,
                  );
                } else {
                  AppHelpers.showSnackBar(
                    context,
                    adminProvider.errorMessage ?? 'Operation failed.',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Confirm Decline'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final adminUid = auth.currentUser?.uid ?? '';

    // STRICT: Only authenticated administrators can access verifications console
    if (auth.currentUser == null || !auth.currentUser!.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.gpp_bad_rounded,
                    size: 64,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Administrator Authorization Required',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Only verified college administrators are authorized to inspect student credentials and approve or reject verification requests.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Return Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allStudents = adminProvider.allUsers
        .where((u) => !u.isAdmin)
        .toList();
    final pendingStudents = allStudents
        .where((u) => u.verificationStatus == 'pending')
        .toList();
    final approvedStudents = allStudents.where((u) => u.isVerified).toList();
    final rejectedStudents = allStudents
        .where((u) => u.verificationStatus == 'rejected')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student ID Verifications'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: pendingStudents.isNotEmpty,
                label: Text('${pendingStudents.length}'),
                child: const Icon(Icons.hourglass_top_rounded, size: 18),
              ),
              text: 'Pending (${pendingStudents.length})',
            ),
            Tab(
              icon: const Icon(Icons.verified_rounded, size: 18),
              text: 'Approved (${approvedStudents.length})',
            ),
            Tab(
              icon: const Icon(Icons.cancel_rounded, size: 18),
              text: 'Rejected (${rejectedStudents.length})',
            ),
            Tab(
              icon: const Icon(Icons.people_alt_outlined, size: 18),
              text: 'All Students (${allStudents.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by student name, email, roll no...',
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

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentList(
                  pendingStudents,
                  adminUid,
                  'No Pending Verifications',
                  'No students are currently waiting for ID card approval.',
                ),
                _buildStudentList(
                  approvedStudents,
                  adminUid,
                  'No Approved Students',
                  'No students have been approved yet.',
                ),
                _buildStudentList(
                  rejectedStudents,
                  adminUid,
                  'No Rejected Verifications',
                  'No student verifications have been declined.',
                ),
                _buildStudentList(
                  allStudents,
                  adminUid,
                  'No Registered Students',
                  'No student profiles found.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(
    List<UserModel> list,
    String adminUid,
    String emptyTitle,
    String emptyDesc,
  ) {
    var filtered = list;
    if (_searchQuery.isNotEmpty) {
      filtered = list.where((s) {
        return s.fullName.toLowerCase().contains(_searchQuery) ||
            s.email.toLowerCase().contains(_searchQuery) ||
            s.registerNumber.toLowerCase().contains(_searchQuery) ||
            s.department.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.badge_outlined,
        title: emptyTitle,
        description: emptyDesc,
      );
    }

    final adminProvider = Provider.of<AdminProvider>(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final student = filtered[index];
        final isVerified = student.isVerified;
        final isRejected = student.isRejected;

        Color statusColor = const Color(0xFFF59E0B);
        if (isVerified) statusColor = const Color(0xFF10B981);
        if (isRejected) statusColor = const Color(0xFFEF4444);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                      child: Text(
                        student.fullName.isNotEmpty
                            ? student.fullName[0].toUpperCase()
                            : 'S',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  student.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
                                    color: statusColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  student.verificationStatus.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Academic metadata
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Department: ${student.department}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      student.semester.isNotEmpty
                          ? 'Year: ${student.academicYear} • ${student.semester}'
                          : 'Year: ${student.academicYear}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Register No: ${AppHelpers.maskRegisterNumber(student.registerNumber)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Registered: ${AppHelpers.formatDate(student.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (student.collegeId.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'College ID: ${AppHelpers.maskRegisterNumber(student.collegeId)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],

                // Rejection reason if applicable
                if (student.rejectionReason != null &&
                    student.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Decline Reason: ${student.rejectionReason}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // View ID card button
                OutlinedButton.icon(
                  onPressed: () => _showImageModal(context, student),
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  label: const Text('Inspect Uploaded College ID Card'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    backgroundColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    if (!isRejected)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _showRejectDialog(context, student, adminUid),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            minimumSize: const Size.fromHeight(42),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                    if (!isRejected && !isVerified) const SizedBox(width: 12),
                    if (!isVerified)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = await adminProvider.approveStudent(
                              student.uid,
                              adminUid,
                            );
                            if (context.mounted) {
                              if (success) {
                                AppHelpers.showSnackBar(
                                  context,
                                  '${student.fullName} has been approved as verified student!',
                                  isSuccess: true,
                                );
                              } else {
                                AppHelpers.showSnackBar(
                                  context,
                                  adminProvider.errorMessage ??
                                      'Failed to approve',
                                  isError: true,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(42),
                          ),
                          child: const Text('Approve Student'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
