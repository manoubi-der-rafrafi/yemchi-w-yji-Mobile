import 'package:flutter/material.dart';

/// Palette inspir?e du logo Yemchi w Yji
class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF1A756B);
  static const Color primaryPressed = Color(0xFF15635B);
  static const Color accent = Color(0xFFEE8009);
  static const Color support = Color(0xFFEFCA74);
  static const Color secondaryAccent = Color(0xFFB47C3D);

  // Neutrals
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E0E0);
  static const Color disabledFill = Color(0xFFCFCFCF);
  static const Color disabledText = Color(0xFF8A8A8A);
  static const Color error = Color(0xFFD32F2F);

  // D?grad?s utilitaires
  static const Gradient gradWarm = LinearGradient(
    colors: [accent, support],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const Gradient gradCool = LinearGradient(
    colors: [primary, support],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      tertiary: secondaryAccent,
      onTertiary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceVariant: support,
      onSurfaceVariant: textPrimary,
      background: surface,
      onBackground: textPrimary,
      outline: border,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        filled: true,
        fillColor: surface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: disabledFill,
          disabledForegroundColor: disabledText,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: disabledFill,
          disabledForegroundColor: disabledText,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        showUnselectedLabels: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
      ),
      dividerTheme: const DividerThemeData(color: border),
      cardTheme: const CardThemeData(color: surface),
    );
  }
}

/// Widget utilitaire pour peindre un d?grad? en fond
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFEFCA74)],
        ),
      ),
      child: child,
    );
  }
}

/// Bouton plein avec texte en d?grad? chaud
class WarmCTA extends StatelessWidget {
  const WarmCTA({super.key, required this.onPressed, required this.label});
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppTheme.accent, AppTheme.accent],
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        blendMode: BlendMode.srcIn,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Titre avec texte noir et petit accent d?grad?
class LogoTitle extends StatelessWidget {
  const LogoTitle({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Place ton asset du logo ici
        Image.asset(
          'assets\images\LOGO_YEMCHI W YJI.png', // ajoute-le dans pubspec.yaml
          width: 96,
          height: 96,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        const Text(
          'YEMCHI W YJI',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
