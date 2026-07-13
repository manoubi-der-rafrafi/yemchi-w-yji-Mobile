import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';

import 'package:yemchi_wyji/features/auth/pages/splash_screen.dart';
import 'package:yemchi_wyji/features/auth/pages/login_page.dart';
import 'package:yemchi_wyji/features/auth/pages/signup_page.dart';
import 'package:yemchi_wyji/features/client/client_home_navbar.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/home_coursier_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Api>(create: (_) => Api()),
        Provider<AuthUserService>(
          create: (ctx) => AuthUserService(ctx.read<Api>()),
        ),
        Provider<AuthController>(
          create: (ctx) => AuthController(ctx.read<AuthUserService>()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Yemchi w Yji',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
          useMaterial3: true,
        ),

        // SplashScreen handles auth check and routing
        home: const SplashScreen(),

        routes: {
          '/login':        (_) => const LoginPage(),
          '/signup':       (_) => const SignUpPage(),
          '/home_coursier': (_) => HomeCoursierPage(),
          '/home_client':  (_) => ClientHome(),
        },
      ),
    );
  }
}
