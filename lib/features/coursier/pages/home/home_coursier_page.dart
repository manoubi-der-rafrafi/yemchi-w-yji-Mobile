// lib/features/coursier/pages/home/home_coursier_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/pages/mes_courses_page.dart';

import 'controllers/home_controller.dart';
import 'widgets/courier_drawer.dart';
import 'widgets/map_view.dart';
import 'widgets/notifications_panel.dart';
import 'widgets/top_bar.dart';

class HomeCoursierPage extends StatelessWidget {
  HomeCoursierPage({super.key});

  // Permet d'appeler centerOnMe() ou startNavigationFor() depuis cette page.
  final GlobalKey<MapViewState> _mapKey = GlobalKey<MapViewState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeController(context.read<AuthController>()),
      builder: (context, _) {
        return Scaffold(
          drawer: CourierDrawer(
            onOpenMesCourses: () => _openMesCourses(context),
          ),
          body: Stack(
            children: [
              // 1) Carte
              Positioned.fill(child: MapView(key: _mapKey)),

              // 2) Top bar
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(child: TopBar()),
              ),

              // 3) Bouton "ma position" - centre droite
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FloatingActionButton.small(
                          onPressed:
                              () =>
                                  _mapKey.currentState?.handleCenterButtonTap(),
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 4) Panneau notifications en bas
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: NotificationsPanel(mapKey: _mapKey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMesCourses(BuildContext context) async {
    final controller = context.read<HomeController>();
    final Commande? commande = await Navigator.of(context).push<Commande>(
      MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider<HomeController>.value(
              value: controller,
              child: const MesCoursesPage(),
            ),
      ),
    );
    if (commande == null) return;

    final mapState = _mapKey.currentState;
    if (mapState != null) {
      await mapState.startNavigationFor(commande);
      return;
    }

    controller.selectCommande(commande);
    controller.setNavigationMode(true);
  }
}
