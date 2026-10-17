import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item_model.dart';
import '../../models/borrow_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class BorrowRequestFormScreen extends StatefulWidget {
  final ItemModel? item;

  const BorrowRequestFormScreen({super.key, this.item});

  @override
  State<BorrowRequestFormScreen> createState() =>
      _BorrowRequestFormScreenState();
}

class _BorrowRequestFormScreenState extends State<BorrowRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _itemNameController;
  late TextEditingController _pickupLocationController;
  final _messageController = TextEditingController();

  String _selectedCategory = 'Books';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 16, minute: 0);
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController(
      text: widget.item?.name ?? '',
    );
    if (widget.item != null && widget.item!.category.isNotEmpty) {
      _selectedCategory = widget.item!.category;
    }
    _pickupLocationController = TextEditingController(
      text: widget.item?.pickupLocation.isNotEmpty == true
          ? widget.item!.pickupLocation
          : AppConstants.campusPickupLocations.first,
    );
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _pickupLocationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      AppHelpers.showSnackBar(
        context,
        'Please log in to submit a request.',
        isError: true,
      );
      return;
    }

    if (widget.item != null && user.uid == widget.item!.ownerId) {
      AppHelpers.showSnackBar(
        context,
        'You cannot borrow your own item.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final requestProvider = Provider.of<RequestProvider>(
        context,
        listen: false,
      );
      final formattedTime = _selectedTime.format(context);
      final itemName = widget.item?.name ?? _itemNameController.text.trim();
      final tempReqId = 'req_${DateTime.now().millisecondsSinceEpoch}';
      final itemId = widget.item?.id ?? tempReqId;
      final ownerId = widget.item?.ownerId ?? 'campus_community';

      final request = BorrowRequestModel(
        id: '',
        itemId: itemId,
        itemName: itemName,
        category: _selectedCategory,
        itemPhotoUrl: widget.item?.photoUrl ?? '',
        ownerId: ownerId,
        borrowerId: user.uid,
        borrowerName: user.fullName,
        borrowerDepartment: user.department,
        collegeId: user.collegeId.isNotEmpty ? user.collegeId : user.registerNumber,
        borrowerRating: user.ratingAverage,
        requiredTime: formattedTime,
        pickupLocation: _pickupLocationController.text.trim(),
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
        status: 'pending',
      );

      final success = await requestProvider.submitRequest(request);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        final successMsg = widget.item != null
            ? 'Borrow request sent to ${widget.item!.ownerName}!'
            : 'Request for "$itemName" posted to campus community!';
        AppHelpers.showSnackBar(context, successMsg, isSuccess: true);
        Navigator.pop(context);
      } else {
        AppHelpers.showSnackBar(
          context,
          requestProvider.errorMessage ?? 'Failed to submit request.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppHelpers.showSnackBar(
          context,
          'Error creating request: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomItem = widget.item == null;
    final availableCategories =
        AppConstants.categories.where((c) => c != 'All').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(isCustomItem ? 'Request an Item' : 'Request to Borrow'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isCustomItem) ...[
                  // Item Preview Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bookmark_border_rounded,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Owner: ${widget.item!.ownerName} (${widget.item!.ownerDepartment})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // Item Name Field
                  CustomTextField(
                    controller: _itemNameController,
                    labelText: 'Item Name *',
                    hintText: 'e.g. Scientific Calculator fx-991EX',
                    prefixIcon: Icons.inventory_2_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter the item you need';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      prefixIcon: Icon(Icons.category_outlined, size: 20),
                    ),
                    dropdownColor: Colors.white,
                    items: availableCategories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat,
                              style: const TextStyle(color: Color(0xFF111827)),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Need Until Time
                Text(
                  'Need Until Time *',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _selectTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pickup Location
                Text(
                  'Campus Pickup Location *',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _pickupLocationController,
                  labelText: 'Pickup Location',
                  prefixIcon: Icons.place_outlined,
                  validator: Validators.validatePickupLocation,
                ),
                const SizedBox(height: 8),

                // Quick location chips from predefined campus locations
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AppConstants.campusPickupLocations.map((loc) {
                    final isSelected = _pickupLocationController.text == loc;
                    return InkWell(
                      onTap: () {
                        setState(() => _pickupLocationController.text = loc);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF6FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          loc,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Message / Note
                CustomTextField(
                  controller: _messageController,
                  labelText: 'Note / Reason (Optional)',
                  hintText:
                      'e.g. Needed for Lab exam / Midterm study in library',
                  maxLines: 3,
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'Post Request',
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
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
