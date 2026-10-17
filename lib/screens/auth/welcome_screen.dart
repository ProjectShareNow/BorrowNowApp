import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/images/borrow_now_logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Campus Sharing\nMade Effortless',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Borrow calculators, lab coats, chargers, and textbooks directly from verified students on your campus.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Campus Safety & ID verification pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF0F766E),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '100% Student Verified via College ID Card',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Get Started / Register',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.register),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Sign In to Account',
                isOutlined: true,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
