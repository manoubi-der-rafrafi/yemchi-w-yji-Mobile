import 'package:flutter/material.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/core/models/produit.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';
import 'package:yemchi_wyji/features/produit/data/produit_service.dart';

class CommandeDetailsPage extends StatefulWidget {
  final Commande commande;

  const CommandeDetailsPage({super.key, required this.commande});

  @override
  State<CommandeDetailsPage> createState() => _CommandeDetailsPageState();
}

class _CommandeDetailsPageState extends State<CommandeDetailsPage> {
  late Future<_CommandeDetailsData> _future;
  final ProduitService _produitService = ProduitService();

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_CommandeDetailsData> _loadData() async {
    Utilisateur? client;
    final clientId = widget.commande.clientId;
    if (clientId != null && clientId.isNotEmpty) {
      try {
        final authService = AuthUserService(Api());
        client = await authService.getById(clientId);
      } catch (_) {
        client = null;
      }
    }
    final produits = await _produitService.getByCommande(widget.commande.id);
    return _CommandeDetailsData(client: client, produits: produits);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Details de la commande')),
      body: FutureBuilder<_CommandeDetailsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorSection(
              error: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _future = _loadData();
                });
              },
            );
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _loadData();
              });
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _ClientCard(
                  client: data.client,
                  fallbackEmail: widget.commande.telDepart,
                  fallbackPhone: widget.commande.telDepart,
                ),
                const SizedBox(height: 16),
                _CommandeInfoCard(commande: widget.commande),
                const SizedBox(height: 16),
                _ProduitsSection(produits: data.produits),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Utilisateur? client;
  final String? fallbackEmail;
  final String? fallbackPhone;

  const _ClientCard({
    required this.client,
    required this.fallbackEmail,
    required this.fallbackPhone,
  });

  String get _displayName {
    final nom = client?.nom?.trim() ?? '';
    final prenom = client?.prenom?.trim() ?? '';
    final combined = '$prenom $nom'.trim();
    return combined.isNotEmpty ? combined : 'Client';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email =
        client?.email?.trim().isNotEmpty == true
            ? client!.email!
            : (fallbackEmail ?? 'Email non disponible');
    final phone =
        client?.telephone?.trim().isNotEmpty == true
            ? client!.telephone!
            : (fallbackPhone ?? 'Numero non disponible');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _ClientAvatar(imageUrl: client?.image, name: _displayName),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(email, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(phone, style: theme.textTheme.bodySmall),
                    ],
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

class _CommandeInfoCard extends StatelessWidget {
  final Commande commande;

  const _CommandeInfoCard({required this.commande});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations trajet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.flight_takeoff,
              label: 'Depart',
              value:
                  '${commande.zonePrincipaleDepart ?? '-'} · ${commande.sousZoneDepart ?? '-'}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.flag,
              label: 'Arrivee',
              value:
                  '${commande.zonePrincipaleArrivee ?? '-'} · ${commande.sousZoneArrivee ?? '-'}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.route,
              label: 'Trajet',
              value:
                  commande.distanceKm != null
                      ? '${commande.distanceKm!.toStringAsFixed(1)} km'
                      : 'Non precise',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Prix',
              value:
                  commande.prix != null
                      ? '${commande.prix!.toStringAsFixed(2)} DT'
                      : 'Non precise',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.qr_code_2,
              label: 'QR Reception',
              value:
                  commande.qrCodeReceptionScanne == true
                      ? 'Scannee'
                      : 'Non scannee',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProduitsSection extends StatelessWidget {
  final List<Produit> produits;

  const _ProduitsSection({required this.produits});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (produits.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'Aucun produit pour cette commande.',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produits (${produits.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...produits.map(
          (produit) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ProduitTile(produit: produit),
          ),
        ),
      ],
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;

  const _ClientAvatar({required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    const double size = 64;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _PlaceholderAvatar(name: name),
        ),
      );
    }
    return _PlaceholderAvatar(name: name);
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  final String name;

  const _PlaceholderAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 32,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProduitTile extends StatelessWidget {
  final Produit produit;

  const _ProduitTile({required this.produit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _ProduitImage(imageUrl: produit.image1),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.nom?.trim().isNotEmpty == true
                      ? produit.nom!.trim()
                      : 'Produit sans nom',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantite : ${produit.quantite ?? '-'}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProduitImage extends StatelessWidget {
  final String? imageUrl;

  const _ProduitImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const double size = 60;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _PlaceholderProduitImage(size: size),
        ),
      );
    }
    return _PlaceholderProduitImage(size: size);
  }
}

class _PlaceholderProduitImage extends StatelessWidget {
  final double size;

  const _PlaceholderProduitImage({required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorSection({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger les details.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandeDetailsData {
  final Utilisateur? client;
  final List<Produit> produits;

  _CommandeDetailsData({required this.client, required this.produits});
}
