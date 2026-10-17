import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/rating_model.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_registry.dart';
import '../../utils/helpers.dart';
import '../../widgets/user_avatar.dart';

class FeedbackScreen extends StatefulWidget {
  final TransactionModel? transaction;
  final String? transactionId;

  const FeedbackScreen({
    super.key,
    this.transaction,
    this.transactionId,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  TransactionModel? _transaction;
  UserModel? _otherUser;
  RatingModel? _existingReview;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  int _selectedRating = 5;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = auth.currentUser?.uid ?? '';

      TransactionModel? txn = widget.transaction;
      if (txn == null && widget.transactionId != null) {
        txn = await ServiceRegistry.transactionService.getTransaction(widget.transactionId!);
      }

      if (txn == null) {
        setState(() {
          _errorMessage = 'Transaction not found.';
          _isLoading = false;
        });
        return;
      }

      _transaction = txn;
      final isOwner = txn.ownerId == currentUserId;
      final otherUserId = isOwner ? txn.borrowerId : txn.ownerId;

      // Load other participant profile
      final otherUser = await ServiceRegistry.authService.getUserData(otherUserId);

      // Check if current user already submitted a review
      final review = await ServiceRegistry.ratingService.getReviewForTransaction(
        transactionId: txn.id,
        userId: currentUserId,
      );

      if (mounted) {
        setState(() {
          _transaction = txn;
          _otherUser = otherUser;
          _existingReview = review;
          if (review != null) {
            _selectedRating = review.rating.round().clamp(1, 5);
            _feedbackController.text = review.feedback.isNotEmpty ? review.feedback : review.review;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading feedback: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitFeedback() async {
    final txn = _transaction;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;

    if (txn == null || currentUser == null) return;

    if (_selectedRating < 1 || _selectedRating > 5) {
      AppHelpers.showSnackBar(
        context,
        'Please select a star rating between 1 and 5.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final isOwner = txn.ownerId == currentUser.uid;
      final reviewerRole = isOwner ? 'lender' : 'borrower';
      final revieweeId = isOwner ? txn.borrowerId : txn.ownerId;
      final revieweeName = isOwner ? txn.borrowerName : txn.ownerName;

      final ratingModel = RatingModel(
        transactionId: txn.id,
        requestId: txn.requestId,
        itemId: txn.itemId,
        reviewerId: currentUser.uid,
        reviewerName: currentUser.fullName,
        revieweeId: revieweeId,
        reviewerRole: reviewerRole,
        rating: _selectedRating.toDouble(),
        feedback: _feedbackController.text.trim(),
      );

      await ServiceRegistry.ratingService.submitRating(ratingModel);

      // Fetch the updated review and transaction state
      final updatedReview = await ServiceRegistry.ratingService.getReviewForTransaction(
        transactionId: txn.id,
        userId: currentUser.uid,
      );

      final updatedTxn = await ServiceRegistry.transactionService.getTransaction(txn.id);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _existingReview = updatedReview ?? ratingModel;
          if (updatedTxn != null) {
            _transaction = updatedTxn;
          }
        });

        AppHelpers.showSnackBar(
          context,
          'Feedback for $revieweeName submitted successfully! Thank you for rating.',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppHelpers.showSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Feedback'),
        elevation: 0,
      ),
      body: _buildBody(currentUserId),
    );
  }

  Widget _buildBody(String currentUserId) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _transaction == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Unable to load feedback.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final txn = _transaction!;
    final isCompleted = txn.isCompleted;
    final isOwner = txn.ownerId == currentUserId;
    final otherRole = isOwner ? 'Borrower' : 'Lender';
    final otherName = isOwner ? txn.borrowerName : txn.ownerName;
    final isAlreadyReviewed = _existingReview != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Completed Transaction / Item Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ITEM BORROWED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCompleted ? 'COMPLETED' : txn.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  txn.itemName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Transaction #${txn.id.substring(0, 8).toUpperCase()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Participant Reviewee Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                UserAvatar(
                  name: otherName,
                  radius: 26,
                  rating: _otherUser?.ratingAverage,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              otherName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOwner
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isOwner
                                    ? const Color(0xFFBBF7D0)
                                    : const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: Text(
                              otherRole,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isOwner
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_otherUser != null && _otherUser!.department.isNotEmpty)
                        Text(
                          '${_otherUser!.department} • ${_otherUser!.academicYear}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      if (_otherUser != null && _otherUser!.registerNumber.isNotEmpty)
                        Text(
                          'Roll No: ${AppHelpers.maskRegisterNumber(_otherUser!.registerNumber)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Non-completed transaction warning
          if (!isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Ratings and feedback are available only after the item has been returned and the transaction is successfully completed.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Existing Review Status Banner
          if (isAlreadyReviewed) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Feedback Submitted',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Submitted on ${AppHelpers.formatDateTime(_existingReview!.createdAt)}. Reviews are permanent and cannot be modified.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Rating Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  isAlreadyReviewed
                      ? 'Your Rating for $otherName'
                      : 'How would you rate $otherName?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOwner
                      ? 'Communication, responsibility, punctuality, and item care'
                      : 'Communication, helpfulness, punctuality, and borrowing experience',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),

                // Star Rating Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNumber = index + 1;
                    final isFilled = starNumber <= _selectedRating;
                    return IconButton(
                      iconSize: 40,
                      splashRadius: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: (!isCompleted || isAlreadyReviewed || _isSubmitting)
                          ? null
                          : () {
                              setState(() {
                                _selectedRating = starNumber;
                              });
                            },
                      icon: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isFilled ? Colors.amber.shade600 : Colors.grey.shade400,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_selectedRating of 5 Stars',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 24),

                // Feedback Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Written Feedback',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Optional',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _feedbackController,
                  enabled: isCompleted && !isAlreadyReviewed && !_isSubmitting,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: isOwner
                        ? 'Share brief feedback about the borrower\'s punctuality, responsibility, and condition of the returned item...'
                        : 'Share brief feedback about the lender\'s helpfulness, handover communication, and overall experience...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: isAlreadyReviewed ? const Color(0xFFF8FAFC) : Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit Button
                if (!isAlreadyReviewed) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: (!isCompleted || _isSubmitting)
                          ? null
                          : _submitFeedback,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSubmitting ? 'Submitting Review...' : 'Submit Feedback',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Disabled submitted state
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Feedback Submitted & Recorded'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Other Party Review Status Information
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  txn.hasOtherPartyRated(currentUserId)
                      ? Icons.check_circle_outline
                      : Icons.pending_outlined,
                  size: 20,
                  color: txn.hasOtherPartyRated(currentUserId)
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    txn.hasOtherPartyRated(currentUserId)
                        ? '$otherName has submitted their feedback for you.'
                        : '$otherName\'s feedback is currently pending.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: txn.hasOtherPartyRated(currentUserId)
                          ? const Color(0xFF065F46)
                          : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
