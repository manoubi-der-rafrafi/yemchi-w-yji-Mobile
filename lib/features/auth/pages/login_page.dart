import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_text_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Login Page — Yemchi w Yji (Espace Livreur)
// ─────────────────────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  // Stagger animation for card fields
  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _staggerAnims;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _staggerAnims = List.generate(4, (i) {
      final start = i * 0.15;
      return CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(start, (start + 0.5).clamp(0, 1), curve: Curves.easeOut),
      );
    });
    // Slight delay so hero finishes painting first
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _staggerCtrl.forward();
    });
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final auth = context.read<AuthController>();
      final ok = await auth.login(_emailCtrl.text.trim(), _pwdCtrl.text);
      if (!mounted) return;
      if (!ok) {
        setState(() => _errorMsg = auth.error.value ?? 'Email ou mot de passe incorrect');
        HapticFeedback.heavyImpact();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.cardBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return Stack(
              children: [
                const AuthHeroHeader(),
                SafeArea(child: _wideLayout()),
              ],
            );
          }
          // Narrow: full screen column, no SafeArea wrapping the whole thing
          // so the gradient extends under the status bar naturally
          return _narrowLayout();
        },
      ),
    );
  }

  Widget _narrowLayout() {
    final screenH = MediaQuery.of(context).size.height;
    final headerH = screenH * 0.35;

    return Column(
      children: [
        // ── Gradient header — contains the wave + brand lockup ──────
        SizedBox(
          height: headerH,
          width: double.infinity,
          child: ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFA726),
                    Color(0xFFFF5722),
                  ],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Blue decorative blob — vivid brand blue, clipped inside wave
                  Positioned(
                    bottom: -55,
                    left: -45,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0D47A1).withValues(alpha: 0.80),
                            const Color(0xFF1565C0).withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  // Small white bubble — top right
                  Positioned(
                    top: 10,
                    right: -24,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  // Brand lockup centred in the header
                  SafeArea(
                    bottom: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const AuthBrandLockup(
                          centered: true,
                          subtitle: 'Connectez-vous à votre espace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── White card fills all remaining space ────────────────────
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AuthColors.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 28,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: _buildFormContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AuthBrandLockup(subtitle: 'Gérez vos courses en temps réel'),
                SizedBox(height: 20),
                _Highlights(),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildCard() {
    return Card(
      elevation: 16,
      shadowColor: const Color(0x1A0D47A1),
      color: AuthColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: _buildFormContent(),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card title — no emoji
          _FadeSlide(
            animation: _staggerAnims[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AuthColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bon retour parmi nous',
                  style: TextStyle(
                    fontSize: 14,
                    color: AuthColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          if (_errorMsg != null) ...[
            _FadeSlide(
              animation: _staggerAnims[0],
              child: _ErrorBanner(message: _errorMsg!),
            ),
            const SizedBox(height: 14),
          ],

          _FadeSlide(
            animation: _staggerAnims[1],
            child: AuthTextField(
              controller: _emailCtrl,
              label: 'Email',
              hintText: 'votre@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email requis';
                if (!v.contains('@')) return 'Email invalide';
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          _FadeSlide(
            animation: _staggerAnims[2],
            child: AuthPasswordField(
              controller: _pwdCtrl,
              label: 'Mot de passe',
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
              onSubmitted: (_) => _submit(),
            ),
          ),

          _FadeSlide(
            animation: _staggerAnims[2],
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading ? null : () {},
                child: const Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(
                      fontSize: 13, color: AuthColors.fieldFocusBorder),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          _FadeSlide(
            animation: _staggerAnims[3],
            child: GradientButton(
              label: 'Se connecter',
              loading: _loading,
              onPressed: _loading ? null : _submit,
            ),
          ),
          const SizedBox(height: 16),

          _FadeSlide(
            animation: _staggerAnims[3],
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _FadeSlide(
            animation: _staggerAnims[3],
            child: GoogleSignInButton(
              onPressed: _loading
                  ? null
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Google Sign-In — bientôt disponible')),
                      ),
            ),
          ),
          const SizedBox(height: 20),

          _FadeSlide(
            animation: _staggerAnims[3],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Pas encore de compte ?',
                    style: TextStyle(
                        color: AuthColors.textSecondary, fontSize: 13)),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pushNamed('/signup'),
                  style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8)),
                  child: const Text(
                    "S'inscrire",
                    style: TextStyle(
                      color: AuthColors.fieldFocusBorder,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wave clipper (same curve as AuthHeroHeader)
// ─────────────────────────────────────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 50);
    p.cubicTo(
      size.width * 0.15, size.height + 10,
      size.width * 0.40, size.height - 70,
      size.width * 0.60, size.height - 30,
    );
    p.cubicTo(
      size.width * 0.80, size.height + 10,
      size.width * 0.90, size.height - 50,
      size.width,        size.height - 20,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _FadeSlide extends StatelessWidget {
  const _FadeSlide({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights();
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.bolt_rounded, 'Courses assignées en temps réel'),
      (Icons.map_rounded, 'Suivi GPS intégré'),
      (Icons.payments_rounded, 'Paiements rapides et traçables'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(e.$1, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              e.$2,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
