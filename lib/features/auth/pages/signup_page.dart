import 'package:flutter/material.dart';
import '../widgets/auth_text_field.dart';

/// Inscription en 3 étapes (statique, sans backend)
/// 1) Téléphone, Date de naissance, Adresse
/// 2) Nom, Prénom, Email (+ bouton Continuer avec Google UI only)
/// 3) Mot de passe & Confirmation
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKeys = [
    GlobalKey<FormState>(), // step 0
    GlobalKey<FormState>(), // step 1
    GlobalKey<FormState>(), // step 2
  ];

  int _currentStep = 0;

  // STEP 1
  final _phone = TextEditingController();
  final _dob = TextEditingController(); // rempli via datePicker
  final _address = TextEditingController();

  // STEP 2
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();

  // STEP 3
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _dob.dispose();
    _address.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final firstDate = DateTime(now.year - 100); // limite basse 100 ans

    final date = await showDatePicker(
      context: context,
      initialDate: eighteenYearsAgo,
      firstDate: firstDate,
      lastDate: now,
    );
    if (date != null) {
      _dob.text = _formatDate(date);
      setState(() {});
    }
  }

  String _formatDate(DateTime d) {
    // JJ/MM/AAAA
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void _onContinue() {
    final key = _formKeys[_currentStep];
    if (key.currentState?.validate() != true) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _onSubmit();
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _onSubmit() {
    // Validation finale + message statique
    if (_formKeys.every((k) => k.currentState?.validate() == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte créé (statique). Vous pouvez vous connecter.')),
      );
      Navigator.pop(context); // retour vers /login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;

          return Stack(
            children: [
              const _HeroHeader(),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: Colors.white,
                      tooltip: 'Retour',
                      onPressed: _onBack,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: isWide ? _wideLayout() : _narrowLayout(bottomInset),
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

  Widget _narrowLayout(double bottomInset) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 170),
          const _BrandLockup(centered: true, subtitle: 'Rejoignez Yemchi w Yji'),
          const SizedBox(height: 18),
          _buildCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _BrandLockup(subtitle: 'Créez votre accès coursier'),
                SizedBox(height: 16),
                _SignupHighlights(),
              ],
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: _buildCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Card(
      elevation: 10,
      shadowColor: const Color(0x1A000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(currentStep: _currentStep),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: _buildStepContent(_currentStep),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _onBack,
                  child: Text(_currentStep == 0 ? 'Annuler' : 'Retour'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PrimaryCTA(
                    onPressed: _onContinue,
                    loading: false,
                    label: _currentStep == 2 ? 'Terminer' : 'Continuer',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Déjà un compte ?'),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return Form(
          key: _formKeys[0],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _phone,
                label: 'Numéro de téléphone',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                hintText: 'Ex: +216 12 345 678',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Numéro obligatoire';
                  if (v.replaceAll(' ', '').length < 8) return 'Numéro invalide';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dob,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date de naissance',
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixIcon: IconButton(
                    onPressed: _pickDob,
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Date de naissance obligatoire' : null,
                onTap: _pickDob,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _address,
                label: 'Adresse',
                prefixIcon: Icons.home_outlined,
                hintText: 'Rue, ville, code postal',
                validator: (v) =>
                    (v == null || v.length < 5) ? 'Adresse trop courte' : null,
                maxLines: 2,
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _formKeys[1],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      controller: _lastName,
                      label: 'Nom',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obligatoire' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthTextField(
                      controller: _firstName,
                      label: 'Prénom',
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obligatoire' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email obligatoire';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Google Sign-In (UI only)')),
                  );
                },
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Continuer avec Google'),
              ),
            ],
          ),
        );
      case 2:
      default:
        return Form(
          key: _formKeys[2],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthPasswordField(
                controller: _password,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 caractères' : null,
                helperText: 'Utilisez au moins 6 caractères',
              ),
              const SizedBox(height: 14),
              AuthPasswordField(
                controller: _confirmPassword,
                label: 'Confirmer le mot de passe',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obligatoire';
                  if (v != _password.text) return 'Les mots de passe ne correspondent pas';
                  return null;
                },
              ),
            ],
          ),
        );
    }
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
              colors: [Color(0xFFFFB92C), Color(0xFFFF3D2E)],
            ),
          ),
          child: Stack(
            children: [
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
                      colors: [Color(0xFF0057D6), Color(0xFF18C0F9)],
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
        size.width * .25, size.height, size.width * .5, size.height - 40);
    p.quadraticBezierTo(
        size.width * .8, size.height - 90, size.width, size.height - 20);
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({this.centered = false, required this.subtitle});

  final bool centered;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final align = centered ? MainAxisAlignment.center : MainAxisAlignment.start;
    final cross =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: align,
          children: [
            Image.asset(
              'assets/images/LOGO_YEMCHI W YJI.jpg',
              height: 90,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.local_shipping, size: 90, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              'Yemchi w Yji',
              style: TextStyle(
                color: Colors.white.withOpacity(0.92),
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w600,
          ),
          textAlign: centered ? TextAlign.center : TextAlign.left,
        ),
      ],
    );
  }
}

class _SignupHighlights extends StatelessWidget {
  const _SignupHighlights();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Gérez vos courses en temps réel', style: style),
        SizedBox(height: 8),
        Text('Recevez plus de missions selon votre zone', style: style),
        SizedBox(height: 8),
        Text('Paiements rapides et sécurisés', style: style),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const titles = ['Informations', 'Profil', 'Sécurité'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étape ${currentStep + 1} sur ${titles.length}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (currentStep + 1) / titles.length,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF18C0F9)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(titles.length, (index) {
            final isActive = index == currentStep;
            final isDone = index < currentStep;
            final bgColor = isDone
                ? const Color(0xFF0F6DDA)
                : isActive
                    ? const Color(0xFF18C0F9)
                    : const Color(0xFFE2E8F0);
            final iconColor =
                isDone || isActive ? Colors.white : const Color(0xFF94A3B8);

            final icon = [
              Icons.phone_outlined,
              Icons.person_outline,
              Icons.lock_outline
            ][index];

            return Expanded(
              child: Column(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    titles[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isDone || isActive
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
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
        onPressed: loading ? null : onPressed,
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          backgroundColor:
              WidgetStateProperty.resolveWith((states) => Colors.transparent),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F6DDA), Color(0xFF18C0F9)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: loading
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
