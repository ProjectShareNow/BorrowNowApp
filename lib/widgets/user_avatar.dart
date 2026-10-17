import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;
  final double? rating;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 20,
    this.rating,
  });

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        imageUrl != null &&
        imageUrl!.isNotEmpty &&
        imageUrl!.startsWith('http');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
          backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
          child: !hasImage
              ? Text(
                  _getInitials(name),
                  style: TextStyle(
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                )
              : null,
        ),
        if (rating != null)
          Positioned(
            bottom: -2,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.amber.shade600,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                  const SizedBox(width: 1),
                  Text(
                    rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
