import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../services/service_registry.dart';
import '../../app/routes.dart';
import '../../utils/helpers.dart';

class ChatWorkflowPanel extends StatefulWidget {
  final ChatModel chat;
  final TransactionModel? transaction;
  final UserModel currentUser;
  final VoidCallback onRefresh;

  const ChatWorkflowPanel({
    super.key,
    required this.chat,
    required this.transaction,
    required this.currentUser,
    required this.onRefresh,
  });

  @override
  State<ChatWorkflowPanel> createState() => _ChatWorkflowPanelState();
}

class _ChatWorkflowPanelState extends State<ChatWorkflowPanel> {
  bool _isExpanded = true;
  final _damageDetailsController = TextEditingController();

  bool _isConfirmingHandover = false;
  bool _isConfirmingReturn = false;

  String _returnCondition = 'good';
  bool _damageReported = false;

  @override
  void dispose() {
    _damageDetailsController.dispose();
    super.dispose();
  }

  bool get _isLender =>
      widget.currentUser.uid == widget.chat.lenderId ||
      widget.currentUser.uid == widget.chat.ownerId ||
      (widget.transaction != null &&
          widget.currentUser.uid == widget.transaction!.ownerId);

  bool get _isBorrower =>
      widget.currentUser.uid == widget.chat.borrowerId ||
      (widget.transaction != null &&
          widget.currentUser.uid == widget.transaction!.borrowerId);

  Future<void> _handleConfirmItemHandover(TransactionModel txn) async {
    setState(() {
      _isConfirmingHandover = true;
    });

    try {
      await ServiceRegistry.transactionService.confirmItemHandover(
        transactionId: txn.id,
        lenderId: widget.currentUser.uid,
      );
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'Item handover confirmed! Active borrowing started.');
      widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConfirmingHandover = false;
        });
      }
    }
  }

  void _showReturnConfirmationDialog(TransactionModel txn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assignment_return_rounded, color: Color(0xFF0F766E)),
            SizedBox(width: 8),
            Text('Initiate Item Return'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you ready to return this item to the owner?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'The return workflow requires:\n'
              '• A fresh live camera photo of the item condition\n'
              '• Both participants confirming item condition and receipt',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ServiceRegistry.transactionService.requestReturn(
                  transactionId: txn.id,
                  currentUserId: widget.currentUser.uid,
                );
                if (mounted) {
                  AppHelpers.showSnackBar(context, 'Return requested! Return verification is now active.');
                  widget.onRefresh();
                }
              } catch (e) {
                if (mounted) {
                  AppHelpers.showSnackBar(
                    context,
                    e.toString().replaceAll('Exception: ', ''),
                    isError: true,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Start Return'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirmReturnReceipt(TransactionModel txn) async {
    setState(() {
      _isConfirmingReturn = true;
    });

    try {
      await ServiceRegistry.transactionService.confirmReturnAndComplete(
        transactionId: txn.id,
        currentUserId: widget.currentUser.uid,
        returnCondition: _returnCondition,
        damageReported: _damageReported,
        damageDetails: _damageReported ? _damageDetailsController.text.trim() : null,
      );
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'Return confirmed! Transaction successfully completed.');
      widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConfirmingReturn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final txn = widget.transaction;
    if (txn == null) {
      return const SizedBox.shrink();
    }

    final isScheduled = txn.isScheduled;
    final isActive = txn.isActive;
    final isReturnRequested = txn.isReturnRequested;
    final isCompleted = txn.isCompleted;

    String stageTitle = 'Handover photo required';
    Color stageColor = const Color(0xFF0F766E);
    Color stageBg = const Color(0xFFF0FDF4);
    IconData stageIcon = Icons.swap_horiz_rounded;

    if (isScheduled) {
      if (txn.handoverPhotoUrl.isEmpty) {
        stageTitle = 'Handover photo required';
      } else if (!txn.handoverConfirmed) {
        stageTitle = 'Waiting for handover confirmation';
      } else {
        stageTitle = 'Handover confirmed';
      }
      stageColor = const Color(0xFF0F766E);
      stageBg = const Color(0xFFF0FDF4);
      stageIcon = Icons.swap_horiz_rounded;
    } else if (isActive) {
      stageTitle = 'Item borrowed';
      stageColor = const Color(0xFF2563EB);
      stageBg = const Color(0xFFEFF6FF);
      stageIcon = Icons.inventory_2_outlined;
    } else if (isReturnRequested) {
      if (txn.returnPhotoUrl.isEmpty) {
        stageTitle = 'Return photo required';
      } else if (!txn.lenderReturnConfirmed) {
        stageTitle = 'Waiting for lender confirmation';
      } else {
        stageTitle = 'Return requested';
      }
      stageColor = const Color(0xFFD97706);
      stageBg = const Color(0xFFFFFBEB);
      stageIcon = Icons.assignment_return_outlined;
    } else if (isCompleted) {
      stageTitle = 'Transaction completed';
      stageColor = const Color(0xFF059669);
      stageBg = const Color(0xFFECFDF5);
      stageIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar with Toggle
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: stageBg,
              child: Row(
                children: [
                  Icon(stageIcon, size: 16, color: stageColor),
                  const SizedBox(width: 8),
                  Text(
                    stageTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: stageColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: stageColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.chat.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: stageColor,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Content
          if (_isExpanded)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 170),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isScheduled) _buildHandoverSection(txn),
                    if (isActive) _buildActiveBorrowingSection(txn),
                    if (isReturnRequested) _buildReturnSection(txn),
                    if (isCompleted) _buildCompletedSection(txn),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. Handover Workflow Section (isScheduled)
  // -------------------------------------------------------------
  Widget _buildHandoverSection(TransactionModel txn) {
    final theme = Theme.of(context);
    final hasPhoto = txn.handoverPhotoUrl.isNotEmpty;
    final canConfirmHandover = _isLender && hasPhoto && !txn.handoverConfirmed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Confirm Item Handover Button (Lender only)
        if (_isLender) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canConfirmHandover && !_isConfirmingHandover
                  ? () => _handleConfirmItemHandover(txn)
                  : null,
              icon: _isConfirmingHandover
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 16),
              label: Text(_isConfirmingHandover ? 'Confirming...' : 'Confirm Handover'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (!canConfirmHandover)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Text(
                  !hasPhoto ? 'Capture live handover photo below' : '',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // 2. Active Borrowing Section (isActive)
  // -------------------------------------------------------------
  Widget _buildActiveBorrowingSection(TransactionModel txn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Item Handed Over & Active',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                  if (txn.pickupTime != null)
                    Text(
                      AppHelpers.formatTime(txn.pickupTime!),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _isBorrower
                    ? 'You have safely received "${txn.itemName}". Please take care of the item and initiate return when finished.'
                    : '"${txn.itemName}" is currently with ${txn.borrowerName}. You will be notified when they request return.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ],
          ),
        ),

        // Prominent Return Item Button for Borrower
        if (_isBorrower) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showReturnConfirmationDialog(txn),
              icon: const Icon(Icons.assignment_return_rounded, size: 16),
              label: const Text('Return Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // 3. Return Workflow Section (isReturnRequested)
  // -------------------------------------------------------------
  Widget _buildReturnSection(TransactionModel txn) {
    final hasReturnPhoto = txn.returnPhotoUrl.isNotEmpty;
    final canCompleteReturn = _isLender && hasReturnPhoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [        // Condition Confirmation & Damage Reporting (Lender inspection)
        if (_isLender) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Item Condition at Return',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'good', label: Text('Good 👍')),
                    ButtonSegment(value: 'fair', label: Text('Fair 😐')),
                    ButtonSegment(value: 'damaged', label: Text('Damaged ⚠️')),
                  ],
                  selected: {_returnCondition},
                  onSelectionChanged: (val) {
                    setState(() {
                      _returnCondition = val.first;
                      if (_returnCondition == 'damaged') {
                        _damageReported = true;
                      }
                    });
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Checkbox(
                      value: _damageReported,
                      onChanged: (val) {
                        setState(() {
                          _damageReported = val ?? false;
                        });
                      },
                    ),
                    const Text('Report item damage or missing parts', style: TextStyle(fontSize: 12)),
                  ],
                ),
                if (_damageReported) ...[
                  TextField(
                    controller: _damageDetailsController,
                    decoration: InputDecoration(
                      hintText: 'Describe damage or missing parts...',
                      hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canCompleteReturn && !_isConfirmingReturn
                  ? () => _handleConfirmReturnReceipt(txn)
                  : null,
              icon: _isConfirmingReturn
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.task_alt_rounded, size: 16),
              label: Text(_isConfirmingReturn ? 'Completing...' : 'Confirm Return & Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (!canCompleteReturn)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Text(
                  !hasReturnPhoto ? 'Capture fresh return photo below' : '',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ),
        ] else ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasReturnPhoto
                        ? 'Return photo uploaded! Waiting for ${txn.ownerName} to confirm receipt.'
                        : 'Capture the return photo so lender can inspect and finalize return.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          if (_isBorrower && hasReturnPhoto) ...[
            const SizedBox(height: 10),
            if (!txn.borrowerReturnConfirmed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await ServiceRegistry.transactionService.confirmBorrowerReturnHandback(
                        transactionId: txn.id,
                        borrowerId: widget.currentUser.uid,
                      );
                      if (mounted) {
                        AppHelpers.showSnackBar(context, 'You confirmed item hand-back.');
                        widget.onRefresh();
                      }
                    } catch (e) {
                      if (mounted) {
                        AppHelpers.showSnackBar(context, e.toString().replaceAll('Exception: ', ''), isError: true);
                      }
                    }
                  },
                  icon: const Icon(Icons.handshake_outlined, size: 16),
                  label: const Text('Confirm Item Handed Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'You confirmed item hand-back. Waiting for lender to inspect and complete.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // 4. Completed Section (isCompleted)
  // -------------------------------------------------------------
  Widget _buildCompletedSection(TransactionModel txn) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Transaction Successfully Completed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Item returned and inspected. Condition: ${txn.returnCondition.toUpperCase()}${txn.damageReported ? " (Damage reported)" : ""}.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF047857)),
          ),
          if (txn.damageReported && txn.damageDetails != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Damage notes: ${txn.damageDetails}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (txn.handoverPhotoUrl.isNotEmpty) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Handover Photo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          txn.handoverPhotoUrl,
                          height: 60,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (txn.returnPhotoUrl.isNotEmpty) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Return Photo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          txn.returnPhotoUrl,
                          height: 60,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Feedback / Rating Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.feedback,
                  arguments: txn,
                );
              },
              icon: Icon(
                txn.hasUserRated(widget.currentUser.uid)
                    ? Icons.check_circle_outline_rounded
                    : Icons.star_rate_rounded,
                size: 16,
              ),
              label: Text(
                txn.hasUserRated(widget.currentUser.uid)
                    ? 'Feedback Submitted ✓'
                    : 'Rate & Leave Feedback',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: txn.hasUserRated(widget.currentUser.uid)
                    ? const Color(0xFF0F766E)
                    : Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              txn.hasOtherPartyRated(widget.currentUser.uid)
                  ? 'Other participant has submitted feedback.'
                  : 'Other participant feedback is pending.',
              style: TextStyle(
                fontSize: 11,
                color: txn.hasOtherPartyRated(widget.currentUser.uid)
                    ? const Color(0xFF065F46)
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
