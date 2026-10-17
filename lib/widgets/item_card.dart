import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../utils/constants.dart';
import 'status_chip.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onTap;
  final bool isHorizontal;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        item.photoUrl.isNotEmpty && item.photoUrl.startsWith('http');

    if (isHorizontal) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade100,
                    child: hasImage
                        ? Image.network(
                            item.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Icon(
                              AppConstants.getCategoryIcon(item.category),
                              size: 32,
                              color: theme.primaryColor,
                            ),
                          )
                        : Icon(
                            AppConstants.getCategoryIcon(item.category),
                            size: 32,
                            color: theme.primaryColor,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          StatusChip(status: item.availability, fontSize: 10),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.pickupLocation,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            item.ownerName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Colors.amber,
                          ),
                          Text(
                            ' ${item.ownerRating.toStringAsFixed(1)} / 5.0',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

    // Grid / Vertical card
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: hasImage
                      ? Image.network(
                          item.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Center(
                            child: Icon(
                              AppConstants.getCategoryIcon(item.category),
                              size: 40,
                              color: theme.primaryColor,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            AppConstants.getCategoryIcon(item.category),
                            size: 40,
                            color: theme.primaryColor,
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: StatusChip(status: item.availability, fontSize: 10),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.condition,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.pickupLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Colors.amber,
                          ),
                          Text(
                            ' ${item.ownerRating.toStringAsFixed(1)} / 5.0',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
