import 'package:flutter/material.dart';

/// Palette inspirée du logo Yemchi w Yji
class AppTheme {
  // Dégradés du logo
  static const Gradient gradWarm = LinearGradient(
    colors: [Color(0xFFF6C300), Color(0xFFFF6A00), Color(0xFFFF3B2E)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const Gradient gradCool = LinearGradient(
    colors: [Color(0xFF0058D9), Color(0xFF0A7BFF), Color(0xFF00C2FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Color blackText = Color(0xFF121212); // pour rappeler le logotype

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A7BFF),
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: scheme.copyWith(
        primary: const Color(0xFF0A7BFF),
        secondary: const Color(0xFFFF6A00),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: blackText,
        displayColor: blackText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: scheme.surfaceVariant.withOpacity(0.35),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }
}

/// Widget utilitaire pour peindre un dégradé en fond
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
          colors: [Color(0xFF0A7BFF), Color(0xFF00C2FF)],
        ),
      ),
      child: child,
    );
  }
}

/// Bouton plein avec texte en dégradé chaud
class WarmCTA extends StatelessWidget {
  const WarmCTA({super.key, required this.onPressed, required this.label});
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: ShaderMask(
        shaderCallback:
            (bounds) => const LinearGradient(
              colors: [Color(0xFFF6C300), Color(0xFFFF6A00), Color(0xFFFF3B2E)],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        blendMode: BlendMode.srcIn,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Titre avec texte noir et petit accent dégradé
class LogoTitle extends StatelessWidget {
  const LogoTitle({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Place ton asset du logo ici
        Image.asset(
          'assets/images/logo_yemchi_w_yji.jpg', // ajoute-le dans pubspec.yaml
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
