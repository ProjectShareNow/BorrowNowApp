import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/item_model.dart';
import '../../models/rating_model.dart';
import '../../services/service_registry.dart';
import '../../app/routes.dart';
import '../../utils/helpers.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/item_card.dart';
import '../../widgets/loading_widget.dart';

class UserPublicProfileScreen extends StatefulWidget {
  final String userId;

  const UserPublicProfileScreen({super.key, required this.userId});

  @override
  State<UserPublicProfileScreen> createState() =>
      _UserPublicProfileScreenState();
}

class _UserPublicProfileScreenState extends State<UserPublicProfileScreen> {
  UserModel? _user;
  List<ItemModel> _userItems = [];
  List<RatingModel> _reviews = [];
  bool _isLoading = true;
  StreamSubscription<List<ItemModel>>? _itemsSub;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _itemsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final user = await ServiceRegistry.authService.getUserData(widget.userId);
    final reviews = await ServiceRegistry.ratingService.getUserReviews(
      widget.userId,
    );

    // Fetch user items
    _itemsSub = ServiceRegistry.itemService
        .getMyItemsStream(widget.userId)
        .listen((list) {
          if (mounted) {
            setState(() {
              _userItems = list.where((i) => i.isAvailable).toList();
            });
          }
        });

    if (mounted) {
      setState(() {
        _user = user;
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading student profile...'),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Profile')),
        body: const Center(child: Text('User profile not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Student Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  UserAvatar(
                    name: _user!.fullName,
                    radius: 40,
                    rating: _user!.ratingAverage,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _user!.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_user!.department} • ${_user!.academicYear}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Roll No: ${AppHelpers.maskRegisterNumber(_user!.registerNumber)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppHelpers.formatRatingDisplay(
                            _user!.ratingAverage,
                            _user!.ratingsCount,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _buildStat('Active Items', '${_userItems.length}')),
                  Container(
                    width: 1,
                    height: 30,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(child: _buildStat('Completed Loans', '${_user!.borrowedCount}')),
                  Container(
                    width: 1,
                    height: 30,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _buildStat(
                      'Rating',
                      AppHelpers.formatRatingDisplay(
                        _user!.ratingAverage,
                        _user!.ratingsCount,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Currently Available Items by this user
            Text(
              'Items Available from ${_user!.fullName.split(" ").first}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_userItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No items currently listed for lending.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              )
            else
              ..._userItems.map(
                (item) => ItemCard(
                  item: item,
                  isHorizontal: true,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.itemDetails,
                      arguments: item,
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            // Reviews Received Section
            Text(
              'Peer Reviews (${_user!.ratingsCount})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No reviews submitted yet. Rating: ${AppHelpers.formatRatingDisplay(_user!.ratingAverage, _user!.ratingsCount)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              )
            else
              ..._reviews.map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            r.fromUserName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (idx) => Icon(
                                idx < r.rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.review,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppHelpers.formatDate(r.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
