import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/auth/pages/login_page.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/home_coursier_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initDone = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    auth.loadMeIfToken().whenComplete(() {
      if (mounted) setState(() => _initDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    if (!_initDone) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 👉 On n'écoute QUE currentUser
    return ValueListenableBuilder(
      valueListenable: auth.currentUser,
      builder: (context, user, _) {
        if (user == null) return LoginPage();
        return HomeCoursierPage();
      },
    );
  }
}
