import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';

/// -------------------------------------------------------------
/// Yemchi w Yji — Login Page (ESSAI 2 : Hero diagonal + carte blanche)
/// -------------------------------------------------------------
/// Direction artistique
/// - En‑tête "hero" diagonal orange→rouge (rappel du W)
/// - Corps sur fond clair avec **carte blanche** nette (pas de glassmorphism)
/// - Accent secondaire bleu→cyan pour les actions (rappel du Y)
/// - Inputs en mode "filled outline" sobres
/// - CTA principal bleu→cyan (contrastant), lien "Créer un compte" en accent
/// - Responsive: même structure mobile/desktop (hero + carte centrée)
///
/// Dépendances minimales : AuthController.login(idOrEmail, password)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthController>().login(
        _idCtrl.text.trim(),
        _pwdCtrl.text,
      );
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_error ?? 'Erreur inconnue')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // HERO diagonal (orange → rouge)
              const _HeroHeader(),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: isWide ? _wide() : _narrow(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _narrow() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 170),
          const _BrandLockup(centered: true),
          const SizedBox(height: 18),
          _CardForm(
            formKey: _formKey,
            idCtrl: _idCtrl,
            pwdCtrl: _pwdCtrl,
            obscure: _obscure,
            remember: _remember,
            loading: _loading,
            error: _error,
            onToggleObscure: () => setState(() => _obscure = !_obscure),
            onToggleRemember: (v) => setState(() => _remember = v),
            onSubmit: _submit,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _wide() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _BrandLockup(),
                SizedBox(height: 16),
                _Tagline(),
              ],
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _CardForm(
                formKey: _formKey,
                idCtrl: _idCtrl,
                pwdCtrl: _pwdCtrl,
                obscure: _obscure,
                remember: _remember,
                loading: _loading,
                error: _error,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onToggleRemember: (v) => setState(() => _remember = v),
                onSubmit: _submit,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: ClipPath(
        clipper: _DiagonalClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFB92C), Color(0xFFFF3D2E)], // orange → rouge
            ),
          ),
          child: Stack(
            children: [
              // Blue accent circle (echo brand)
              Positioned(
                bottom: -80,
                left: -40,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0057D6),
                        Color(0xFF18C0F9),
                      ], // bleu → cyan
                    ),
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

class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 60);
    p.quadraticBezierTo(
      size.width * .25,
      size.height,
      size.width * .5,
      size.height - 40,
    );
    p.quadraticBezierTo(
      size.width * .8,
      size.height - 90,
      size.width,
      size.height - 20,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({this.centered = false});
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final align = centered ? MainAxisAlignment.center : MainAxisAlignment.start;
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: align,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/LOGO_YEMCHI W YJI.jpg',
              height: 90,
              errorBuilder:
                  (_, __, ___) => const Icon(
                    Icons.local_shipping,
                    size: 90,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Connexion à votre compte',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
          textAlign: centered ? TextAlign.center : TextAlign.left,
        ),
      ],
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Livraison rapide, simple et fiable — pour tous.',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }
}

class _CardForm extends StatelessWidget {
  const _CardForm({
    required this.formKey,
    required this.idCtrl,
    required this.pwdCtrl,
    required this.obscure,
    required this.remember,
    required this.loading,
    required this.error,
    required this.onToggleObscure,
    required this.onToggleRemember,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController idCtrl;
  final TextEditingController pwdCtrl;
  final bool obscure;
  final bool remember;
  final bool loading;
  final String? error;
  final VoidCallback onToggleObscure;
  final ValueChanged<bool> onToggleRemember;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      shadowColor: const Color(0x1A000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF8A80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFD32F2F)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error!,
                          style: const TextStyle(color: Color(0xFFD32F2F)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              _filledField(
                context,
                controller: idCtrl,
                label: "Email ou Nom d'utilisateur",
                hint: 'ex: client@mail.com ou client01',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),
              _filledField(
                context,
                controller: pwdCtrl,
                label: 'Mot de passe',
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: obscure,
                suffix: IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                ),
                onFieldSubmitted: (_) => onSubmit(),
                validator:
                    (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: loading ? null : () {},
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _PrimaryCTA(
                onPressed: loading ? null : onSubmit,
                loading: loading,
                label: 'Se connecter',
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Sign up"),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/signup'),
                    child: const Text('Créer un compte'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filledField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF3F6FB),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF0EA5E9),
            width: 1.4,
          ), // cyan accent
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      ),
    );
  }
}

class _PrimaryCTA extends StatelessWidget {
  const _PrimaryCTA({
    required this.onPressed,
    required this.loading,
    required this.label,
  });
  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => Colors.transparent,
          ),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F6DDA), Color(0xFF18C0F9)], // bleu → cyan
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child:
                loading
                    ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
