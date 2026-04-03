import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Add image_picker to pubspec.yaml
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/core/network/api.dart'; // Ensure this exports Api and ApiException
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';



class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  // Dependencies (In a real app, use GetIt or Provider)
  final AuthUserService _authService = AuthUserService(Api()); 
  
  // State
  Utilisateur? _user;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Equivalent to ngOnInit
  Future<void> _loadUserData() async {
    try {
      final userId = Provider.of<AuthController>(context, listen: false).currentUser.value?.id;
      // 1. Fetch current user (me)
      final user = await _authService.me(userId!);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      // 2. Security: Redirect if not logged in or error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session expirée ou erreur: $e')),
        );
        // Navigate back to login
        // Navigator.of(context).pushReplacementNamed('/login'); 
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Equivalent to onLogout
  Future<void> _onLogout() async {
    // Clear token via your Api class or a StorageService
    // await SecureStorage.deleteToken(); 
    
    // Stop presence service if you have one in Flutter
    // PresenceService.stop();

    if (mounted) {
      // Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      print("Logged out"); // Placeholder for navigation
    }
  }

  // Equivalent to onFileSelected + Upload + Update
  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload en cours...')),
        );
      }

      // 1. Upload
      final File imageFile = File(pickedFile.path);
      //final String imageUrl = await _authService.uploadImageProfil(imageFile);

      // 2. Update User Profile with new URL
      // Note: We use updateMe because we are the current user
      // final updatedUser = await _authService.updateMe(image: imageUrl);

      if (mounted) {
        setState(() {
          //_user = updatedUser;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Assets
    const defaultAvatar = "assets/avatar.png"; 
    const cameraIcon = "assets/profil/camera.png"; 

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text("Impossible de charger le profil")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Profile block
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey.shade300,
                      // Logic to show Network image if exists, else Asset
                      backgroundImage: (_user!.image != null && _user!.image!.isNotEmpty)
                          ? NetworkImage(_user!.image!) as ImageProvider
                          : const AssetImage(defaultAvatar),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(21),
                        onTap: _pickAndUploadImage, // Action connected here
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
                  "${_user!.nom} ${_user!.prenom}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.email, 
                  text: _user!.email ?? '—',
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.phone, 
                  text: _user!.telephone ?? '—',
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.location_on, 
                  text: _user!.adresse ?? '—',
                ),
                const SizedBox(height: 12),
                const Divider(height: 32),
                Row(
                  children: [
                    Icon(Icons.cake, color: Theme.of(context).colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    const Text("Né(e) le :", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    // Assuming dateNaissance is a String (ISO or formatted)
                    Text((_user!.dateNaissance?.toString() ?? '—'), style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions block
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ProfileButton(
                      icon: Icons.edit,
                      label: 'Modifier mon profil',
                      color: Theme.of(context).colorScheme.secondary,
                      onPressed: () {
                        // Equivalent to router.navigate(['/profil/modifier'])
                        // Navigator.pushNamed(context, '/profil/modifier', arguments: _user);
                        print("Nav to Edit");
                      },
                    ),
                    const SizedBox(height: 12),
                    _ProfileButton(
                      icon: Icons.history,
                      label: 'Historique de commandes',
                      color: Theme.of(context).colorScheme.secondary,
                      onPressed: () {
                        // Equivalent to router.navigate(['/historique'])
                         print("Nav to History");
                      },
                    ),
                    const SizedBox(height: 12),
                    _ProfileButton(
                      icon: Icons.people,
                      label: 'Mes amis',
                      color: Theme.of(context).colorScheme.secondary,
                      onPressed: () {
                         // Equivalent to router.navigate(['/mesAmis'])
                         print("Nav to Friends");
                      },
                    ),
                    const SizedBox(height: 12),
                    _ProfileButton(
                      icon: Icons.logout,
                      label: 'Se déconnecter',
                      color: Theme.of(context).colorScheme.error,
                      onPressed: _onLogout,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for User info rows to reduce code duplication
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }
}

// Custom button widget (Kept same as before)
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
