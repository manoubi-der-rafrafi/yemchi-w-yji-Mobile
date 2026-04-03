import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/features/admin/pages/admin_home_page.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/auth/pages/login_page.dart';
import 'package:yemchi_wyji/features/client/client_home_navbar.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/home_coursier_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initDone = false;
  String? _lastLoggedUserId;
  Role? _lastLoggedRole;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    if (kDebugMode) {
      debugPrint('[AUTH_GATE] init -> loadMeIfToken()');
    }
    auth.loadMeIfToken().whenComplete(() {
      if (kDebugMode) {
        debugPrint('[AUTH_GATE] loadMeIfToken() completed');
      }
      if (mounted) setState(() => _initDone = true);
    });
  }

  void _logRouteDecision(Utilisateur? user) {
    if (!kDebugMode) return;
    final userId = user?.id;
    final role = user?.role;
    if (_lastLoggedUserId == userId && _lastLoggedRole == role) return;
    _lastLoggedUserId = userId;
    _lastLoggedRole = role;
    debugPrint(
      '[AUTH_GATE] route decision -> userId=${user?.id}, role=${user?.role.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    if (!_initDone) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ValueListenableBuilder(
      valueListenable: auth.currentUser,
      builder: (context, user, _) {
        _logRouteDecision(user);
        if (user == null) return LoginPage();
        if (user.role == Role.client) return ClientHome();
        if (user.role == Role.transporteur) return HomeCoursierPage();
        if (user.role == Role.admin) return const AdminHomePage();
        return LoginPage();
      },
    );
  }
}
