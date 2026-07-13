import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_hero.dart'; // for AuthColors

// ─────────────────────────────────────────────────────────────────────────────
// Field constants — exact values from spec
// ─────────────────────────────────────────────────────────────────────────────
const _kRadius = 12.0;
const _kMinHeight = 52.0;

// ─────────────────────────────────────────────────────────────────────────────
// YwY Text Field — animated floating label + reactive icon color + valid check
// ─────────────────────────────────────────────────────────────────────────────
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.helperText,
    this.textInputAction,
    this.autofocus = false,
    this.enabled,
    this.readOnly = false,
    this.maxLines = 1,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? hintText;
  final String? helperText;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool? enabled;
  final bool readOnly;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focus;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;
  bool _hasError = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(_onFocusChange);
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    widget.controller.addListener(_onTextChange);
  }

  void _onFocusChange() => setState(() {});

  void _onTextChange() {
    if (widget.validator == null) return;
    final err = widget.validator!(widget.controller.text);
    setState(() {
      _hasError = err != null && widget.controller.text.isNotEmpty;
      _isValid = err == null && widget.controller.text.isNotEmpty;
    });
  }

  /// Call this from the Form to trigger the shake animation on submit error
  void shake() {
    _shakeCtrl.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _shakeCtrl.dispose();
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  Color get _iconColor {
    if (_hasError) return AuthColors.error;
    if (_focus.hasFocus) return AuthColors.iconFocus;
    if (_isValid) return AuthColors.success;
    return AuthColors.iconRest;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final dx = _shakeCtrl.isAnimating
            ? 6 * (0.5 - (_shakeAnim.value % 1)).abs() * 2 - 3
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kRadius),
          boxShadow: _focus.hasFocus
              ? [
                  BoxShadow(
                    color: AuthColors.fieldFocusBorder.withValues(alpha: 0.12),
                    blurRadius: 0,
                    spreadRadius: 3,
                  )
                ]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          enableSuggestions: !widget.obscureText,
          autocorrect: !widget.obscureText,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          style: const TextStyle(
              fontSize: 15, color: AuthColors.textPrimary),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            helperText: widget.helperText,
            helperMaxLines: 2,
            constraints: const BoxConstraints(minHeight: _kMinHeight),
            prefixIcon: widget.prefixIcon != null
                ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.prefixIcon,
                      key: ValueKey(_iconColor),
                      color: _iconColor,
                      size: 20,
                    ),
                  )
                : null,
            suffixIcon: widget.suffixIcon ??
                (_isValid
                    ? const Icon(Icons.check_circle_rounded,
                        color: AuthColors.success, size: 20)
                    : null),
            filled: true,
            fillColor: _hasError
                ? const Color(0xFFFFF5F5)
                : AuthColors.fieldBg,
            labelStyle: TextStyle(
              color: _focus.hasFocus
                  ? AuthColors.fieldFocusBorder
                  : _hasError
                      ? AuthColors.error
                      : AuthColors.iconRest,
              fontSize: 14,
            ),
            floatingLabelStyle: TextStyle(
              color: _focus.hasFocus
                  ? AuthColors.fieldFocusBorder
                  : _hasError
                      ? AuthColors.error
                      : AuthColors.iconRest,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            errorStyle: const TextStyle(
              color: AuthColors.error,
              fontSize: 12,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kRadius),
              borderSide: BorderSide(
                color: _isValid
                    ? AuthColors.success.withValues(alpha: 0.5)
                    : AuthColors.fieldBorder,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kRadius),
              borderSide: const BorderSide(
                  color: AuthColors.fieldFocusBorder, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kRadius),
              borderSide:
                  const BorderSide(color: AuthColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kRadius),
              borderSide:
                  const BorderSide(color: AuthColors.error, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password field with strength indicator
// ─────────────────────────────────────────────────────────────────────────────
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    this.label = 'Mot de passe',
    this.validator,
    this.helperText,
    this.textInputAction,
    this.autofocus = false,
    this.enabled,
    this.onChanged,
    this.onSubmitted,
    this.showStrength = false,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final String? helperText;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool? enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool showStrength;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;
  int _strength = 0; // 0-3

  int _calcStrength(String v) {
    if (v.length < 4) return 0;
    int s = 0;
    if (v.length >= 8) s++;
    if (v.contains(RegExp(r'[A-Z]'))) s++;
    if (v.contains(RegExp(r'[0-9]')) || v.contains(RegExp(r'[^a-zA-Z0-9]'))) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    const strengthLabels = ['Faible', 'Moyen', 'Fort'];
    const strengthColors = [Color(0xFFE53935), Color(0xFFFFA000), Color(0xFF2ECC71)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: widget.controller,
          label: widget.label,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscure,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          onChanged: (v) {
            if (widget.showStrength) setState(() => _strength = _calcStrength(v));
            widget.onChanged?.call(v);
          },
          onSubmitted: widget.onSubmitted,
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Afficher' : 'Masquer',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: const Color(0xFF8896AB),
            ),
          ),
        ),
        if (widget.showStrength && widget.controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(3, (i) {
                final active = i < _strength;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: active
                          ? strengthColors[_strength - 1]
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _strength > 0 ? strengthLabels[_strength - 1] : '',
                  key: ValueKey(_strength),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _strength > 0 ? strengthColors[_strength - 1] : Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
