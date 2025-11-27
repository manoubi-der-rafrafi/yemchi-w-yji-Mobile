import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';

import '../controllers/home_controller.dart';
import 'commande_produits_page.dart';

enum MesCourseFilter { tous, recuperer, livraison }

class MesCoursesPage extends StatefulWidget {
  const MesCoursesPage({super.key});

  @override
  State<MesCoursesPage> createState() => _MesCoursesPageState();
}

class _MesCoursesPageState extends State<MesCoursesPage> {
  final Map<String, Future<Utilisateur?>> _clientFutures = {};
  MesCourseFilter _filter = MesCourseFilter.tous;

  Future<Utilisateur?>? _futureForClient(String? clientId) {
    if (clientId == null || clientId.trim().isEmpty) return null;
    return _clientFutures.putIfAbsent(
      clientId,
      () async {
        try {
          return await context.read<AuthUserService>().getById(clientId);
        } catch (_) {
          return null;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final commandes = _filteredCommandes(home.mesCommandes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses en cours'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SegmentedButton<MesCourseFilter>(
              segments: const [
                ButtonSegment(
                  value: MesCourseFilter.tous,
                  label: Text('Tous'),
                ),
                ButtonSegment(
                  value: MesCourseFilter.recuperer,
                  label: Text('À récupérer'),
                ),
                ButtonSegment(
                  value: MesCourseFilter.livraison,
                  label: Text('En livraison'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty && selection.first != _filter) {
                  setState(() => _filter = selection.first);
                }
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                backgroundColor: MaterialStateProperty.resolveWith(
                  (states) => states.contains(MaterialState.selected)
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                ),
                foregroundColor: MaterialStateProperty.resolveWith(
                  (states) => states.contains(MaterialState.selected)
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                side: MaterialStateProperty.resolveWith(
                  (states) => BorderSide(
                    color: states.contains(MaterialState.selected)
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                elevation: MaterialStateProperty.all(0),
              ),
            ),
          ),
          Expanded(
            child: commandes.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: commandes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final commande = commandes[index];
                return _CommandeCard(
                  commande: commande,
                  clientFuture: _futureForClient(commande.clientId),
                  onStartNavigation: () => _handleStartCommande(commande),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleStartCommande(Commande commande) {
    Navigator.of(context).pop(commande);
  }

  List<Commande> _filteredCommandes(List<Commande> source) {
    switch (_filter) {
      case MesCourseFilter.tous:
        return source;
      case MesCourseFilter.recuperer:
        return source
            .where((c) => (c.qrCodeDepartScanne ?? false) == false)
            .toList();
      case MesCourseFilter.livraison:
        return source.where((c) => c.qrCodeDepartScanne == true).toList();
    }
  }
}

class _CommandeCard extends StatelessWidget {
  final Commande commande;
  final Future<Utilisateur?>? clientFuture;
  final VoidCallback onStartNavigation;

  const _CommandeCard({
    required this.commande,
    required this.clientFuture,
    required this.onStartNavigation,
  });

  Color _cardBackground(bool isPickupDone) =>
      isPickupDone ? const Color(0xFFE6F4EA) : const Color(0xFFFFF3E0);

  Color _badgeColor(bool isPickupDone) =>
      isPickupDone ? const Color(0xFF1E8E3E) : const Color(0xFFFB8C00);

  String _modePaiementLabel(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    switch (normalized) {
      case 'en_ligne':
        return 'payé';
      case 'depart':
        return 'depare';
      case 'arrivee':
        return 'arriver';
      default:
        return 'Mode inconnu';
    }
  }

  Color _modePaiementColor(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    switch (normalized) {
      case 'en_ligne':
        return const Color(0xFF1E8E3E);
      case 'depart':
        return const Color(0xFFFB8C00);
      case 'arrivee':
        return const Color(0xFF1976D2);
      default:
        return Colors.grey;
    }
  }

  String _formatZone(String? zone, String? sousZone) {
    final z = (zone ?? '').trim();
    final sz = (sousZone ?? '').trim();
    if (z.isEmpty && sz.isEmpty) return 'Zone non precisee';
    if (z.isNotEmpty && sz.isNotEmpty) return '$z / $sz';
    return z.isNotEmpty ? z : sz;
  }

  String _formatPrice(double? price) {
    if (price == null) return 'Prix non renseigne';
    final showDecimals = price % 1 != 0;
    return '${showDecimals ? price.toStringAsFixed(2) : price.toStringAsFixed(0)} TND';
  }

  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) return 'Distance inconnue';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPickupDone = commande.qrCodeDepartScanne ?? false;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      color: _cardBackground(isPickupDone),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClientHeader(
              commande: commande,
              future: clientFuture,
            ),
            const SizedBox(height: 8),
            _StatusBadge(
              label: isPickupDone ? 'En livraison' : 'À récupérer',
              color: _badgeColor(isPickupDone),
            ),
            const SizedBox(height: 6),
            _ModePaiementBadge(
              label: _modePaiementLabel(commande.modePaiement),
              color: _modePaiementColor(commande.modePaiement),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RouteRow(
                      label: 'Depart',
                      value: _formatZone(
                        commande.zonePrincipaleDepart,
                        commande.sousZoneDepart,
                      ),
                      icon: Icons.flag_circle_outlined,
                    ),
                    const SizedBox(height: 8),
                    _RouteRow(
                      label: 'Arrivee',
                      value: _formatZone(
                        commande.zonePrincipaleArrivee,
                        commande.sousZoneArrivee,
                      ),
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                            label: 'Prix',
                            value: _formatPrice(commande.prix),
                            icon: Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InfoChip(
                            label: 'Distance',
                            value: _formatDistance(commande.distanceKm),
                            icon: Icons.social_distance,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CommandeProduitsPage(commande: commande),
                      ),
                    );
                  },
                  child: const Text('Details'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onStartNavigation,
                    child: const Text('Demarrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientHeader extends StatelessWidget {
  final Commande commande;
  final Future<Utilisateur?>? future;

  const _ClientHeader({
    required this.commande,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return _ClientRow(
        user: null,
        isLoading: false,
        commande: commande,
      );
    }
    return FutureBuilder<Utilisateur?>(
      future: future,
      builder: (context, snapshot) {
        return _ClientRow(
          user: snapshot.data,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          commande: commande,
        );
      },
    );
  }
}

class _ClientRow extends StatelessWidget {
  final Utilisateur? user;
  final bool isLoading;
  final Commande commande;

  const _ClientRow({
    required this.user,
    required this.isLoading,
    required this.commande,
  });

  String _fallback(String? value, String placeholder) {
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? placeholder : clean;
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = user?.image?.trim();
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundImage:
              (avatarImage != null && avatarImage.isNotEmpty) ? NetworkImage(avatarImage) : null,
          child: (avatarImage == null || avatarImage.isEmpty)
              ? (isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fallback(
                  user != null ? '${user!.prenom ?? ''} ${user!.nom ?? ''}'.trim() : '',
                  'Client inconnu',
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _fallback(user?.email, 'Email indisponible'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                _fallback(user?.telephone ?? commande.telDepart, 'Numero indisponible'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _RouteRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ModePaiementBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ModePaiementBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Mode :',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
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
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune course en cours',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Vous verrez vos commandes assignees ici des qu\'elles seront disponibles.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
