import 'dart:math';

import 'package:bloc_clean_architecture/src/comman/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Text animation controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0, 0.6, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Pulse animation for the glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  void _startAnimationSequence() {
    _logoController.forward();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });

    // Navigate to login after splash animations
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.replaceNamed(AppRoutes.LOGIN_ROUTE_NAME);
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _buildGradientBackground(),

          // Floating particles
          _buildParticles(),

          // Main content
          _buildMainContent(context),

          // Bottom loading indicator
          _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.2,
              colors: [
                const Color(0xFF1A1A4E).withValues(alpha: _pulseAnimation.value),
                const Color(0xFF0D0D2B),
                const Color(0xFF050515),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            progress: _particleController.value,
            particleCount: 30,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Logo with glow effect
          AnimatedBuilder(
            animation: Listenable.merge([_logoController, _pulseController]),
            builder: (context, child) {
              return Transform.scale(
                scale: _logoScale.value,
                child: Opacity(
                  opacity: _logoOpacity.value,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A6CF7)
                              .withValues(alpha: 0.4 * _pulseAnimation.value),
                          blurRadius: 40 * _pulseAnimation.value,
                          spreadRadius: 5 * _pulseAnimation.value,
                        ),
                        BoxShadow(
                          color: const Color(0xFF00D2FF)
                              .withValues(alpha: 0.2 * _pulseAnimation.value),
                          blurRadius: 60 * _pulseAnimation.value,
                          spreadRadius: 10 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // App Title with shimmer
          SlideTransition(
            position: _textSlide,
            child: FadeTransition(
              opacity: _textOpacity,
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: const [
                          Colors.white,
                          Color(0xFF00D2FF),
                          Colors.white,
                        ],
                        stops: [
                          (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                          _shimmerAnimation.value.clamp(0.0, 1.0),
                          (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                        ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'AI Speaking',
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 3,
                        height: 1.2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SlideTransition(
            position: _textSlide,
            child: FadeTransition(
              opacity: _textOpacity,
              child: Text(
                'Your Smart Voice Coach',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF4A6CF7),
                  letterSpacing: 3,
                  height: 1.1,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          SlideTransition(
            position: _subtitleSlide,
            child: FadeTransition(
              opacity: _subtitleOpacity,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4A6CF7).withValues(alpha: 0.3),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4A6CF7).withValues(alpha: 0.1),
                      const Color(0xFF00D2FF).withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Text(
                  '✨ Powered by AI',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8DA4EF),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _subtitleOpacity,
        child: Column(
          children: [
            // Custom animated loading dots
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final progress =
                        (_particleController.value + delay) % 1.0;
                    final scale = 0.5 + 0.5 * sin(progress * pi);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          const Color(0xFF4A6CF7),
                          const Color(0xFF00D2FF),
                          scale,
                        )?.withValues(alpha: 0.5 + 0.5 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A6CF7)
                                .withValues(alpha: 0.3 * scale),
                            blurRadius: 6 * scale,
                            spreadRadius: 1 * scale,
                          ),
                        ],
                      ),
                    );
                  }),
                );
              },
            ),

            const SizedBox(height: 20),

            Text(
              'Preparing your practice session...',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Particle Painter for floating particles effect
class ParticlePainter extends CustomPainter {

  ParticlePainter({required this.progress, required this.particleCount});
  final double progress;
  final int particleCount;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Fixed seed for consistent particles

    for (var i = 0; i < particleCount; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.3 + random.nextDouble() * 0.7;
      final particleSize = 1.0 + random.nextDouble() * 2.5;

      // Calculate animated position
      final animatedY =
          (baseY - progress * size.height * speed) % size.height;
      final animatedX =
          baseX + sin((progress * 2 * pi) + i) * 20;

      // Calculate opacity based on position (fade at edges)
      final distFromCenter = (animatedY / size.height - 0.5).abs();
      final opacity = (1.0 - distFromCenter * 2).clamp(0.0, 0.6);

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFF4A6CF7),
          const Color(0xFF00D2FF),
          random.nextDouble(),
        )!
            .withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(animatedX, animatedY),
        particleSize,
        paint,
      );

      // Add glow to some particles
      if (i % 3 == 0) {
        final glowPaint = Paint()
          ..color = const Color(0xFF4A6CF7).withValues(alpha: opacity * 0.15)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawCircle(
          Offset(animatedX, animatedY),
          particleSize * 3,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
