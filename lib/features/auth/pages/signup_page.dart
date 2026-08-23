import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/models/utilisateur.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_text_field.dart';

bool _isStrongPassword(String value) =>
    value.length >= 8 &&
    value.length <= 128 &&
    RegExp(r'[a-z]').hasMatch(value) &&
    RegExp(r'[A-Z]').hasMatch(value) &&
    RegExp(r'\d').hasMatch(value);

// ─────────────────────────────────────────────────────────────────────────────
// Signup Page — 3 steps with animated stepper + slide transitions
// ─────────────────────────────────────────────────────────────────────────────
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  int _step = 0;
  bool _isLoading = false;
  bool _termsAccepted = false;
  String? _signupToken;

  // Step 0
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  final _address = TextEditingController();

  // Step 1
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();

  // Step 2
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  // Slide animation between steps
  late final AnimationController _slideCtrl;
  late Animation<Offset> _slideIn;
  late Animation<Offset> _slideOut;
  bool _goingForward = true;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..value = 1.0;
    _updateSlideAnims();
  }

  void _updateSlideAnims() {
    final dir = _goingForward ? 1.0 : -1.0;
    _slideIn = Tween<Offset>(
      begin: Offset(dir, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-dir, 0),
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn));
  }

  Future<void> _goTo(int next) async {
    _goingForward = next > _step;
    _updateSlideAnims();
    _slideCtrl.value = 0;
    setState(() => _step = next);
    await _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    for (final c in [
      _phone,
      _dob,
      _address,
      _firstName,
      _lastName,
      _email,
      _password,
      _confirmPassword,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_formKeys[_step].currentState?.validate() != true) {
      HapticFeedback.mediumImpact();
      return;
    }
    if (_step == 1) {
      setState(() => _isLoading = true);
      try {
        _signupToken = await context.read<AuthController>().initiateSignup(
          _email.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email envoyé. Cliquez sur le lien avant de terminer.',
            ),
          ),
        );
        await _goTo(2);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_step < 2) {
      _goTo(_step + 1);
    } else {
      _onSubmit();
    }
  }

  void _onBack() {
    if (_isLoading) return;
    if (_step > 0) {
      _goTo(_step - 1);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _onSubmit() async {
    if (_formKeys[2].currentState?.validate() != true) {
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() => _isLoading = true);

    final dobParts = _dob.text.split('/');
    final dateNaissance =
        dobParts.length == 3
            ? '${dobParts[2]}-${dobParts[1]}-${dobParts[0]}'
            : _dob.text;

    final auth = context.read<AuthController>();
    if (_signupToken == null ||
        !await auth.isEmailVerified(_email.text.trim(), _signupToken!)) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'email n'est pas encore vérifié.")),
      );
      return;
    }
    final success = await auth.register(
      email: _email.text.trim(),
      password: _password.text,
      nom: _lastName.text.trim(),
      prenom: _firstName.text.trim(),
      telephone: _phone.text.trim(),
      adresse: _address.text.trim(),
      dateNaissance: dateNaissance,
      signupToken: _signupToken!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      HapticFeedback.lightImpact();
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _SuccessDialog(name: _firstName.text.trim()),
      );
      if (!mounted) return;
      final role = auth.currentUser.value?.role;
      Navigator.of(context).pushReplacementNamed(
        role == Role.transporteur ? '/home_coursier' : '/home_client',
      );
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(auth.error.value ?? "Erreur lors de l'inscription"),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final defaultYear = now.year - 18;

    // Start controllers at 18 years ago
    DateTime _selected = DateTime(defaultYear, now.month, now.day);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder:
          (ctx) => _DobPickerSheet(
            initialDate: _selected,
            onConfirm: (date) {
              _dob.text =
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
              setState(() {});
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: Stack(
        children: [
          const AuthHeroHeader(heightFactor: 0.28),
          SafeArea(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return isWide ? _wideLayout() : _narrowLayout();
              },
            ),
          ),

          // Back button floating over hero
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.white,
                tooltip: 'Retour',
                onPressed: _onBack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _narrowLayout() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const AuthBrandLockup(
            centered: true,
            subtitle: 'Créez votre compte livreur',
          ),
          const SizedBox(height: 20),
          _buildCard(),
        ],
      ),
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
                AuthBrandLockup(subtitle: 'Rejoignez notre réseau de livreurs'),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
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
      shadowColor: const Color(0x1A0F6DDA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Animated stepper
            _AnimatedStepper(currentStep: _step),
            const SizedBox(height: 24),

            // Step content with slide transition
            ClipRect(
              child: SlideTransition(
                position: _slideIn,
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStepContent(_step),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Navigation buttons
            Row(
              children: [
                _SecondaryButton(
                  label: _step == 0 ? 'Annuler' : 'Retour',
                  onPressed: _isLoading ? null : _onBack,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    label: _step == 2 ? 'Terminer' : 'Continuer',
                    loading: _isLoading,
                    onPressed: _isLoading ? null : _onContinue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Déjà un compte ?',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(
                      color: Color(0xFF0F6DDA),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
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
            children: [
              AuthTextField(
                controller: _phone,
                label: 'Numéro de téléphone',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                hintText: '+216 12 345 678',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Numéro obligatoire';
                  if (v.replaceAll(' ', '').length < 8)
                    return 'Numéro invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Date de naissance — taps into custom drum picker
              GestureDetector(
                onTap: _pickDob,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dob,
                    readOnly: true,
                    validator:
                        (v) =>
                            (v == null || v.isEmpty)
                                ? 'Date de naissance obligatoire'
                                : null,
                    decoration: InputDecoration(
                      labelText: 'Date de naissance',
                      hintText: 'JJ/MM/AAAA',
                      prefixIcon: const Icon(
                        Icons.cake_outlined,
                        color: Color(0xFF9AA0A6),
                        size: 20,
                      ),
                      suffixIcon: const Icon(
                        Icons.expand_more_rounded,
                        color: Color(0xFF9AA0A6),
                        size: 22,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FA),
                      constraints: const BoxConstraints(minHeight: 52),
                      labelStyle: const TextStyle(
                        color: Color(0xFF9AA0A6),
                        fontSize: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E5EA),
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1565C0),
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE53935),
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE53935),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _address,
                label: 'Adresse',
                prefixIcon: Icons.home_outlined,
                hintText: 'Rue, ville, code postal',
                maxLines: 2,
                validator:
                    (v) =>
                        (v == null || v.length < 5)
                            ? 'Adresse trop courte'
                            : null,
              ),
            ],
          ),
        );

      case 1:
        return Form(
          key: _formKeys[1],
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      controller: _lastName,
                      label: 'Nom',
                      prefixIcon: Icons.badge_outlined,
                      validator:
                          (v) =>
                              (v == null || v.isEmpty) ? 'Obligatoire' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthTextField(
                      controller: _firstName,
                      label: 'Prénom',
                      prefixIcon: Icons.person_outline,
                      validator:
                          (v) =>
                              (v == null || v.isEmpty) ? 'Obligatoire' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                hintText: 'votre@email.com',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email obligatoire';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GoogleSignInButton(
                onPressed:
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google Sign-In — bientôt disponible'),
                      ),
                    ),
              ),
            ],
          ),
        );

      case 2:
      default:
        return Form(
          key: _formKeys[2],
          child: Column(
            children: [
              AuthPasswordField(
                controller: _password,
                showStrength: true,
                validator:
                    (v) =>
                        (v == null || !_isStrongPassword(v))
                            ? '8 à 128 caractères, avec majuscule, minuscule et chiffre'
                            : null,
              ),
              const SizedBox(height: 16),
              AuthPasswordField(
                controller: _confirmPassword,
                label: 'Confirmer le mot de passe',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obligatoire';
                  if (v != _password.text)
                    return 'Les mots de passe ne correspondent pas';
                  return null;
                },
              ),
            ],
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Stepper
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedStepper extends StatelessWidget {
  const _AnimatedStepper({required this.currentStep});
  final int currentStep;

  static const _steps = [
    (Icons.phone_outlined, 'Infos'),
    (Icons.person_outline, 'Profil'),
    (Icons.lock_outline, 'Sécurité'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step name with animated text switch
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder:
              (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
          child: Text(
            _steps[currentStep].$2,
            key: ValueKey(currentStep),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2033),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Étape ${currentStep + 1} sur ${_steps.length}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF8896AB)),
        ),
        const SizedBox(height: 14),

        // Animated progress bar
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (currentStep + 1) / _steps.length),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          builder:
              (_, v, __) => Stack(
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F6DDA), Color(0xFF18C0F9)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        ),
        const SizedBox(height: 16),

        // Step icons
        Row(
          children: List.generate(_steps.length, (i) {
            final isDone = i < currentStep;
            final isActive = i == currentStep;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: isActive ? 1.1 : 1.0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          builder:
                              (_, scale, child) =>
                                  Transform.scale(scale: scale, child: child),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient:
                                  (isDone || isActive)
                                      ? const LinearGradient(
                                        colors: [
                                          Color(0xFF0F6DDA),
                                          Color(0xFF18C0F9),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                      : null,
                              color:
                                  (isDone || isActive)
                                      ? null
                                      : const Color(0xFFEDF1F7),
                              boxShadow:
                                  isActive
                                      ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF0F6DDA,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                      : [],
                            ),
                            child: Icon(
                              isDone ? Icons.check_rounded : _steps[i].$1,
                              color:
                                  (isDone || isActive)
                                      ? Colors.white
                                      : const Color(0xFFAAB4C8),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _steps[i].$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isActive
                                    ? const Color(0xFF0F6DDA)
                                    : isDone
                                    ? const Color(0xFF1A2033)
                                    : const Color(0xFFAAB4C8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Connector line between steps
                  if (i < _steps.length - 1)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient:
                              isDone
                                  ? const LinearGradient(
                                    colors: [
                                      Color(0xFF0F6DDA),
                                      Color(0xFF18C0F9),
                                    ],
                                  )
                                  : null,
                          color: isDone ? null : const Color(0xFFE2E8F0),
                        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Secondary (outline) button
// ─────────────────────────────────────────────────────────────────────────────
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDDE3EE), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: const Color(0xFF4A5568),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success dialog
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Custom DOB Drum Picker — 3 scroll columns: Jour / Mois / Année
// Opens directly at initialDate, no scrolling through years required.
// ─────────────────────────────────────────────────────────────────────────────
class _DobPickerSheet extends StatefulWidget {
  const _DobPickerSheet({required this.initialDate, required this.onConfirm});

  final DateTime initialDate;
  final ValueChanged<DateTime> onConfirm;

  @override
  State<_DobPickerSheet> createState() => _DobPickerSheetState();
}

class _DobPickerSheetState extends State<_DobPickerSheet> {
  static const _months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  late int _day;
  late int _month;
  late int _year;

  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _yearCtrl;

  final int _minYear = DateTime.now().year - 100;
  final int _maxYear = DateTime.now().year - 16;

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  @override
  void initState() {
    super.initState();
    _day = widget.initialDate.day;
    _month = widget.initialDate.month;
    _year = widget.initialDate.year.clamp(_minYear, _maxYear);

    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _yearCtrl = FixedExtentScrollController(initialItem: _year - _minYear);
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _clampDay() {
    final max = _daysInMonth;
    if (_day > max) {
      _day = max;
      _dayCtrl.jumpToItem(_day - 1);
    }
  }

  DateTime get _current => DateTime(_year, _month, _day.clamp(1, _daysInMonth));

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    const itemH = 44.0;
    const visibleItems = 5;
    const pickerH = itemH * visibleItems;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E), // dark sheet — iOS-style
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPad + 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // ── Title row ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Annuler', style: TextStyle(fontSize: 15)),
                ),
                const Expanded(
                  child: Text(
                    'Date de naissance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onConfirm(_current);
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4FC3F7),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    'Confirmer',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ── Drums ────────────────────────────────────────────
          SizedBox(
            height: pickerH,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Selection band
                Positioned(
                  top: itemH * 2,
                  left: 12,
                  right: 12,
                  child: Container(
                    height: itemH,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),

                // Top gradient fade
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: itemH * 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1C1C1E),
                            const Color(0xFF1C1C1E).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom gradient fade
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: itemH * 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF1C1C1E),
                            const Color(0xFF1C1C1E).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Three columns
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // DAY
                      Expanded(
                        flex: 2,
                        child: _buildWheel(
                          controller: _dayCtrl,
                          itemCount: 31,
                          itemH: itemH,
                          selectedIndex: _day - 1,
                          labelBuilder:
                              (i) => (i + 1).toString().padLeft(2, '0'),
                          onChanged:
                              (i) => setState(() {
                                _day = i + 1;
                                _clampDay();
                              }),
                        ),
                      ),
                      // MONTH
                      Expanded(
                        flex: 4,
                        child: _buildWheel(
                          controller: _monthCtrl,
                          itemCount: 12,
                          itemH: itemH,
                          selectedIndex: _month - 1,
                          labelBuilder: (i) => _months[i],
                          onChanged:
                              (i) => setState(() {
                                _month = i + 1;
                                _clampDay();
                              }),
                        ),
                      ),
                      // YEAR
                      Expanded(
                        flex: 3,
                        child: _buildWheel(
                          controller: _yearCtrl,
                          itemCount: _maxYear - _minYear + 1,
                          itemH: itemH,
                          selectedIndex: _year - _minYear,
                          labelBuilder: (i) => (_minYear + i).toString(),
                          onChanged:
                              (i) => setState(() {
                                _year = _minYear + i;
                                _clampDay();
                              }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required double itemH,
    required int selectedIndex,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemH,
      perspective: 0.002,
      diameterRatio: 3.0,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (_, i) {
          final selected = i == selectedIndex;
          return Center(
            child: Text(
              labelBuilder(i),
              style: TextStyle(
                fontSize: selected ? 18 : 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color:
                    selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                height: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}

// _DrumItem replaced by inline builder in _buildWheel

// ─────────────────────────────────────────────────────────────────────────────
// Success dialog
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0F6DDA), Color(0xFF18C0F9)],
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Bienvenue${name.isNotEmpty ? ', $name' : ''} 🎉',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2033),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre compte livreur a été créé avec succès.\nPrêt à démarrer vos courses ?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8896AB),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Commencer',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
