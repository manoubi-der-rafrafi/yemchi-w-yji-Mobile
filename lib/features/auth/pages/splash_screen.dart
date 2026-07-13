import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/utilisateur.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_hero.dart'; // AuthColors

// ─────────────────────────────────────────────────────────────────────────────
// Flutter Splash Screen
// Shown after the native launch screen while the app initializes.
// Runs auth check + enforces a 1200ms minimum display time.
// ─────────────────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _nameCtrl;
  late final AnimationController _badgeCtrl;
  late final AnimationController _exitCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _badgeOpacity;
  late final Animation<double> _exitOpacity;

  static const _minDisplay = Duration(milliseconds: 1200);
  static const _maxDisplay = Duration(milliseconds: 5000);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runInit();
  }

  void _setupAnimations() {
    // Logo: fade-in + scale 0.85 → 1.0, 600ms
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut),
    );

    // Name: fade-in + slide-up 10px, starts 200ms after logo
    _nameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOut),
    );
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.3), // ~10px at normal font size
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOut));

    // Badge: fade-in, starts 350ms after logo
    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _badgeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOut),
    );

    // Exit: fade-out for transition
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    // Start staggered entry animations
    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _nameCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _badgeCtrl.forward();
    });
  }

  Future<void> _runInit() async {
    final stopwatch = Stopwatch()..start();

    // Run auth check in parallel with minimum display timer
    final auth = context.read<AuthController>();
    await Future.wait([
      auth.loadMeIfToken(),
      Future.delayed(_minDisplay),
    ]).timeout(_maxDisplay, onTimeout: () => [null, null]);

    stopwatch.stop();
    if (!mounted) return;

    // Fade-out transition
    await _exitCtrl.forward();
    if (!mounted) return;

    // Navigate based on auth state
    final user = auth.currentUser.value;
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else if (user.role == Role.transporteur) {
      Navigator.of(context).pushReplacementNamed('/home_coursier');
    } else {
      Navigator.of(context).pushReplacementNamed('/home_client');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _nameCtrl.dispose();
    _badgeCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitOpacity,
      builder: (_, child) => Opacity(
        opacity: _exitOpacity.value,
        child: child,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // ── Gradient background ────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AuthColors.headerStart, AuthColors.headerEnd],
                ),
              ),
            ),

            // ── Decorative blob — bottom left, vivid brand blue ────────
            Positioned(
              bottom: -80,
              left: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0D47A1).withValues(alpha: 0.75),
                      const Color(0xFF1565C0).withValues(alpha: 0.70),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // ── Decorative bubble — top right ──────────────────────────
            Positioned(
              top: -20,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),

            // ── Main content: logo + name + badge ─────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _logoCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 24,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/LOGO_YEMCHI W YJI.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.local_shipping_outlined,
                          size: 64,
                          color: AuthColors.headerEnd,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Brand name
                  AnimatedBuilder(
                    animation: _nameCtrl,
                    builder: (_, child) => FadeTransition(
                      opacity: _nameOpacity,
                      child: SlideTransition(
                        position: _nameSlide,
                        child: child,
                      ),
                    ),
                    child: const Text(
                      'Yemchi w Yji',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            color: Color(0x26000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Badge
                  FadeTransition(
                    opacity: _badgeOpacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 13,
                            color: AuthColors.badgeText,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Espace Livreur',
                            style: TextStyle(
                              color: AuthColors.badgeText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Loading indicator — bottom center ─────────────────────
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _badgeOpacity, // reuse same delayed fade
                child: Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chargement de votre espace...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
