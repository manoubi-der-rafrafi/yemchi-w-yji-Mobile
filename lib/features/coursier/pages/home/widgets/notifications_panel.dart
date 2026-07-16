import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/commande/data/commande_service.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/services/client_cache_service.dart';

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
    if (ctrl.isCurrentTransporteurEnPanne &&
        commande.transporteurId == ctrl.currentTransporteurId) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _CommandeSelectionCard(
            key: ValueKey(commande.id),
            commande: commande,
            isMine: ctrl.isSelectedCommandeMine,
            onClose: () {
              final mapState = mapKey.currentState;
              if (mapState != null) {
                mapState
                    .stopNavigation(); // 🛑 Stoppe la navigation avant de fermer
              }
              context
                  .read<HomeController>()
                  .clearSelection(); // 🔚 Ferme le panneau
            },

            onExitNavigation: () {
              mapKey.currentState?.stopNavigation();
            },
            onDetails: () => mapKey.currentState?.openCommandeDetails(commande),
            isNavigationActive: ctrl.isNavigationMode,
            onToggleNavigation:
                ctrl.isSelectedCommandeMine
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
  final VoidCallback onExitNavigation;
  final VoidCallback onDetails;
  final bool isNavigationActive;
  final VoidCallback? onToggleNavigation;

  const _CommandeSelectionCard({
    super.key,
    required this.commande,
    required this.isMine,
    required this.onClose,
    required this.onExitNavigation,
    required this.onDetails,
    required this.isNavigationActive,
    this.onToggleNavigation,
  });

  @override
  State<_CommandeSelectionCard> createState() => _CommandeSelectionCardState();
}

class _CommandeSelectionCardState extends State<_CommandeSelectionCard> {
  final ClientCacheService _clientCacheService = ClientCacheService();
  Utilisateur? _client;
  bool _isClientLoading = true;
  bool _isCalling = false;

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  @override
  void didUpdateWidget(covariant _CommandeSelectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commande.id != widget.commande.id) {
      _loadClient();
    }
  }

  Future<void> _loadClient() async {
    final override = context.read<HomeController>().selectedContactInfo;
    if (override != null) {
      if (!mounted) return;
      setState(() {
        _client = null;
        _isClientLoading = false;
      });
      return;
    }
    final clientId = widget.commande.clientId;
    if (clientId == null || clientId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _client = null;
        _isClientLoading = false;
      });
      return;
    }

    final cached = await _clientCacheService.read(clientId);
    if (!mounted || widget.commande.clientId != clientId) return;
    if (cached != null) {
      setState(() {
        _client = cached;
        _isClientLoading = false;
      });
      unawaited(_refreshClient(clientId));
      return;
    }

    setState(() {
      _client = null;
      _isClientLoading = true;
    });
    await _refreshClient(clientId);
  }

  Future<void> _refreshClient(String clientId) async {
    final service = context.read<AuthUserService>();
    try {
      final user = await service.getById(clientId);
      await _clientCacheService.write(user);
      if (!mounted || widget.commande.clientId != clientId) return;
      setState(() {
        _client = user;
        _isClientLoading = false;
      });
    } catch (_) {
      if (!mounted || widget.commande.clientId != clientId) return;
      setState(() {
        _isClientLoading = false;
      });
    }
  }

  Future<void> _callClient() async {
    if (_isCalling) return;

    final bool departScanne = widget.commande.qrCodeDepartScanne == true;
    final rawNumber =
        departScanne
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
    final contactOverride = homeCtrl.selectedContactInfo;
    final double? distanceMetersFromRoute =
        homeCtrl.currentRouteDistanceMeters ??
        (widget.commande.distanceKm != null
            ? widget.commande.distanceKm! * 1000
            : null);
    final Duration? eta =
        homeCtrl.currentRouteEta ??
        (distanceMetersFromRoute != null
            ? _etaFromDistance(distanceMetersFromRoute)
            : null);
    final distanceText =
        distanceMetersFromRoute != null
            ? _formatDistance(distanceMetersFromRoute)
            : null;
    final durationText = eta != null ? _formatDuration(eta) : null;
    final priceText =
        !widget.isNavigationActive ? _formatPrice(widget.commande.prix) : null;
    final bool hasMetrics =
        distanceText != null || durationText != null || priceText != null;
    final bool showCompleteButton = widget.isMine && widget.isNavigationActive;
    final bool isSecoursCommande = homeCtrl.isCommandeSecours(
      widget.commande.id,
    );
    final bool departScanne = widget.commande.qrCodeDepartScanne == true;
    final bool relaisEffectue =
        widget.commande.relaisTransporteurEffectue == true;
    final String completeLabel =
        isSecoursCommande && departScanne && !relaisEffectue
            ? 'Relais recupere'
            : 'Terminer';

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        widget.isNavigationActive ? 12 : 16,
        16,
        12,
      ),
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
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isNavigationActive) ...[
                if (hasMetrics)
                  Padding(
                    padding: const EdgeInsets.only(right: 36),
                    child: _RouteMetrics(
                      distance: distanceText,
                      eta: durationText,
                      price: priceText,
                    ),
                  ),
                if (hasMetrics) const SizedBox(height: 12),
              ] else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ClientInfos(
                      theme: theme,
                      user: _client,
                      commande: widget.commande,
                      isLoading: _isClientLoading,
                      onClose: widget.onClose,
                      contactOverride: contactOverride,
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
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.isMine) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            widget.isNavigationActive
                                ? () => _callClient()
                                : widget.onDetails,
                        child: Text(
                          widget.isNavigationActive ? 'Appeler' : 'Details',
                        ),
                      ),
                    ),
                    if (!widget.isNavigationActive) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            widget.onToggleNavigation?.call();
                          },
                          child: const Text('Démarrer'),
                        ),
                      ),
                    ],
                    if (showCompleteButton) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final api = context.read<Api>();
                            final service = CommandeService(api);
                            if (isSecoursCommande &&
                                departScanne &&
                                !relaisEffectue) {
                              final updated = await service
                                  .marquerRelaisTransporteurEffectue(
                                    widget.commande.id,
                                  );
                              if (!mounted) return;
                              homeCtrl.updateCommande(updated);
                              homeCtrl.setNavigationMode(false);
                              homeCtrl.clearSelection();
                              return;
                            } else if (departScanne) {
                              final updated = await service
                                  .marquerReceptionScanne(widget.commande.id);
                              if (!mounted) return;
                              homeCtrl.updateCommande(updated);
                              homeCtrl.setNavigationMode(false);
                              homeCtrl.clearSelection();
                              return;
                            } else {
                              final updated = await service.marquerDepartScanne(
                                widget.commande.id,
                              );
                              if (!mounted) return;
                              homeCtrl.updateCommande(updated);
                              homeCtrl.setNavigationMode(false);
                              homeCtrl.clearSelection();
                              return;
                            }
                          },
                          child: Text(
                            completeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
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
          if (widget.isNavigationActive)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: widget.onExitNavigation,
                icon: const Icon(Icons.close, size: 22),
                tooltip: 'Arrêter le suivi',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                visualDensity: VisualDensity.compact,
              ),
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
        _RouteMetric(icon: Icons.timer, label: 'Temps restant', value: eta!),
      if (price != null)
        _RouteMetric(icon: Icons.payments, label: 'Prix', value: price!),
    ];
    if (metrics.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: _MetricTile(data: metrics[i])),
          ],
        ],
      ),
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
            Icon(data.icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                data.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
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
  final SelectedContactInfo? contactOverride;

  const _ClientInfos({
    required this.theme,
    required this.user,
    required this.commande,
    required this.isLoading,
    required this.onClose,
    this.contactOverride,
  });

  String _fallback(String? value, String fallback) {
    if (value == null) return fallback;
    final clean = value.trim();
    return clean.isEmpty ? fallback : clean;
  }

  @override
  Widget build(BuildContext context) {
    final parts =
        [user?.prenom, user?.nom]
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    final fullName =
        contactOverride?.displayName.trim().isNotEmpty == true
            ? contactOverride!.displayName.trim()
            : (parts.isNotEmpty ? parts.join(' ') : 'Utilisateur inconnu');

    final telDepart = _fallback(
      contactOverride?.phoneDepart ?? commande.telDepart,
      'Numero depart indisponible',
    );
    final telArrivee = _fallback(
      contactOverride?.phoneArrivee ?? commande.telArrivee,
      'Numero arrivee indisponible',
    );

    final imageUrl = (contactOverride?.imageUrl ?? user?.image)?.trim();
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
        backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
        child:
            hasImage
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
                : Icon(Icons.person, color: theme.colorScheme.primary),
      ),
    );

    final statusColor =
        contactOverride != null
            ? (contactOverride!.isActive ? Colors.green : Colors.redAccent)
            : (user?.statut == Statut.actif ? Colors.green : Colors.redAccent);

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
              LayoutBuilder(
                builder: (context, constraints) {
                  const minColumnWidth = 220.0;
                  final bool shouldStack =
                      constraints.maxWidth < minColumnWidth * 2;
                  if (shouldStack) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoLine(label: 'Tel depart', value: telDepart),
                        const SizedBox(height: 6),
                        _InfoLine(label: 'Tel arrivee', value: telArrivee),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _InfoLine(label: 'Tel depart', value: telDepart),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoLine(
                          label: 'Tel arrivee',
                          value: telArrivee,
                        ),
                      ),
                    ],
                  );
                },
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
