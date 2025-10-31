import 'package:flutter/material.dart';

class CourierDrawer extends StatelessWidget {
  const CourierDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ====== En-tête "compte" façon Google ======
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundImage: AssetImage('assets/avatar_placeholder.png'), // remplace si tu as une vraie image
                    backgroundColor: Colors.black12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Nom du coursier',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'courier@yemchi.app',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 16,
                    child: Text('A'),
                  ),
                ],
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
              onTap: () {},
            ),
            _Item(
              icon: Icons.logout,
              label: "Se déconnecter",
              onTap: () {},
            ),

            const Divider(height: 16),

            // ====== Actions principales coursier ======
            _SectionHeader("COURSES"),
            _Item(
              icon: Icons.route_outlined,
              label: "Courses en cours",
              onTap: () {},
            ),
            _Item(
              icon: Icons.history,
              label: "Historique des courses",
              onTap: () {},
            ),
            _Item(
              icon: Icons.assignment_outlined,
              label: "Demandes à accepter",
              trailing: const _Pill("3"), // exemple badge
              onTap: () {},
            ),

            const Divider(height: 16),

            _SectionHeader("CARTE & LOCALISATION"),
            _Item(
              icon: Icons.my_location_outlined,
              label: "Ma position",
              onTap: () {
                // ex: remonter un event pour centrer la carte
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Centrer sur ma position")),
                );
              },
            ),
            _Item(
              icon: Icons.map_outlined,
              label: "Zones de service",
              onTap: () {},
            ),

            const Divider(height: 16),

            _SectionHeader("PORTEFEUILLE"),
            _Item(
              icon: Icons.account_balance_wallet_outlined,
              label: "Mes gains",
              onTap: () {},
            ),
            _Item(
              icon: Icons.receipt_long_outlined,
              label: "Paiements & factures",
              onTap: () {},
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
