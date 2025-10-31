// lib/features/coursier/pages/home/home_coursier_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/home_controller.dart';
import 'widgets/top_bar.dart';
import 'widgets/map_view.dart';
import 'widgets/notifications_panel.dart';
import 'widgets/courier_drawer.dart'; // ← ajout import du menu

class HomeCoursierPage extends StatelessWidget {
  HomeCoursierPage({super.key});

  // 🔑 permet d’appeler centerOnMe() depuis ici
  final GlobalKey<MapViewState> _mapKey = GlobalKey<MapViewState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeController(),
      child: Scaffold(
        drawer: const CourierDrawer(), // ← ajout du Drawer ici
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

            // 3) Bouton "ma position" — 👉 CENTRE DROITE
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SafeArea(
                    // pas de padding haut/bas, on gère juste le bord droit
                    top: false,
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FloatingActionButton.small(
                        onPressed: () => _mapKey.currentState?.centerOnMe(),
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
      ),
    );
  }
}
