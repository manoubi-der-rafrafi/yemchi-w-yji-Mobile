import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

// 🔌 Services & contrôleurs
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/presence/data/presence_service.dart';

// 🧭 Pages
import 'package:yemchi_wyji/features/auth/pages/auth_gate.dart';
import 'package:yemchi_wyji/features/auth/pages/login_page.dart';
import 'package:yemchi_wyji/features/auth/pages/signup_page.dart';
import 'package:yemchi_wyji/features/client/client_home_navbar.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/home_coursier_page.dart';

const String _defaultMapboxAccessToken = '';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const accessToken = String.fromEnvironment(
    'ACCESS_TOKEN',
    defaultValue: _defaultMapboxAccessToken,
  );
  if (!kIsWeb && accessToken.isNotEmpty) {
    MapboxOptions.setAccessToken(accessToken);
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
        title: 'Yemchi w Yji',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF34D058)),
          useMaterial3: true,
        ),

        // ✅ Laisse AuthGate décider : LoginPage ou HomeCoursierPage
        home: const AuthGate(),

        // ✅ Routes nommées (si tu utilises Navigator.pushNamed)
        routes: {
          '/login': (_) => LoginPage(),
          '/signup': (_) => SignUpPage(),
          '/home_coursier': (_) => HomeCoursierPage(),
          '/home_client': (_) => ClientHome(),
        },
      ),
    );
  }
}
