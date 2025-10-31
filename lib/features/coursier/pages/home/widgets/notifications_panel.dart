import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';

import '../controllers/home_controller.dart';
import 'map_view.dart';

class NotificationsPanel extends StatelessWidget {
  final GlobalKey<MapViewState> mapKey;
  const NotificationsPanel({super.key, required this.mapKey});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HomeController>();
    final commande = ctrl.selectedCommande;

    if (commande == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _CommandeSelectionCard(
            key: ValueKey(commande.id),
            commande: commande,
            onClose: () => context.read<HomeController>().selectCommande(null),
            onDetails: () => mapKey.currentState?.openCommandeDetails(commande),
          ),
        ),
      ),
    );
  }
}

class _CommandeSelectionCard extends StatefulWidget {
  final Commande commande;
  final VoidCallback onClose;
  final VoidCallback onDetails;

  const _CommandeSelectionCard({
    super.key,
    required this.commande,
    required this.onClose,
    required this.onDetails,
  });

  @override
  State<_CommandeSelectionCard> createState() => _CommandeSelectionCardState();
}

class _CommandeSelectionCardState extends State<_CommandeSelectionCard> {
  late Future<Utilisateur?> _clientFuture;

  @override
  void initState() {
    super.initState();
    _clientFuture = _fetchClient();
  }

  @override
  void didUpdateWidget(covariant _CommandeSelectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commande.id != widget.commande.id) {
      _clientFuture = _fetchClient();
    }
  }

  Future<Utilisateur?> _fetchClient() async {
    final clientId = widget.commande.clientId;
    if (clientId == null || clientId.isEmpty) return null;
    final service = context.read<AuthUserService>();
    try {
      return await service.getById(clientId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<Utilisateur?>(
            future: _clientFuture,
            builder: (context, snapshot) {
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ClientInfos(
                    theme: theme,
                    user: snapshot.data,
                    commande: widget.commande,
                    isLoading: isLoading,
                    onClose: widget.onClose,
                  ),
                  const SizedBox(height: 12),
                  
                ],
              );
            },
          ),
          const Divider(height: 28),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: widget.onDetails,
                  child: const Text('Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ClientInfos extends StatelessWidget {
  final ThemeData theme;
  final Utilisateur? user;
  final Commande commande;
  final bool isLoading;
  final VoidCallback onClose;

  const _ClientInfos({
    required this.theme,
    required this.user,
    required this.commande,
    required this.isLoading,
    required this.onClose,
  });

  String _fallback(String? value, String fallback) {
    if (value == null) return fallback;
    final clean = value.trim();
    return clean.isEmpty ? fallback : clean;
  }

  @override
  Widget build(BuildContext context) {
    final parts = [user?.prenom, user?.nom]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final fullName =
        parts.isNotEmpty ? parts.join(' ') : 'Utilisateur inconnu';

    final email = _fallback(user?.email, 'Email indisponible');
    final phone = _fallback(
      user?.telephone ?? commande.telDepart,
      'Telephone indisponible',
    );

    final imageUrl = user?.image?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    final avatar = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.6),
          width: 1.4,
        ),
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
        child: hasImage
            ? null
            : isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: theme.colorScheme.primary,
                  ),
      ),
    );

    final statusColor =
        user?.statut == Statut.actif ? Colors.green : Colors.redAccent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                phone,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          tooltip: 'Fermer',
        ),
      ],
    );
  }
}
