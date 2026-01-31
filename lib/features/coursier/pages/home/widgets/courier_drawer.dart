import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/pages/profil_page.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/pages/historique_commandes_page.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/pages/zones_service_page.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/controllers/home_controller.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/pages/demandes_a_accepter_page.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/pages/mes_gains_page.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/pages/mes_factures_page.dart';
class CourierDrawer extends StatelessWidget {
  final VoidCallback? onOpenMesCourses;

  const CourierDrawer({super.key, this.onOpenMesCourses});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final homeController = context.watch<HomeController>();
    final demandesCount = homeController.commandes.length;

    return Drawer(
      elevation: 0,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ====== En-tête "compte" façon Google ======
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: ValueListenableBuilder<Utilisateur?>(
                valueListenable: auth.currentUser,
                builder: (context, user, _) {
                  String _safe(String? input) => input?.trim() ?? '';

                  final prenom = _safe(user?.prenom);
                  final nom = _safe(user?.nom);
                  final email = _safe(user?.email);
                  final fullName = [prenom, nom].where((s) => s.isNotEmpty).join(' ').trim();
                  final displayName = fullName.isNotEmpty ? fullName : 'Nom du coursier';
                  final displayEmail = email.isNotEmpty ? email : 'courier@yemchi.app';
                  final initialsSource = (fullName.isNotEmpty ? fullName : displayEmail).trim();
                  final initial = initialsSource.isNotEmpty ? initialsSource[0].toUpperCase() : 'A';

                  ImageProvider<Object>? avatarImage;
                  Widget? avatarChild;

                  final imageUrl = _safe(user?.image);
                  if (imageUrl.isNotEmpty) {
                    avatarImage = NetworkImage(imageUrl);
                  } else {
                    avatarChild = Text(initial);
                  }

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: avatarImage,
                        backgroundColor: Colors.black12,
                        child: avatarChild,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayEmail,
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 16,
                        child: Text(initial),
                      ),
                    ],
                  );
                },
              ),
            ),

            const Divider(height: 16),

            // ====== Bloc actions "compte" (optionnel) ======
            _Item(
              icon: Icons.person_outline,
              label: "Mon profil",
              onTap: () {},
            ),
            _Item(
              icon: Icons.account_circle_outlined,
              label: "Gérer le compte",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfilPage(),
                  ),
                );
              },
            ),
            _Item(
              icon: Icons.logout,
              label: "Se déconnecter",
              onTap: () async {
                Navigator.of(context).pop();
                await auth.logout();
              },
            ),

            const Divider(height: 16),

            // ====== Actions principales coursier ======
            _SectionHeader("COURSES"),
            _Item(
              icon: Icons.route_outlined,
              label: "Courses en cours",
              onTap: () {
                Navigator.of(context).pop();
                if (onOpenMesCourses != null) {
                  Future.microtask(onOpenMesCourses!);
                }
              },
            ),
            _Item(
              icon: Icons.history,
              label: "Historique des courses",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HistoriqueCommandesPage(),
                  ),
                );
              },
            ),
            _Item(
              icon: Icons.assignment_outlined,
              label: "Demandes a accepter",
              trailing: demandesCount > 0 ? _Pill('$demandesCount') : null,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChangeNotifierProvider<HomeController>.value(
                      value: homeController,
                      child: const DemandesAAccepterPage(),
                    ),
                  ),
                );
              },
            ),

            const Divider(height: 16),

            _SectionHeader("CARTE & LOCALISATION"),
            _Item(
              icon: Icons.map_outlined,
              label: "Zones de service",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ZonesServicePage(),
                  ),
                );
              },
            ),

            const Divider(height: 16),

            _SectionHeader("PORTEFEUILLE"),
            _Item(
              icon: Icons.account_balance_wallet_outlined,
              label: "Mes gains",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MesGainsPage(),
                  ),
                );
              },
            ),
            _Item(
              icon: Icons.receipt_long_outlined,
              label: "Paiements & factures",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MesFacturesPage(),
                  ),
                );
              },
            ),

            const Divider(height: 16),

            _SectionHeader("AIDE"),
            _Item(
              icon: Icons.help_outline,
              label: "Centre d’aide",
              onTap: () {},
            ),
            _Item(
              icon: Icons.settings_outlined,
              label: "Paramètres",
              onTap: () {},
            ),

            const SizedBox(height: 12),
            // Pied de page type "Règles de confidentialité • Conditions"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: const [
                  _FooterLink("Règles de confidentialité"),
                  Text("•", style: TextStyle(color: Colors.black38)),
                  _FooterLink("Conditions d’utilisation"),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ==== Petits widgets de style pour coller au design Google ====

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Item({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: false,
      leading: Icon(icon, color: Colors.black87),
      title: Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
      trailing: trailing,
      onTap: onTap,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 12.5,
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.solid,
      ),
    );
  }
}
