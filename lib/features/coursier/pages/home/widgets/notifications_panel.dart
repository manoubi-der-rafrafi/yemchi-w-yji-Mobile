import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
    if (!ctrl.isPanelOpen || commande == null) {
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
            isMine: ctrl.isSelectedCommandeMine,
            onClose: () {
              final mapState = mapKey.currentState;
              if (mapState != null) {
                mapState.stopNavigation(); // 🛑 Stoppe la navigation avant de fermer
              }
              context.read<HomeController>().clearSelection(); // 🔚 Ferme le panneau
            },

            onDetails: () => mapKey.currentState?.openCommandeDetails(commande),
            isNavigationActive: ctrl.isNavigationMode,
            onToggleNavigation: ctrl.isSelectedCommandeMine
                ? () async {
                    final mapState = mapKey.currentState;
                    if (mapState == null) return;
                    if (ctrl.isNavigationMode) {
                      mapState.stopNavigation();
                    } else {
                      await mapState.startNavigationFor(commande);
                    }
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

class _CommandeSelectionCard extends StatefulWidget {
  final Commande commande;
  final bool isMine;
  final VoidCallback onClose;
  final VoidCallback onDetails;
  final bool isNavigationActive;
  final VoidCallback? onToggleNavigation;

  const _CommandeSelectionCard({
    super.key,
    required this.commande,
    required this.isMine,
    required this.onClose,
    required this.onDetails,
    required this.isNavigationActive,
    this.onToggleNavigation,
  });

  @override
  State<_CommandeSelectionCard> createState() => _CommandeSelectionCardState();
}

class _CommandeSelectionCardState extends State<_CommandeSelectionCard> {
  late Future<Utilisateur?> _clientFuture;
  bool _isCalling = false;

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

  Future<void> _callClient() async {
    if (_isCalling) return;

    final bool departScanne = widget.commande.qrCodeDepartScanne == true;
    final rawNumber = departScanne
        ? (widget.commande.telArrivee ?? widget.commande.telDepart)
        : (widget.commande.telDepart ?? widget.commande.telArrivee);
    final number = rawNumber?.replaceAll(RegExp(r'[^0-9+]'), '');

    if (number == null || number.isEmpty) {
      _showSnack('Numero de telephone indisponible');
      return;
    }

    _isCalling = true;
    try {
      final uri = Uri(scheme: 'tel', path: number);
      if (!await launchUrl(uri)) {
        _showSnack('Impossible de lancer l\'appel');
      }
    } catch (_) {
      _showSnack('Impossible de lancer l\'appel');
    } finally {
      _isCalling = false;
    }
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeCtrl = context.watch<HomeController>();
    final double? distanceMetersFromRoute =
        homeCtrl.currentRouteDistanceMeters ??
            (widget.commande.distanceKm != null
                ? widget.commande.distanceKm! * 1000
                : null);
    final Duration? eta = homeCtrl.currentRouteEta ??
        (distanceMetersFromRoute != null
            ? _etaFromDistance(distanceMetersFromRoute)
            : null);
    final distanceText = distanceMetersFromRoute != null
        ? _formatDistance(distanceMetersFromRoute)
        : null;
    final durationText = eta != null ? _formatDuration(eta) : null;
    final priceText = !widget.isNavigationActive
        ? _formatPrice(widget.commande.prix)
        : null;
    final bool hasMetrics =
        distanceText != null || durationText != null || priceText != null;

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
                    showContactDetails: !widget.isNavigationActive,
                  ),
                  const SizedBox(height: 10),
                  if (hasMetrics) ...[
                    _RouteMetrics(
                      distance: distanceText,
                      eta: durationText,
                      price: priceText,
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.isMine) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isNavigationActive
                        ? () => _callClient()
                        : widget.onDetails,
                    child: Text(widget.isNavigationActive ? 'Appeler' : 'Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onToggleNavigation,
                    child: Text(widget.isNavigationActive ? 'Arrêter' : 'Démarrer'),
                  ),
                ),
              ] else ...[
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
            ],
          ),
        ],
      ),
    );
  }

  String? _formatDistance(double meters) {
    if (meters <= 0) return null;
    if (meters >= 1000) {
      final km = meters / 1000;
      final decimals = km >= 10 ? 0 : 1;
      return '${km.toStringAsFixed(decimals)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  Duration _etaFromDistance(double meters) {
    if (meters <= 0) return Duration.zero;
    final km = meters / 1000;
    final hours = km / HomeController.kAverageCourierSpeedKmh;
    final seconds = (hours * 3600).round();
    return Duration(seconds: seconds < 0 ? 0 : seconds);
  }

  String? _formatDuration(Duration duration) {
    if (duration <= Duration.zero) return '< 1 min';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}min';
      }
      return '${hours}h';
    }
    final mins = duration.inMinutes;
    return mins <= 0 ? '< 1 min' : '$mins min';
  }

  String? _formatPrice(double? price) {
    if (price == null) return null;
    return '${price.toStringAsFixed(2)} TND';
  }
}

class _RouteMetrics extends StatelessWidget {
  final String? distance;
  final String? eta;
  final String? price;

  const _RouteMetrics({this.distance, this.eta, this.price});

  @override
  Widget build(BuildContext context) {
    final metrics = <_RouteMetric>[
      if (distance != null)
        _RouteMetric(
          icon: Icons.alt_route,
          label: 'Distance',
          value: distance!,
        ),
      if (eta != null)
        _RouteMetric(
          icon: Icons.timer,
          label: 'Temps restant',
          value: eta!,
        ),
      if (price != null)
        _RouteMetric(
          icon: Icons.payments,
          label: 'Prix',
          value: price!,
        ),
    ];
    if (metrics.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTileWidth = 120.0;
        final bool shouldStack =
            constraints.maxWidth < minTileWidth * metrics.length;
        Widget content;
        if (shouldStack) {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _MetricTile(data: metrics[i]),
              ],
            ],
          );
        } else {
          content = Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: _MetricTile(data: metrics[i])),
              ],
            ],
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: content,
        );
      },
    );
  }
}

class _RouteMetric {
  final IconData icon;
  final String label;
  final String value;

  const _RouteMetric({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _MetricTile extends StatelessWidget {
  final _RouteMetric data;

  const _MetricTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              data.icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              data.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          data.value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
  final bool showContactDetails;

  const _ClientInfos({
    required this.theme,
    required this.user,
    required this.commande,
    required this.isLoading,
    required this.onClose,
    this.showContactDetails = true,
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
    final telDepart =
        _fallback(commande.telDepart, 'Numero depart indisponible');
    final telArrivee =
        _fallback(commande.telArrivee, 'Numero arrivee indisponible');

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
              if (showContactDetails) ...[
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                _InfoLine(label: 'Tel depart', value: telDepart),
                _InfoLine(label: 'Tel arrivee', value: telArrivee),
              ],
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
