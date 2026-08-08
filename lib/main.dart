import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/config/mapbox_config.dart';

// 🔌 Services & contrôleurs
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/core/analytics/analytics_service.dart';
import 'package:yemchi_wyji/core/errors/application_error_service.dart';
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/presence/data/presence_service.dart';

// 🧭 Pages
import 'package:yemchi_wyji/features/auth/pages/splash_screen.dart';
import 'package:yemchi_wyji/features/auth/pages/login_page.dart';
import 'package:yemchi_wyji/features/auth/pages/signup_page.dart';
import 'package:yemchi_wyji/features/client/client_home_navbar.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/home_coursier_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      ApplicationErrorService.report(
        details.exception,
        stackTrace: details.stack,
        type: 'flutter_error',
      ),
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      ApplicationErrorService.report(
        error,
        stackTrace: stack,
        type: 'unhandled_async_error',
        severity: 'critical',
      ),
    );
    return false;
  };
  unawaited(AnalyticsService.track('app_open'));
  if (!kIsWeb && MapboxConfig.hasValidAccessToken) {
    MapboxOptions.setAccessToken(MapboxConfig.accessToken);
  } else if (!kIsWeb) {
    debugPrint(
      'MAPBOX CONFIGURATION ERROR: ACCESS_TOKEN is missing or invalid. '
      'Start with --dart-define=ACCESS_TOKEN=pk...',
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Instance unique et partagée dans toute l'app
        Provider<Api>(create: (_) => Api()),
        Provider<AuthUserService>(
          create: (ctx) => AuthUserService(ctx.read<Api>()),
        ),
        Provider<AuthController>(
          create: (ctx) => AuthController(ctx.read<AuthUserService>()),
        ),
        Provider<PresenceService>(
          create: (ctx) => PresenceService(ctx.read<Api>()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'yemchiwyji Coursier',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
          useMaterial3: true,
        ),

        home: const SplashScreen(),

        // ✅ Routes nommées (si tu utilises Navigator.pushNamed)
        routes: {
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const SignUpPage(),
          '/home_coursier': (_) => HomeCoursierPage(),
          '/home_client': (_) => ClientHome(),
        },
      ),
    );
  }
}
