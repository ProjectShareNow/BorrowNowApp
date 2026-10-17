import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditItemScreen extends StatefulWidget {
  final ItemModel item;

  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _pickupLocationController;

  late String _selectedCategory;
  late String _selectedCondition;
  late String _selectedAvailability;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _descriptionController = TextEditingController(
      text: widget.item.description,
    );
    _pickupLocationController = TextEditingController(
      text: widget.item.pickupLocation,
    );

    _selectedCategory = widget.item.category;
    _selectedCondition = widget.item.condition;
    _selectedAvailability = widget.item.availability;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null || user.uid != widget.item.ownerId) {
      AppHelpers.showSnackBar(
        context,
        'Unauthorized: You can only edit your own listings.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    final updated = widget.item.copyWith(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      condition: _selectedCondition,
      pickupLocation: _pickupLocationController.text.trim(),
      availability: _selectedAvailability,
    );

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final success = await itemProvider.updateItem(updated, user.uid);

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      AppHelpers.showSnackBar(
        context,
        'Item details updated successfully!',
        isSuccess: true,
      );
      Navigator.pop(context);
    } else {
      AppHelpers.showSnackBar(
        context,
        itemProvider.errorMessage ?? 'Failed to update item.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item Listing')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Item Name *',
                  validator: Validators.validateItemTitle,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                  ),
                  items: AppConstants.categories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedCondition,
                  decoration: const InputDecoration(
                    labelText: 'Condition *',
                    prefixIcon: Icon(Icons.thumb_up_alt_outlined, size: 20),
                  ),
                  items: AppConstants.itemConditions
                      .map(
                        (cond) =>
                            DropdownMenuItem(value: cond, child: Text(cond)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCondition = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedAvailability,
                  decoration: const InputDecoration(
                    labelText: 'Availability Status *',
                    prefixIcon: Icon(Icons.sync_alt_rounded, size: 20),
                  ),
                  items:
                      [
                            AppConstants.statusAvailable,
                            AppConstants.statusReserved,
                            AppConstants.statusBorrowed,
                            AppConstants.statusInactive,
                          ]
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(AppHelpers.getStatusLabel(s)),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedAvailability = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _pickupLocationController,
                  labelText: 'Pickup Location *',
                  validator: Validators.validatePickupLocation,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description *',
                  maxLines: 4,
                  validator: Validators.validateItemDescription,
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: 'Save Changes',
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
