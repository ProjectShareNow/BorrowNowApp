import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../services/service_registry.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupLocationController = TextEditingController();

  String _selectedCategory = AppConstants.categories[1]; // Books
  String _selectedCondition = AppConstants.itemConditions[1]; // Like New
  XFile? _itemImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ServiceRegistry.storageService.pickImage();
    if (picked != null) {
      setState(() => _itemImage = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null || !user.isVerified) {
      AppHelpers.showSnackBar(
        context,
        'Only verified students can list items. Please wait for ID verification.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String photoUrl = '';
      if (_itemImage != null) {
        photoUrl = await ServiceRegistry.storageService.uploadItemImage(
          file: _itemImage!,
          itemId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      final newItem = ItemModel(
        id: '',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        condition: _selectedCondition,
        photoUrl: photoUrl,
        pickupLocation: _pickupLocationController.text.trim(),
        availability: AppConstants.statusAvailable,
        ownerId: user.uid,
        ownerName: user.fullName,
        ownerDepartment: user.department,
        ownerRating: user.ratingAverage,
      );

      if (!mounted) return;
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final success = await itemProvider.createItem(newItem);

      setState(() => _isSubmitting = false);

      if (!mounted) return;

      if (success) {
        AppHelpers.showSnackBar(
          context,
          'Your item has been successfully listed in the campus catalog!',
          isSuccess: true,
        );
        Navigator.pop(context);
      } else {
        AppHelpers.showSnackBar(
          context,
          itemProvider.errorMessage ?? 'Failed to list item.',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Error creating listing: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('List New Item')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Item Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'List an item for your peers to borrow during exam season or daily classes.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),

                // Item Photo Upload
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _itemImage != null
                            ? theme.primaryColor
                            : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: _itemImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                kIsWeb
                                    ? Image.network(
                                        _itemImage!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_itemImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Change Photo',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload Item Photo',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Clear photo helps faster requests',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Item Name
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Item Name *',
                  hintText: 'e.g. Casio fx-991EX Scientific Calculator',
                  prefixIcon: Icons.badge_outlined,
                  validator: Validators.validateItemTitle,
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                  ),
                  items: AppConstants.categories
                      .where((c) => c != 'All')
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 14)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 16),

                // Condition Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCondition,
                  decoration: const InputDecoration(
                    labelText: 'Condition *',
                    prefixIcon: Icon(Icons.thumb_up_alt_outlined, size: 20),
                  ),
                  items: AppConstants.itemConditions
                      .map(
                        (cond) => DropdownMenuItem(
                          value: cond,
                          child: Text(
                            cond,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCondition = val);
                  },
                ),
                const SizedBox(height: 16),

                // Pickup Location
                CustomTextField(
                  controller: _pickupLocationController,
                  labelText: 'Campus Pickup Location *',
                  hintText:
                      'e.g. CS Dept Library / Block C Entrance / Hostel 4 Common Room',
                  prefixIcon: Icons.place_outlined,
                  validator: Validators.validatePickupLocation,
                ),
                const SizedBox(height: 16),

                // Description
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description & Lending Guidelines *',
                  hintText:
                      'Describe working condition, included accessories, or lending rules (e.g. return before 5 PM)',
                  maxLines: 4,
                  validator: Validators.validateItemDescription,
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'Publish Item Listing',
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
