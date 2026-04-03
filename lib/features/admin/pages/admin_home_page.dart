import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final user = auth.currentUser.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          TextButton(
            onPressed: () async {
              await auth.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connected as: ${user?.email ?? user?.id ?? "unknown"}'),
            const SizedBox(height: 8),
            Text('Role: ${user?.role.name ?? "unknown"}'),
            const SizedBox(height: 16),
            const Text(
              'Admin role is now routed correctly. Add your admin-specific '
              'screens/services here.',
            ),
          ],
        ),
      ),
    );
  }
}
