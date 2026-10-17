import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../app/routes.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/user_avatar.dart';

class ItemDetailsScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final itemProvider = Provider.of<ItemProvider>(context);

    final currentUser = authProvider.currentUser;
    final isOwner = currentUser?.uid == item.ownerId;
    final hasImage =
        item.photoUrl.isNotEmpty && item.photoUrl.startsWith('http');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          // Report item button for non-owners
          if (!isOwner)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Report Listing',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.submitReport,
                  arguments: {
                    'itemId': item.id,
                    'reportedUserId': item.ownerId,
                    'reportedUserName': item.ownerName,
                  },
                );
              },
            ),
          // Owner actions (Edit / Delete)
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'edit') {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.editItem,
                    arguments: item,
                  );
                } else if (val == 'delete') {
                  final confirm = await AppHelpers.showConfirmDialog(
                    context: context,
                    title: 'Delete Listing?',
                    message:
                        'Are you sure you want to remove "${item.name}" from the campus catalog?',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  );
                  if (confirm && context.mounted) {
                    final success = await itemProvider.deleteItem(
                      item.id,
                      currentUser!.uid,
                    );
                    if (context.mounted) {
                      if (success) {
                        AppHelpers.showSnackBar(
                          context,
                          'Listing deleted successfully.',
                          isSuccess: true,
                        );
                        Navigator.pop(context);
                      } else {
                        AppHelpers.showSnackBar(
                          context,
                          itemProvider.errorMessage ??
                              'Failed to delete listing',
                          isError: true,
                        );
                      }
                    }
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Item', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Photo
            Container(
              height: 240,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: hasImage
                  ? Image.network(
                      item.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Center(
                        child: Icon(
                          AppConstants.getCategoryIcon(item.category),
                          size: 64,
                          color: theme.primaryColor,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        AppConstants.getCategoryIcon(item.category),
                        size: 64,
                        color: theme.primaryColor,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges: Category & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      StatusChip(status: item.availability),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Item Name
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Condition & Pickup Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeaturePill(
                          icon: Icons.thumb_up_alt_outlined,
                          title: 'Condition',
                          value: item.condition,
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: const Color(0xFFE2E8F0),
                        ),
                        _buildFeaturePill(
                          icon: Icons.place_outlined,
                          title: 'Pickup Hub',
                          value: item.pickupLocation,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Item Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Owner Information Card
                  const Text(
                    'Lender Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.userPublicProfile,
                        arguments: item.ownerId,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          UserAvatar(
                            name: item.ownerName,
                            imageUrl: item.ownerPhotoUrl,
                            radius: 22,
                            rating: item.ownerRating,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.ownerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.ownerDepartment.isNotEmpty
                                      ? item.ownerDepartment
                                      : 'Verified Student',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${item.ownerRating.toStringAsFixed(1)} / 5.0',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: isOwner
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final newStatus = item.isAvailable
                              ? AppConstants.statusInactive
                              : AppConstants.statusAvailable;
                          await itemProvider.updateItemAvailability(
                            item.id,
                            newStatus,
                            currentUser!.uid,
                          );
                          if (context.mounted) {
                            AppHelpers.showSnackBar(
                              context,
                              'Availability set to ${AppHelpers.getStatusLabel(newStatus)}',
                              isSuccess: true,
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          item.isAvailable
                              ? 'Deactivate Listing'
                              : 'Make Available',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.editItem,
                          arguments: item,
                        ),
                        child: const Text('Edit Listing'),
                      ),
                    ),
                  ],
                )
              : CustomButton(
                  text: item.isAvailable
                      ? 'Request to Borrow'
                      : 'Currently Not Available',
                  onPressed: item.isAvailable
                      ? () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.borrowRequestForm,
                            arguments: item,
                          );
                        }
                      : null,
                ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
