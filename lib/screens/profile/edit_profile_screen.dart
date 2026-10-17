import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late String _selectedDepartment;
  late String _selectedAcademicYear;
  String? _selectedSemester;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');

    _selectedDepartment =
        (user?.department.isNotEmpty == true &&
            AppConstants.departments.contains(user!.department))
        ? user.department
        : AppConstants.departments.first;

    _selectedAcademicYear =
        (user?.academicYear.isNotEmpty == true &&
            AppConstants.academicYears.contains(user!.academicYear))
        ? user.academicYear
        : AppConstants.academicYears.first;

    _selectedSemester =
        (user?.semester.isNotEmpty == true &&
            AppConstants.studentSemesters.contains(user!.semester))
        ? user.semester
        : null;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      fullName: _fullNameController.text.trim(),
      department: _selectedDepartment,
      academicYear: _selectedAcademicYear,
      semester: _selectedSemester,
    );

    if (!mounted) return;

    if (success) {
      AppHelpers.showSnackBar(
        context,
        'Profile updated successfully!',
        isSuccess: true,
      );
      Navigator.pop(context);
    } else {
      AppHelpers.showSnackBar(
        context,
        authProvider.errorMessage ?? 'Failed to update profile.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Avatar Header
                Center(
                  child: UserAvatar(
                    name: user?.fullName ?? 'Student',
                    radius: 42,
                    rating: user?.ratingAverage,
                  ),
                ),
                const SizedBox(height: 20),

                // Read-only institutional fields notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Institutional fields (Email: ${user?.email}, Register No: ${AppHelpers.maskRegisterNumber(user?.registerNumber)}) are locked for integrity.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomTextField(
                  controller: _fullNameController,
                  labelText: 'Full Name *',
                  validator: Validators.validateName,
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                  ),
                  items: AppConstants.departments
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(d, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedDepartment = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedAcademicYear,
                  decoration: const InputDecoration(
                    labelText: 'Academic Year',
                    prefixIcon: Icon(Icons.school_outlined, size: 20),
                  ),
                  items: AppConstants.academicYears
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(y, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedAcademicYear = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedSemester,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    hintText: 'Select Semester',
                    prefixIcon: Icon(Icons.calendar_month_outlined, size: 20),
                  ),
                  hint: const Text(
                    'Select Semester',
                    style: TextStyle(fontSize: 13),
                  ),
                  items: AppConstants.studentSemesters
                      .map(
                        (sem) => DropdownMenuItem(
                          value: sem,
                          child: Text(
                            sem,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please select your semester';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    setState(() => _selectedSemester = val);
                  },
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: 'Save Changes',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 12),

                CustomButton(
                  text: 'Cancel',
                  isOutlined: true,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
