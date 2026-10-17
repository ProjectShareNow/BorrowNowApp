import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendPasswordReset(_emailController.text);

    if (!mounted) return;

    if (success) {
      setState(() => _emailSent = true);
    } else {
      AppHelpers.showSnackBar(
        context,
        authProvider.errorMessage ??
            'Could not send reset link. Please check your email.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _emailSent
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_email_read_rounded,
                          size: 56,
                          color: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Password Reset Email Sent!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We have sent instructions to ${_emailController.text}. Please check your inbox and spam folders.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Back to Sign In',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Forgot Password?',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your registered college email and we will send you a link to reset your account password.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'College Email',
                        hintText: 'e.g. rollno@college.edu',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Send Reset Link',
                        isLoading: authProvider.isLoading,
                        onPressed: _handleReset,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
