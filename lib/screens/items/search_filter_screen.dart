import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/item_provider.dart';
import '../../app/routes.dart';
import '../../utils/constants.dart';
import '../../widgets/item_card.dart';
import '../../widgets/empty_state.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    _searchController.text = itemProvider.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context, ItemProvider itemProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          itemProvider.resetFilters();
                          _searchController.clear();
                          Navigator.pop(context);
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Category filter
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.categories.map((cat) {
                      final isSelected = itemProvider.selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            itemProvider.setCategory(selected ? cat : 'All');
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Availability filter
                  const Text(
                    'Availability',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'available', 'reserved', 'borrowed'].map((
                      status,
                    ) {
                      final isSelected =
                          itemProvider.selectedAvailability == status;
                      return ChoiceChip(
                        label: Text(
                          status.toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            itemProvider.setAvailability(
                              selected ? status : 'All',
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Department filter
                  const Text(
                    'Lender Department',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: itemProvider.selectedDepartment,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: ['All', ...AppConstants.departments].map((dept) {
                      return DropdownMenuItem(
                        value: dept,
                        child: Text(dept, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          itemProvider.setDepartment(val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemProvider = Provider.of<ItemProvider>(context);
    final items = itemProvider.filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Campus Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter',
            onPressed: () => _showFilterModal(context, itemProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items, condition, location...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          itemProvider.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (val) => itemProvider.setSearchQuery(val),
            ),
          ),

          // Active filter tags row
          if (itemProvider.selectedCategory != 'All' ||
              itemProvider.selectedAvailability != 'All' ||
              itemProvider.selectedDepartment != 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (itemProvider.selectedCategory != 'All')
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Chip(
                          label: Text(
                            'Category: ${itemProvider.selectedCategory}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => itemProvider.setCategory('All'),
                        ),
                      ),
                    if (itemProvider.selectedAvailability != 'All')
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Chip(
                          label: Text(
                            'Status: ${itemProvider.selectedAvailability}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => itemProvider.setAvailability('All'),
                        ),
                      ),
                    if (itemProvider.selectedDepartment != 'All')
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Chip(
                          label: Text(
                            'Dept: ${itemProvider.selectedDepartment}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => itemProvider.setDepartment('All'),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Results count and sorting
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${items.length} ${items.length == 1 ? "item" : "items"} found',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                PopupMenuButton<String>(
                  initialValue: itemProvider.sortBy,
                  onSelected: (val) => itemProvider.setSortBy(val),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        itemProvider.sortBy == 'recent' ? 'Recent' : 'Name',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'recent',
                      child: Text('Sort by Most Recent'),
                    ),
                    const PopupMenuItem(
                      value: 'name',
                      child: Text('Sort by Name (A-Z)'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items List / Grid
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No Matching Items Found',
                    description:
                        'Try adjusting your search keywords, category, or filter criteria.',
                    buttonText: 'Clear Filters',
                    onButtonPressed: () {
                      _searchController.clear();
                      itemProvider.resetFilters();
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ItemCard(
                        item: item,
                        isHorizontal: true,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.itemDetails,
                            arguments: item,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
