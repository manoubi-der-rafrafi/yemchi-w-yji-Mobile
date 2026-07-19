import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand palette — single source of truth
// ─────────────────────────────────────────────────────────────────────────────
class AuthColors {
  // Header gradient
  static const headerStart = Color(0xFFFFA726);
  static const headerEnd = Color(0xFFFF5722);
  // Button gradient
  static const btnStart = Color(0xFF0D47A1);
  static const btnEnd = Color(0xFF29B6F6);
  // Text
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  // Surfaces
  static const cardBg = Color(0xFFFFFFFF);
  static const fieldBg = Color(0xFFF7F8FA);
  // States
  static const error = Color(0xFFE53935);
  static const success = Color(0xFF2E7D32);
  // Field
  static const fieldBorder = Color(0xFFE2E5EA);
  static const fieldFocusBorder = Color(0xFF1565C0);
  static const iconRest = Color(0xFF9AA0A6);
  static const iconFocus = Color(0xFF1565C0);
  // Badge
  static const badgeText = Color(0xFFD9480F);
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero header — decorations clipped INSIDE the header only
// ─────────────────────────────────────────────────────────────────────────────
class AuthHeroHeader extends StatelessWidget {
  const AuthHeroHeader({super.key, this.heightFactor = 0.30});

  /// Fraction of screen height (0.30 = 30%)
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * heightFactor;
    return SizedBox(
      height: h,
      width: double.infinity,
      // ClipPath here ensures NOTHING overflows outside the wave shape
      child: ClipPath(
        clipper: _WaveClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AuthColors.headerStart, AuthColors.headerEnd],
            ),
          ),
          // All decorative blobs are children of this clipped container,
          // so they are automatically cut off at the wave boundary.
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                bottom: -60,
                left: -50,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0D47A1).withValues(alpha: 0.7),
                        const Color(0xFF29B6F6).withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: -28,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 50);
    p.cubicTo(
      size.width * 0.15,
      size.height + 10,
      size.width * 0.40,
      size.height - 70,
      size.width * 0.60,
      size.height - 30,
    );
    p.cubicTo(
      size.width * 0.80,
      size.height + 10,
      size.width * 0.90,
      size.height - 50,
      size.width,
      size.height - 20,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand lockup — logo + title + badge
// ─────────────────────────────────────────────────────────────────────────────
// Brand lockup — vertical centered layout: Logo → Name → Badge → Subtitle
class AuthBrandLockup extends StatelessWidget {
  const AuthBrandLockup({
    super.key,
    this.centered = false,
    this.subtitle,
    this.showDeliveryBadge = true,
  });

  final bool centered;
  final String? subtitle;
  final bool showDeliveryBadge;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Logo — largest element, app-icon style
        Container(
          width: 88,
          height: 88,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo_yemchi_w_yji.jpg',
            fit: BoxFit.contain,
            errorBuilder:
                (_, __, ___) => const Icon(
                  Icons.local_shipping_outlined,
                  size: 52,
                  color: AuthColors.headerEnd,
                ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Brand name — dominant text
        const Text(
          'Yemchi w Yji',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            shadows: [
              Shadow(
                color: Color(0x26000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        // 3. Badge — secondary, kept at same size as before
        if (showDeliveryBadge) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
        ],

        // 4. Subtitle — smallest, most discreet
        if (subtitle != null) ...[
          const SizedBox(height: 14),
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
              fontSize: 14,
              shadows: const [Shadow(color: Color(0x1A000000), blurRadius: 4)],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient CTA button — press scale + loading + disabled
// ─────────────────────────────────────────────────────────────────────────────
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;
    return ScaleTransition(
      scale: _press,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => _press.reverse(),
        onTapUp: disabled ? null : (_) => _press.forward(),
        onTapCancel: disabled ? null : () => _press.forward(),
        child: SizedBox(
          height: 52,
          child: Material(
            borderRadius: BorderRadius.circular(14),
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient:
                    disabled
                        ? const LinearGradient(
                          colors: [Color(0xFFCDD5E0), Color(0xFFB0BAC9)],
                        )
                        : const LinearGradient(
                          colors: [AuthColors.btnStart, AuthColors.btnEnd],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                boxShadow:
                    disabled
                        ? []
                        : [
                          BoxShadow(
                            color: AuthColors.btnStart.withValues(alpha: 0.32),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: disabled ? null : widget.onPressed,
                child: Center(
                  child:
                      widget.loading
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            widget.label,
                            style: TextStyle(
                              color:
                                  disabled
                                      ? const Color(0xFF8896AB)
                                      : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google Sign-In button — official style, untouched per spec
// ─────────────────────────────────────────────────────────────────────────────
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDDE3EE), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _GoogleGPainter()),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continuer avec Google',
              style: TextStyle(
                color: Color(0xFF3C4043),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    void arc(double s, double sw, Color c) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.72),
        s,
        sw,
        false,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.22
          ..strokeCap = StrokeCap.butt,
      );
    }

    const pi = 3.14159265;
    arc(-0.25 * pi, 0.85 * pi, const Color(0xFF4285F4));
    arc(0.60 * pi, 0.50 * pi, const Color(0xFF34A853));
    arc(1.10 * pi, 0.55 * pi, const Color(0xFFFBBC05));
    arc(1.65 * pi, 0.65 * pi, const Color(0xFFEA4335));
    canvas.drawLine(
      Offset(r, r - size.width * 0.01),
      Offset(size.width * 0.94, r - size.width * 0.01),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.square,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
