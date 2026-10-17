import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/rating_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_registry.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';

class RateUserDialog extends StatefulWidget {
  final String transactionId;
  final String fromUserId;
  final String toUserId;
  final String toUserName;

  const RateUserDialog({
    super.key,
    required this.transactionId,
    required this.fromUserId,
    required this.toUserId,
    required this.toUserName,
  });

  @override
  State<RateUserDialog> createState() => _RateUserDialogState();
}

class _RateUserDialogState extends State<RateUserDialog> {
  double _rating = 5.0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_rating < 1.0 || _rating > 5.0) {
      AppHelpers.showSnackBar(
        context,
        'Please select a rating between 1 and 5 stars. Ratings of 0 are not allowed.',
        isError: true,
      );
      return;
    }

    final text = _reviewController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser;

      final rating = RatingModel(
        id: '',
        transactionId: widget.transactionId,
        fromUserId: widget.fromUserId,
        fromUserName: user?.fullName ?? 'Student',
        toUserId: widget.toUserId,
        rating: _rating,
        review: text,
      );

      await ServiceRegistry.ratingService.submitRating(rating);

      setState(() => _isSubmitting = false);

      if (!mounted) return;

      AppHelpers.showSnackBar(
        context,
        'Thank you! Your rating has been recorded.',
        isSuccess: true,
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 44),
          const SizedBox(height: 8),
          Text(
            'Rate ${widget.toUserName}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'How was your borrowing and handover experience?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1.0;
                return IconButton(
                  icon: Icon(
                    starValue <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () => setState(() => _rating = starValue),
                );
              }),
            ),
            Text(
              '${_rating.toInt()} / 5 Stars',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 16),

            // Review text
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText:
                    'Share feedback (e.g. prompt handover, item in pristine condition)',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                text: 'Submit',
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
                height: 42,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
