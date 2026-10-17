import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../models/item_model.dart';
import '../../app/routes.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';

class MyListedItemsScreen extends StatefulWidget {
  const MyListedItemsScreen({super.key});

  @override
  State<MyListedItemsScreen> createState() => _MyListedItemsScreenState();
}

class _MyListedItemsScreenState extends State<MyListedItemsScreen> {
  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      Provider.of<ItemProvider>(
        context,
        listen: false,
      ).listenToUserItems(auth.currentUser!.uid);
    }
  }

  void _confirmDelete(BuildContext context, ItemModel item) async {
    final confirm = await AppHelpers.showConfirmDialog(
      context: context,
      title: 'Delete Item',
      message: 'Are you sure you want to remove "${item.name}" from your listed items?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirm && context.mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final success = await itemProvider.deleteItem(item.id, auth.currentUser?.uid ?? '');
      if (context.mounted) {
        if (success) {
          AppHelpers.showSnackBar(context, 'Item deleted successfully.', isSuccess: true);
        } else {
          AppHelpers.showSnackBar(
            context,
            itemProvider.errorMessage ?? 'Failed to delete item.',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final items = itemProvider.myItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Items'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addItem),
            icon: const Icon(Icons.add_rounded),
            tooltip: '+ Add Item',
          ),
        ],
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No Items Listed',
              description:
                  'You haven’t listed any items for lending yet. Share an extra calculator, charger, or textbook with your peers!',
              buttonText: '+ Add Item',
              onButtonPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.addItem),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildMyItemCard(context, item);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addItem),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('+ Add Item'),
      ),
    );
  }

  Widget _buildMyItemCard(BuildContext context, ItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.itemDetails,
            arguments: item,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Image / Icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: const Color(0xFFF1F5F9),
                      child: item.photoUrl.isNotEmpty
                          ? Image.network(
                              item.photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Icon(
                                Icons.inventory_2_outlined,
                                color: Color(0xFF2563EB),
                                size: 28,
                              ),
                            )
                          : const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF2563EB),
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.pickupLocation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: item.availability),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 8),

              // Action Buttons: Edit, Delete
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.editItem,
                        arguments: item,
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _confirmDelete(context, item),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: const Color(0xFFDC2626),
                    tooltip: 'Delete Item',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
