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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: _onContinue,
              onStepCancel: _onBack,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      FilledButton(
                        onPressed: details.onStepContinue,
                        child: Text(_currentStep == 2 ? 'Terminer' : 'Continuer'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: Text(_currentStep == 0 ? 'Annuler' : 'Retour'),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Infos'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: Form(
                    key: _formKeys[0],
                    child: Column(
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
                        const SizedBox(height: 12),
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
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Date de naissance obligatoire'
                              : null,
                          onTap: _pickDob,
                        ),
                        const SizedBox(height: 12),
                        AuthTextField(
                          controller: _address,
                          label: 'Adresse',
                          prefixIcon: Icons.home_outlined,
                          hintText: 'Rue, ville, code postal',
                          validator: (v) => (v == null || v.length < 5)
                              ? 'Adresse trop courte'
                              : null,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('Profil'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: Form(
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
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Obligatoire'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AuthTextField(
                                controller: _firstName,
                                label: 'Prénom',
                                prefixIcon: Icons.person_outline,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Obligatoire'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Statique : UI only
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Google Sign-In (UI only)')),
                            );
                          },
                          icon: const Icon(Icons.g_mobiledata),
                          label: const Text('Continuer avec Google'),
                        ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('Sécurité'),
                  isActive: _currentStep >= 2,
                  state: _currentStep == 2 ? StepState.indexed : StepState.complete,
                  content: Form(
                    key: _formKeys[2],
                    child: Column(
                      children: [
                        AuthPasswordField(
                          controller: _password,
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Min 6 caractères'
                              : null,
                          helperText: 'Utilisez au moins 6 caractères',
                        ),
                        const SizedBox(height: 12),
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}