import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/home_controller.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HomeController>();
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // === Bouton burger à gauche ===
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 1,
                child: Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(ctx).openDrawer(), // ✅ ouvre le Drawer
                  ),
                ),
              ),
            ),

            // === Bouton central "Commandes" ===
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Afficher les commandes')),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('Commandes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF7EC),
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: const StadiumBorder(),
                ),
              ),
            ),

            // === Boutons langues à droite ===
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(12),
                  constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
                  isSelected: [
                    ctrl.currentLang == AppLang.ar,
                    ctrl.currentLang == AppLang.en,
                  ],
                  onPressed: (index) {
                    ctrl.setLang(index == 0 ? AppLang.ar : AppLang.en);
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('AR'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('FR'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}