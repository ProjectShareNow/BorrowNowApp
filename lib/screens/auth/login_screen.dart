import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../app/routes.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Colors as specified in design requirements
  static const Color _primaryNavy = Color(0xFF102A43);
  static const Color _brightBlue = Color(0xFF1478E8);
  static const Color _paleBorder = Color(0xFFD4E3F7);
  static const Color _secondaryText = Color(0xFF71839F);
  static const Color _inputBackground = Color(0xFFF7FAFD);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.currentUser!;

      if (!user.isActive) {
        Navigator.pushReplacementNamed(context, AppRoutes.accountDisabled);
        return;
      }

      if (user.isAdmin) {
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        return;
      }

      if (user.isRejected) {
        Navigator.pushReplacementNamed(context, AppRoutes.accountRejected);
        return;
      }

      if (user.isPending) {
        Navigator.pushReplacementNamed(context, AppRoutes.verificationPending);
        return;
      }

      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      AppHelpers.showSnackBar(
        context,
        authProvider.errorMessage ??
            'Login failed. Please check your credentials.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Main Login Form Section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 12),

                                // 1. Brand Logo & Subtitle (From Reference Image 1)
                                _buildBrandLogo(),

                                const SizedBox(height: 28),

                                // 2. Welcome Section (From Reference Image 2)
                                _buildWelcomeSection(),

                                const SizedBox(height: 24),

                                // 3. College Email Field
                                _buildEmailField(),

                                const SizedBox(height: 16),

                                // 4. Password Field with Visibility Toggle
                                _buildPasswordField(),

                                const SizedBox(height: 24),

                                // 5. Login Button ("Login →")
                                _buildLoginButton(authProvider),

                                const SizedBox(height: 8),

                                // 6. Forgot Password (Right-aligned below Login button)
                                _buildForgotPasswordLink(),

                                const SizedBox(height: 20),

                                // 7. Registration Link
                                _buildRegistrationLink(),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 8. Campus Illustration and Footer
                      _buildCampusFooter(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 1. BorrowNow Brand Logo with graduation cap & subtitle (Exact from reference image)
  Widget _buildBrandLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/borrow_now_logo.png',
          height: 112,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 6),

        // Subtitle: "A Smarter Way to Share"
        const Text(
          'A Smarter Way to Share',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _secondaryText,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  /// 2. Welcome Section: "Welcome Back!" and "Sign in to continue to BorrowNow"
  Widget _buildWelcomeSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _primaryNavy,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Sign in to continue to BorrowNow',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _secondaryText,
          ),
        ),
      ],
    );
  }

  /// 3. Email Field: Rounded rectangular, email icon, light bg, pale blue border
  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: _inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _paleBorder, width: 1.2),
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(
          color: _primaryNavy,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          hintText: 'Email or Register ID',
          hintStyle: TextStyle(
            color: _secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.mail_outline_rounded,
            color: _secondaryText,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: Validators.validateEmailOrRegisterId,
      ),
    );
  }

  /// 4. Password Field: Rounded rectangular, lock icon, toggle visibility
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: _inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _paleBorder, width: 1.2),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(
          color: _primaryNavy,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: const TextStyle(
            color: _secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: _secondaryText,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _secondaryText,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (v) => Validators.validateRequired(v, 'Password'),
      ),
    );
  }

  /// 5. Full-width bright blue Login Button: "Login →" with shadow
  Widget _buildLoginButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brightBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _brightBlue.withValues(alpha: 0.6),
          elevation: 3,
          shadowColor: _brightBlue.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: authProvider.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
      ),
    );
  }

  /// 6. Right-aligned Forgot Password link below the Login button
  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          visualDensity: VisualDensity.compact,
        ),
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: _brightBlue,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 7. Registration link: "Don't have an account? Register"
  Widget _buildRegistrationLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(color: _secondaryText, fontSize: 14),
        ),
        GestureDetector(
          onTap: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.register),
          child: const Text(
            'Register',
            style: TextStyle(
              color: _brightBlue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 8. Campus Illustration and Footer
  Widget _buildCampusFooter() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8, bottom: 20, left: 24, right: 24),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subtle Campus Illustration
          SizedBox(
            height: 78,
            width: double.infinity,
            child: CustomPaint(painter: _CampusIllustrationPainter()),
          ),
          SizedBox(height: 10),

          // Footer Text: "Together, We Make Campus Life Easier"
          Text(
            'Together, We Make Campus Life Easier',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _secondaryText,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for a subtle, modern college campus line-art illustration
/// with neo-classical campus building, lush trees/greenery, and light-blue decorative shapes.
class _CampusIllustrationPainter extends CustomPainter {
  const _CampusIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1478E8).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final secondaryPaint = Paint()
      ..color = const Color(0xFF71839F).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final treeGreenPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final treeGreenStroke = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final treeBluePaint = Paint()
      ..color = const Color(0xFF1478E8).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final groundY = size.height - 8;
    final centerX = size.width / 2;

    // 0. Light-blue decorative background shapes
    final decoBgPaint = Paint()
      ..color = const Color(0xFFEAF3FF)
      ..style = PaintingStyle.fill;
    final decoBorderPaint = Paint()
      ..color = const Color(0xFFD4E3F7).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Soft rounded backdrop pill behind the buildings and trees
    final bgRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, groundY - 26),
        width: (size.width * 0.9).clamp(240.0, 360.0),
        height: 60,
      ),
      const Radius.circular(30),
    );
    canvas.drawRRect(bgRRect, decoBgPaint);
    canvas.drawRRect(bgRRect, decoBorderPaint);

    // Subtle decorative aura behind the central clock tower
    canvas.drawCircle(
      Offset(centerX, groundY - 42),
      24,
      Paint()..color = const Color(0xFFD4E3F7).withValues(alpha: 0.45),
    );

    // 1. Ground line with gentle curve
    final groundPath = Path()
      ..moveTo(0, groundY)
      ..quadraticBezierTo(size.width * 0.25, groundY - 3, centerX, groundY)
      ..quadraticBezierTo(size.width * 0.75, groundY + 2, size.width, groundY);
    canvas.drawPath(groundPath, strokePaint);

    // 2. Central Academic Hall (Neo-classical campus building)
    const buildingWidth = 74.0;
    const buildingHeight = 36.0;
    final buildingLeft = centerX - (buildingWidth / 2);
    final buildingTop = groundY - buildingHeight;

    // Building body
    final buildingRect = Rect.fromLTWH(
      buildingLeft,
      buildingTop,
      buildingWidth,
      buildingHeight,
    );
    canvas.drawRect(buildingRect, fillPaint);
    canvas.drawRect(buildingRect, strokePaint);

    // Columns
    const numColumns = 4;
    final colSpacing = buildingWidth / (numColumns + 1);
    for (int i = 1; i <= numColumns; i++) {
      final colX = buildingLeft + (i * colSpacing);
      canvas.drawLine(
        Offset(colX, buildingTop + 14),
        Offset(colX, groundY),
        secondaryPaint,
      );
    }

    // Central Arch Doorway
    const doorWidth = 14.0;
    const doorHeight = 16.0;
    final doorRect = Rect.fromLTWH(
      centerX - (doorWidth / 2),
      groundY - doorHeight,
      doorWidth,
      doorHeight,
    );
    final doorPath = Path()
      ..moveTo(doorRect.left, groundY)
      ..lineTo(doorRect.left, doorRect.top + 6)
      ..quadraticBezierTo(
        centerX,
        doorRect.top - 2,
        doorRect.right,
        doorRect.top + 6,
      )
      ..lineTo(doorRect.right, groundY);
    canvas.drawPath(doorPath, strokePaint);

    // Pediment (Triangle roof above columns)
    final pedimentPath = Path()
      ..moveTo(buildingLeft - 3, buildingTop)
      ..lineTo(centerX, buildingTop - 12)
      ..lineTo(buildingLeft + buildingWidth + 3, buildingTop)
      ..close();
    canvas.drawPath(pedimentPath, fillPaint);
    canvas.drawPath(pedimentPath, strokePaint);

    // Clock Tower / Dome above pediment
    const towerWidth = 20.0;
    const towerHeight = 16.0;
    final towerLeft = centerX - (towerWidth / 2);
    final towerTop = buildingTop - 12 - towerHeight;
    final towerRect = Rect.fromLTWH(
      towerLeft,
      towerTop,
      towerWidth,
      towerHeight,
    );
    canvas.drawRect(towerRect, fillPaint);
    canvas.drawRect(towerRect, strokePaint);

    // Clock face
    canvas.drawCircle(Offset(centerX, towerTop + 8), 4, strokePaint);

    // Dome on tower
    final domePath = Path()
      ..moveTo(towerLeft - 1, towerTop)
      ..quadraticBezierTo(
        centerX,
        towerTop - 10,
        towerLeft + towerWidth + 1,
        towerTop,
      )
      ..close();
    canvas.drawPath(domePath, fillPaint);
    canvas.drawPath(domePath, strokePaint);

    // Spire & flag
    canvas.drawLine(
      Offset(centerX, towerTop - 10),
      Offset(centerX, towerTop - 18),
      strokePaint,
    );
    final flagPath = Path()
      ..moveTo(centerX, towerTop - 18)
      ..lineTo(centerX + 6, towerTop - 15)
      ..lineTo(centerX, towerTop - 12)
      ..close();
    canvas.drawPath(flagPath, strokePaint);

    // 3. Side Wings
    const wingWidth = 38.0;
    const wingHeight = 24.0;

    // Left Wing
    final leftWingRect = Rect.fromLTWH(
      buildingLeft - wingWidth,
      groundY - wingHeight,
      wingWidth,
      wingHeight,
    );
    canvas.drawRect(leftWingRect, fillPaint);
    canvas.drawRect(leftWingRect, strokePaint);

    // Left Wing windows
    for (int w = 0; w < 3; w++) {
      final wx = buildingLeft - wingWidth + 6 + (w * 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, groundY - wingHeight + 6, 6, 8),
          const Radius.circular(2),
        ),
        secondaryPaint,
      );
    }

    // Right Wing
    final rightWingRect = Rect.fromLTWH(
      buildingLeft + buildingWidth,
      groundY - wingHeight,
      wingWidth,
      wingHeight,
    );
    canvas.drawRect(rightWingRect, fillPaint);
    canvas.drawRect(rightWingRect, strokePaint);

    // Right Wing windows
    for (int w = 0; w < 3; w++) {
      final wx = buildingLeft + buildingWidth + 6 + (w * 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, groundY - wingHeight + 6, 6, 8),
          const Radius.circular(2),
        ),
        secondaryPaint,
      );
    }

    // 4. Campus Trees & Greenery flanking buildings
    void drawTree(
      double x,
      double radius,
      double trunkH, {
      bool isGreen = true,
    }) {
      // Trunk
      canvas.drawLine(
        Offset(x, groundY),
        Offset(x, groundY - trunkH),
        strokePaint,
      );
      // Foliage
      final center = Offset(x, groundY - trunkH - radius + 2);
      canvas.drawCircle(
        center,
        radius,
        isGreen ? treeGreenPaint : treeBluePaint,
      );
      canvas.drawCircle(
        center,
        radius,
        isGreen ? treeGreenStroke : strokePaint,
      );
    }

    drawTree(buildingLeft - wingWidth - 14, 11, 12, isGreen: true);
    drawTree(buildingLeft - wingWidth - 32, 8, 8, isGreen: false);
    drawTree(
      buildingLeft + buildingWidth + wingWidth + 14,
      11,
      12,
      isGreen: true,
    );
    drawTree(
      buildingLeft + buildingWidth + wingWidth + 32,
      8,
      8,
      isGreen: false,
    );

    // Small bush greenery accents along the ground
    canvas.drawCircle(
      Offset(buildingLeft - 6, groundY - 4),
      4.5,
      treeGreenPaint,
    );
    canvas.drawCircle(
      Offset(buildingLeft - 6, groundY - 4),
      4.5,
      treeGreenStroke,
    );
    canvas.drawCircle(
      Offset(buildingLeft + buildingWidth + 6, groundY - 4),
      4.5,
      treeGreenPaint,
    );
    canvas.drawCircle(
      Offset(buildingLeft + buildingWidth + 6, groundY - 4),
      4.5,
      treeGreenStroke,
    );

    // 5. Pathway lines leading to entrance
    final path1 = Path()
      ..moveTo(centerX - 6, groundY)
      ..lineTo(centerX - 16, size.height);
    final path2 = Path()
      ..moveTo(centerX + 6, groundY)
      ..lineTo(centerX + 16, size.height);
    canvas.drawPath(path1, secondaryPaint);
    canvas.drawPath(path2, secondaryPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
