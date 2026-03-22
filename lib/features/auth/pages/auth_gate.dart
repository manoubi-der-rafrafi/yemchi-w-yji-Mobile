import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/auth/pages/login_page.dart';
import 'package:yemchi_wyji/features/client/client_home_navbar.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/home_coursier_page.dart';
import 'package:yemchi_wyji/features/presence/data/presence_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _initDone = false;
  Utilisateur? _lastUser;
  AppLifecycleState? _lastLifecycle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final auth = context.read<AuthController>();
    auth.loadMeIfToken().whenComplete(() {
      if (mounted) setState(() => _initDone = true);
    });
  }

  @override
  void dispose() {
    context.read<PresenceService>().stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastLifecycle = state;
    final presence = context.read<PresenceService>();
    if (state == AppLifecycleState.resumed) {
      if (_lastUser != null) {
        presence.start(_lastUser!.id);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      presence.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final presence = context.read<PresenceService>();

    if (!_initDone) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 👉 On n'écoute QUE currentUser
    return ValueListenableBuilder(
      valueListenable: auth.currentUser,
      builder: (context, user, _) {
        if (user == null) {
          _lastUser = null;
          presence.stop();
        } else if (_lastUser?.id != user.id) {
          _lastUser = user;
          if (_lastLifecycle != AppLifecycleState.paused &&
              _lastLifecycle != AppLifecycleState.inactive &&
              _lastLifecycle != AppLifecycleState.detached) {
            presence.start(user.id);
          }
        }
        if (user == null ) return LoginPage();
        else if (user.role == Role.client) {
          return ClientHome();
        } else if (user.role == Role.transporteur) {
          return HomeCoursierPage();
        }
        else return LoginPage();
      },
    );
  }
}
