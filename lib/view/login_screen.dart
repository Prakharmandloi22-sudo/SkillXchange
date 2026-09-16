import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../core/theme.dart';
import '../widgets/animated_logo.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  // Phone Auth State
  bool _isPhoneMode = false;
  bool _otpSent = false;
  String? _verificationId;

  // 3D Tilt Values
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    setState(() {
      _tiltY += details.delta.dx / size.width;
      _tiltX -= details.delta.dy / size.height;
      _tiltX = _tiltX.clamp(-0.1, 0.1);
      _tiltY = _tiltY.clamp(-0.1, 0.1);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _tiltX = 0.0;
      _tiltY = 0.0;
    });
  }

  void _login() async {
    setState(() => _isLoading = true);
    final error = await ref
        .read(authActionsProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
    if (mounted) setState(() => _isLoading = false);
    if (error != null && mounted) _showError(error);
  }

  void _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('Enter phone number with country code');
      return;
    }

    setState(() => _isLoading = true);
    await ref
        .read(authActionsProvider.notifier)
        .verifyPhone(
          phoneNumber: phone,
          onCodeSent: (id) {
            setState(() {
              _verificationId = id;
              _otpSent = true;
              _isLoading = false;
            });
          },
          onFailed: (err) {
            setState(() => _isLoading = false);
            _showError(err);
          },
        );
  }

  void _signInWithOTP() async {
    if (_verificationId == null) return;
    setState(() => _isLoading = true);
    final error = await ref
        .read(authActionsProvider.notifier)
        .signInWithOTP(_verificationId!, _otpController.text.trim());
    if (mounted) setState(() => _isLoading = false);
    if (error != null && mounted) _showError(error);
  }

  void _googleLogin() async {
    setState(() => _isGoogleLoading = true);
    final error = await ref
        .read(authActionsProvider.notifier)
        .signInWithGoogle();
    if (mounted) setState(() => _isGoogleLoading = false);
    if (error != null && mounted) _showError(error);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onPanUpdate: (d) => _onPanUpdate(d, size),
        onPanEnd: _onPanEnd,
        child: Stack(
          children: [
            // ── 3D Parallax Background ────────────────
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Base Image
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/bg_3d.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Blur Overlay Fallback
                    Positioned.fill(
                      child: Container(
                        color: AppColors.background.withValues(alpha: 0.8),
                      ),
                    ),
                    // Parallax Orbs
                    _parallaxOrb(
                      size: 300,
                      color: AppColors.accent,
                      offset: Offset(
                        size.width * 0.1 + (_tiltY * 50),
                        size.height * 0.1 + (_tiltX * 50),
                      ),
                      opacity: 0.15,
                    ),
                    _parallaxOrb(
                      size: 250,
                      color: AppColors.purple,
                      offset: Offset(
                        size.width * 0.7 - (_tiltY * 80),
                        size.height * 0.6 - (_tiltX * 80),
                      ),
                      opacity: 0.1,
                    ),
                  ],
                );
              },
            ),

            // ── Grid Paint (Interactive) ────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _InteractiveGridPainter(_tiltX, _tiltY),
              ),
            ),

            // ── Main Content ──────────────────────────────
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _brandRow().animate().scale().fadeIn(),
                    const SizedBox(height: 40),

                    // 3D Perspective Card
                    Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015) // Perspective
                        ..rotateX(_tiltX)
                        ..rotateY(_tiltY),
                      alignment: FractionalOffset.center,
                      child: _buildLoginCard(),
                    ),

                    const SizedBox(height: 32),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isPhoneMode ? 'Phone Login' : 'Sign In',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isPhoneMode
                  ? 'Access the hub via secure SMS verification'
                  : 'Enter your credentials to access the 3D hub',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),

            // Dynamic Fields based on mode and OTP status
            if (!_isPhoneMode) ...[
              _buildField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.alternate_email_rounded,
                hint: 'alex@skillx.io',
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_person_rounded,
                hint: '••••••••',
                isPassword: true,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ] else if (!_otpSent) ...[
              _buildField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_android_rounded,
                hint: '+1 234 567 8900',
              ),
            ] else ...[
              _buildField(
                controller: _otpController,
                label: 'Enter OTP',
                icon: Icons.security_rounded,
                hint: '123456',
              ),
            ],

            const SizedBox(height: 40),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _primaryButton(
          text: _isPhoneMode
              ? (_otpSent ? 'Verify OTP' : 'Send Pulse OTP')
              : 'Launch Pulse',
          onTap: _isPhoneMode
              ? (_otpSent ? _signInWithOTP : _verifyPhone)
              : _login,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        _secondaryButton(
          text: _isPhoneMode ? 'Use Email Login' : 'Continue with Google',
          onTap: _isPhoneMode
              ? () => setState(() {
                  _isPhoneMode = false;
                  _otpSent = false;
                })
              : _googleLogin,
          isLoading: _isGoogleLoading,
          icon: _isPhoneMode
              ? Icons.mail_outline_rounded
              : Icons.g_mobiledata_rounded,
        ),
        if (!_isPhoneMode) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _isPhoneMode = true),
            child: Text(
              'Login with Phone Number',
              style: GoogleFonts.outfit(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ] else if (_otpSent) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _otpSent = false),
            child: Text(
              'Change Phone Number',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _primaryButton({
    required String text,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  text,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    ).animate().scale(duration: 150.ms, curve: Curves.easeOut);
  }

  Widget _secondaryButton({
    required String text,
    required VoidCallback onTap,
    required IconData icon,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'New to the hub? ',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: Text(
            'Create Identity',
            style: GoogleFonts.outfit(
              color: AppColors.solarGold,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildFooter() {
    return _footer().animate().fadeIn(delay: 600.ms);
  }

  Widget _brandRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.auto_awesome_rounded,
          color: AppColors.accent,
          size: 32,
        ),
        const SizedBox(width: 12),
        const AnimatedGradientLogo(
          text: '', // Text Removed strings strings strings (conciseness attempt)
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ],
    );
  }

  Widget _parallaxOrb({
    required double size,
    required Color color,
    required Offset offset,
    required double opacity,
  }) {
    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
    );
  }
}

class _InteractiveGridPainter extends CustomPainter {
  final double tiltX;
  final double tiltY;

  _InteractiveGridPainter(this.tiltX, this.tiltY);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const spacing = 50.0;
    final offsetX = tiltY * 30;
    final offsetY = tiltX * 30;

    for (double i = 0; i < size.width + spacing; i += spacing) {
      canvas.drawLine(
        Offset(i + offsetX, 0),
        Offset(i - offsetX, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height + spacing; i += spacing) {
      canvas.drawLine(
        Offset(0, i + offsetY),
        Offset(size.width, i - offsetY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_InteractiveGridPainter oldDelegate) =>
      oldDelegate.tiltX != tiltX || oldDelegate.tiltY != tiltY;
}
