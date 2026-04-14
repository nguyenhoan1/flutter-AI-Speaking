import 'dart:math';

import 'package:bloc_clean_architecture/src/comman/enum.dart';
import 'package:bloc_clean_architecture/src/comman/routes.dart';
import 'package:bloc_clean_architecture/src/comman/toast.dart';
import 'package:bloc_clean_architecture/src/presentation/bloc/sign_in_form/sign_in_form_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _particleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideFromBottom;
  late Animation<Offset> _slideFromBottomDelayed;
  late Animation<double> _buttonFadeAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideFromBottom = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideFromBottomDelayed = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _buttonFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.4, 1, curve: Curves.easeOut),
      ),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _particleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignInFormBloc, SignInFormState>(
      listener: (context, state) {
        if (state.state == RequestState.loaded) {
          context.replaceNamed(AppRoutes.DASHBOARD_ROUTE_NAME);
        }
        if (state.state == RequestState.error) {
          showToast(
            msg: state.message,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              // Background gradient
              _buildBackground(),

              // Floating particles
              _buildParticles(),

              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          _buildHeader(),
                          const SizedBox(height: 48),
                          _buildLoginForm(state),
                          const SizedBox(height: 24),
                          _buildForgotPassword(),
                          const SizedBox(height: 32),
                          _buildSignInButton(state),
                          const SizedBox(height: 36),
                          _buildDivider(),
                          const SizedBox(height: 24),
                          _buildSocialButtons(),
                          const SizedBox(height: 32),
                          _buildRegisterLink(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A2E),
            Color(0xFF0D1B3E),
            Color(0xFF0A0A2E),
            Color(0xFF050515),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _LoginParticlePainter(
            progress: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideFromBottom,
        child: Column(
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A6CF7).withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Welcome Back',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Sign in to continue your speaking journey',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF8DA4EF),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(SignInFormState state) {
    return SlideTransition(
      position: _slideFromBottomDelayed,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email field
              _buildGlassTextField(
                controller: _emailController,
                hintText: 'Email address',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) {
                  context
                      .read<SignInFormBloc>()
                      .add(SignInFormEvent.emailOnChanged(v));
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password field
              _buildGlassTextField(
                controller: _passwordController,
                hintText: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscureText,
                onChanged: (v) {
                  context
                      .read<SignInFormBloc>()
                      .add(SignInFormEvent.passwordOnChanged(v));
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  child: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF6B7DB3),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A3A6A).withValues(alpha: 0.6),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A2550).withValues(alpha: 0.8),
            const Color(0xFF0F1835).withValues(alpha: 0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: const Color(0xFF4A6CF7),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF4A5580),
            fontSize: 15,
            fontWeight: FontWeight.w300,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, color: const Color(0xFF4A6CF7), size: 22),
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: suffixIcon,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          errorStyle: GoogleFonts.poppins(
            color: const Color(0xFFFF6B6B),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return FadeTransition(
      opacity: _buttonFadeAnimation,
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () {},
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.poppins(
              color: const Color(0xFF4A6CF7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(SignInFormState state) {
    final isLoading = state.state == RequestState.loading;

    return FadeTransition(
      opacity: _buttonFadeAnimation,
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  context
                      .read<SignInFormBloc>()
                      .add(const SignInFormEvent.signInWithEmail());
                }
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLoading
                  ? [
                      const Color(0xFF3A5BD4).withValues(alpha: 0.6),
                      const Color(0xFF2A8AF6).withValues(alpha: 0.6),
                    ]
                  : [
                      const Color(0xFF4A6CF7),
                      const Color(0xFF2A8AF6),
                      const Color(0xFF00C6FF),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A6CF7).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Signing in...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Sign In',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return FadeTransition(
      opacity: _buttonFadeAnimation,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF2A3A6A).withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'or continue with',
              style: GoogleFonts.poppins(
                color: const Color(0xFF4A5580),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2A3A6A).withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButtons() {
    return FadeTransition(
      opacity: _buttonFadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSocialButton(
            icon: FontAwesomeIcons.google,
            label: 'Google',
            color: const Color(0xFFDB4437),
            onTap: () {},
          ),
          const SizedBox(width: 16),
          _buildSocialButton(
            icon: FontAwesomeIcons.apple,
            label: 'Apple',
            color: Colors.white,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF2A3A6A).withValues(alpha: 0.5),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A2550).withValues(alpha: 0.6),
              const Color(0xFF0F1835).withValues(alpha: 0.4),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return FadeTransition(
      opacity: _buttonFadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7DB3),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          GestureDetector(
            onTap: () {
              context.replaceNamed(AppRoutes.SIGNUP_ROUTE_NAME);
            },
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [Color(0xFF4A6CF7), Color(0xFF00C6FF)],
                ).createShader(bounds);
              },
              child: Text(
                'Sign Up',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Particle Painter for login screen floating particles
class _LoginParticlePainter extends CustomPainter {

  _LoginParticlePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(99);

    for (var i = 0; i < 20; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.2 + random.nextDouble() * 0.5;
      final particleSize = 1.0 + random.nextDouble() * 2.0;

      final animatedY = (baseY - progress * size.height * speed) % size.height;
      final animatedX = baseX + sin((progress * 2 * pi) + i) * 15;

      final distFromCenter = (animatedY / size.height - 0.5).abs();
      final opacity = (1.0 - distFromCenter * 2).clamp(0.0, 0.4);

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFF4A6CF7),
          const Color(0xFF00D2FF),
          random.nextDouble(),
        )!
            .withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(animatedX, animatedY), particleSize, paint);

      if (i % 4 == 0) {
        final glowPaint = Paint()
          ..color = const Color(0xFF4A6CF7).withValues(alpha: opacity * 0.1)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawCircle(
            Offset(animatedX, animatedY), particleSize * 3, glowPaint,);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoginParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
