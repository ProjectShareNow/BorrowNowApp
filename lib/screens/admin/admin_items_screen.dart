import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/empty_state.dart';

class AdminItemsScreen extends StatefulWidget {
  const AdminItemsScreen({super.key});

  @override
  State<AdminItemsScreen> createState() => _AdminItemsScreenState();
}

class _AdminItemsScreenState extends State<AdminItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeactivateDialog(BuildContext context, ItemModel item) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Listing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: "${item.name}" by ${item.ownerName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please provide a justification for taking down this listing. The owner will be notified.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'e.g. Inappropriate item, counterfeit, prohibited on campus...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a deactivation reason.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final adminProvider = Provider.of<AdminProvider>(
                context,
                listen: false,
              );
              await adminProvider.adminDeactivateItem(
                itemId: item.id,
                adminUid: auth.currentUser?.uid ?? 'admin',
                adminName: auth.currentUser?.fullName ?? 'Administrator',
                reason: reason,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Listing deactivated successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemDetailsModal(BuildContext context, ItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (item.photoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: Image.network(
                      item.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(Icons.broken_image, size: 48),
                          ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.isInactive
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.availability.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.isInactive
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Category: ${item.category} • Condition: ${item.condition}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                'Owner: ${item.ownerName} (${item.ownerDepartment})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (item.pickupLocation.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Pickup Location: ${item.pickupLocation}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              const Divider(height: 24),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                item.description.isNotEmpty
                    ? item.description
                    : 'No description provided.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (!item.isInactive)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(
                      Icons.block,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Deactivate This Listing',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showDeactivateDialog(context, item);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.currentUser == null || !auth.currentUser!.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'Administrative authorization required.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final adminProvider = Provider.of<AdminProvider>(context);
    final items = adminProvider.allItems.where((item) {
      if (_selectedFilter != 'All' &&
          item.availability.toLowerCase() != _selectedFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return item.name.toLowerCase().contains(_searchQuery) ||
            item.description.toLowerCase().contains(_searchQuery) ||
            item.ownerName.toLowerCase().contains(_searchQuery) ||
            item.category.toLowerCase().contains(_searchQuery) ||
            item.pickupLocation.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Item Management')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items, category, or owner...',
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

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: ['All', 'Available', 'Reserved', 'Borrowed', 'Inactive']
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f, style: const TextStyle(fontSize: 12)),
                        selected: _selectedFilter == f,
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedFilter = f);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Items List
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No Items Found',
                    description: 'No item listings match the current criteria.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 14),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isInactive = item.isInactive;

                      return Card(
                        child: InkWell(
                          onTap: () => _showItemDetailsModal(context, item),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey.shade200,
                                    child: item.photoUrl.isNotEmpty
                                        ? Image.network(
                                            item.photoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.image_outlined,
                                                    ),
                                          )
                                        : const Icon(Icons.image_outlined),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isInactive
                                                  ? Colors.red.shade50
                                                  : Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.availability.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isInactive
                                                    ? Colors.red.shade700
                                                    : Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.category} • ${item.condition}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Owner: ${item.ownerName} (${item.ownerDepartment})',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (!isInactive)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                _showDeactivateDialog(
                                                  context,
                                                  item,
                                                ),
                                            icon: const Icon(
                                              Icons.block_rounded,
                                              size: 14,
                                              color: Colors.red,
                                            ),
                                            label: const Text(
                                              'Deactivate',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: Colors.red.shade200,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
