import 'package:flutter/material.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example static user data
    const avatar = "assets/avatar.png"; // Put your image in assets!
    const cameraIcon = "assets/profil/camera.png"; // Same here
    const defaultUser = {
      'nom': 'Dupont',
      'prenom': 'Marie',
      'email': 'marie.dupont@example.com',
      'telephone': '+33 6 12 34 56 78',
      'adresse': '12 Rue des Fleurs, Paris',
      'dateNaissance': '15/04/1990',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Profile block
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(
                color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)
              )],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: AssetImage(avatar),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(21),
                        onTap: () {}, // Can add change photo action
                        child: CircleAvatar(
                          radius: 21,
                          backgroundColor: Colors.grey.shade200,
                          child: Image.asset(cameraIcon, width: 28, height: 28),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "${defaultUser['nom']} ${defaultUser['prenom']}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text(defaultUser['email']!, style: TextStyle(fontSize: 16, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text(defaultUser['telephone']!, style: TextStyle(fontSize: 16, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text(defaultUser['adresse']!, style: TextStyle(fontSize: 16, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 32),
                Row(
                  children: [
                    const Icon(Icons.cake, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    const Text("Date de naissance :", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text(defaultUser['dateNaissance']!, style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ),
          // Actions block
          Expanded(
            child: Container(
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
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }
}

// Custom button widget for profile actions
class _ProfileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ProfileButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed
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
