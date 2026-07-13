import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gérer mon compte'), centerTitle: false),
      body: SafeArea(
        child: ValueListenableBuilder<Utilisateur?>(
          valueListenable: auth.currentUser,
          builder: (context, user, _) {
            if (user == null) {
              return const _EmptyState();
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IdentityCard(user: user),
                  const SizedBox(height: 16),
                  _ContactCard(user: user),
                  const SizedBox(height: 16),
                  _DocumentsCard(user: user),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final Utilisateur user;

  @override
  Widget build(BuildContext context) {
    String safe(String? value) => value?.trim() ?? '';

    final prenom = safe(user.prenom);
    final nom = safe(user.nom);
    final displayName =
        [prenom, nom].where((text) => text.isNotEmpty).join(' ').trim();
    final initialsSource =
        displayName.isNotEmpty ? displayName : safe(user.email);
    final initials = () {
      final source = initialsSource.trimLeft();
      if (source.isEmpty) return '?';
      return source.substring(0, 1).toUpperCase();
    }();
    final roleLabel = switch (user.role) {
      Role.transporteur => 'Coursier',
      Role.admin => 'Administrateur',
      _ => 'Client',
    };

    ImageProvider<Object>? avatarImage;
    final imageUrl = user.image?.trim();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      avatarImage = NetworkImage(imageUrl);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: avatarImage,
              backgroundColor: Colors.black12,
              child:
                  avatarImage == null
                      ? Text(initials, style: const TextStyle(fontSize: 24))
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName.isNotEmpty ? displayName : 'Nom non renseigné',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roleLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.user});

  final Utilisateur user;

  @override
  Widget build(BuildContext context) {
    String label(String? value) =>
        (value?.trim().isNotEmpty ?? false) ? value!.trim() : 'Non renseigné';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coordonnées',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Téléphone',
              value: label(user.telephone),
            ),
            const Divider(height: 24),
            _InfoTile(
              icon: Icons.mail_outline,
              label: 'E-mail',
              value: label(user.email),
            ),
            const Divider(height: 24),
            _InfoTile(
              icon: Icons.location_on_outlined,
              label: 'Adresse',
              value: label(user.adresse),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard({required this.user});

  final Utilisateur user;

  @override
  Widget build(BuildContext context) {
    String vehicleLabel(TypeVehicule? value) {
      if (value == null) return 'Non renseignǸ';
      final formatted = value.name
          .toLowerCase()
          .split('_')
          .map(
            (part) =>
                part.isEmpty ? part : part[0].toUpperCase() + part.substring(1),
          )
          .join(' ');
      return formatted;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents & vǸhicule',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 500;
                final itemWidth =
                    isWide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocumentPreview(
                      label: 'CIN (recto)',
                      imageUrl: user.imageCarteIdentiteFace,
                      width: itemWidth,
                    ),
                    _DocumentPreview(
                      label: 'CIN (verso)',
                      imageUrl: user.imageCarteIdentiteArriere,
                      width: itemWidth,
                    ),
                    _DocumentPreview(
                      label: 'Permis de conduire',
                      imageUrl: user.imagePermis,
                      width: itemWidth,
                    ),
                    _DocumentPreview(
                      label: 'Carte grise',
                      imageUrl: user.imageCarteGrise,
                      width: itemWidth,
                    ),
                    _DocumentPreview(
                      label: 'Assurance',
                      imageUrl: user.imageAssurance,
                      width: itemWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _InfoTile(
              icon: Icons.local_shipping_outlined,
              label: 'Type de vǸhicule',
              value: vehicleLabel(user.typeVehicule),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({
    required this.label,
    required this.imageUrl,
    required this.width,
  });

  final String label;
  final String? imageUrl;
  final double width;

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl?.trim();
    final hasImage = trimmed != null && trimmed.isNotEmpty;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child:
                  hasImage
                      ? Image.network(
                        trimmed,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => _DocumentPlaceholder(
                              icon: Icons.broken_image_outlined,
                              label: 'Impossible de charger',
                            ),
                      )
                      : const _DocumentPlaceholder(
                        icon: Icons.image_not_supported_outlined,
                        label: 'Document indisponible',
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentPlaceholder extends StatelessWidget {
  const _DocumentPlaceholder({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.black38),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 56, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            'Aucun utilisateur connecté',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Connectez-vous pour consulter et gérer votre profil.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
