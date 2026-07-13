import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser.value;

    final fullName = [user?.prenom, user?.nom]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // ── Profile card ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.green.shade100,
                  backgroundImage: (user?.image != null && user!.image!.isNotEmpty)
                      ? NetworkImage(user.image!)
                      : null,
                  child: (user?.image == null || user!.image!.isEmpty)
                      ? Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  fullName.isNotEmpty ? fullName : 'Utilisateur',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (user?.email != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(user!.email!, style: const TextStyle(fontSize: 15, color: Colors.black54)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                if (user?.telephone != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(user!.telephone!, style: const TextStyle(fontSize: 15, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                if (user?.adresse != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(user!.adresse!, style: const TextStyle(fontSize: 15, color: Colors.black54)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Action buttons ────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ProfileButton(
                    icon: Icons.edit,
                    label: 'Modifier mon profil',
                    color: Colors.blue,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  _ProfileButton(
                    icon: Icons.history,
                    label: 'Historique de commandes',
                    color: Colors.black,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  _ProfileButton(
                    icon: Icons.people,
                    label: 'Mes amis',
                    color: Colors.green,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  _ProfileButton(
                    icon: Icons.logout,
                    label: 'Se déconnecter',
                    color: Colors.red,
                    onPressed: () => _confirmLogout(context, auth),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Se déconnecter ?'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // close dialog first
              await auth.logout();
              // AuthGate's ValueListenableBuilder will automatically
              // rebuild and show LoginPage when currentUser becomes null
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ProfileButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
      ),
    );
  }
}
