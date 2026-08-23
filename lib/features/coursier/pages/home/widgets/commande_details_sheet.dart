import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/produit.dart';
import 'package:yemchi_wyji/core/media/product_image_url.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/commande/data/commande_service.dart';
import 'package:yemchi_wyji/features/produit/data/produit_service.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/controllers/home_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class CommandeDetailsSheet extends StatefulWidget {
  final Commande commande;
  final bool isMine;

  const CommandeDetailsSheet({
    super.key,
    required this.commande,
    required this.isMine,
  });

  @override
  State<CommandeDetailsSheet> createState() => _CommandeDetailsSheetState();
}

class _CommandeDetailsSheetState extends State<CommandeDetailsSheet> {
  final ProduitService _produitService = ProduitService();

  bool _isLoading = true;
  bool _accepted = false;
  bool _departCalled = false;
  bool _arriveeCalled = false;
  List<Produit> _produits = const <Produit>[];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _accepted = widget.isMine;
    _fetchProduits();
    _hydrateCallStateFromStatus();
  }

  void _hydrateCallStateFromStatus() {
    final statut = widget.commande.statut?.trim().toLowerCase();
    if (statut == 'appelle_client_1') {
      _departCalled = true;
      _arriveeCalled = _hasSameContactNumber;
    } else if (statut == 'appelle_client_2') {
      _departCalled = true;
      _arriveeCalled = true;
    }
  }

  bool get _hasSameContactNumber {
    final telDepart = widget.commande.telDepart?.trim();
    final telArrivee = widget.commande.telArrivee?.trim();
    return telDepart != null && telDepart.isNotEmpty && telDepart == telArrivee;
  }

  Future<void> _fetchProduits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final produits = await _produitService.getByCommande(widget.commande.id);
      if (!mounted) return;
      setState(() {
        _produits = produits;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Impossible de recuperer les produits pour cette commande. ($error)';
      });
    }
  }

  void _onProduitDetails(Produit produit) {
    debugPrint('Afficher le detail du produit ${produit.id}');
  }

  void _onAccepter() async {
    final homeCtrl = context.read<HomeController>();
    if (homeCtrl.isFinanciallyBlocked) {
      final restant = homeCtrl.statutFinancier?.paiementRestant ?? 0;
      _showSnack(
        'Nouvelles commandes bloquees. Paiement restant: ${restant.toStringAsFixed(3)} DT.',
      );
      return;
    }
    final auth = context.read<AuthController>();
    final currentUserId = auth.currentUser.value?.id;

    if (currentUserId == null) {
      debugPrint('Aucun utilisateur courant -> assignation impossible.');
      return;
    }

    try {
      final api = context.read<Api>();
      final service = CommandeService(api);
      final transporteurPanneId = homeCtrl.getTransporteurPanneIdForCommande(
        widget.commande.id,
      );

      final updated =
          transporteurPanneId != null
              ? await service.assignerTransporteurSecours(
                widget.commande.id,
                currentUserId,
              )
              : await service.assignerTransporteur(
                widget.commande.id,
                currentUserId,
              );

      if (!mounted) return;
      homeCtrl.moveToMesCommandes(updated);
      homeCtrl.setNavigationMode(false);
      if (transporteurPanneId != null) {
        homeCtrl.clearSelection();
        Navigator.of(context).maybePop(true);
        return;
      }
      setState(() {
        _accepted = true;
      });
    } on StateError catch (e) {
      if (!mounted) return;
      _showSnack(e.message);
    } on ArgumentError catch (e) {
      if (!mounted) return;
      _showSnack(e.message?.toString() ?? 'Erreur de donnees.');
    } on ApiException catch (e) {
      debugPrint(
        'Erreur assignation transporteur (${e.statusCode}): ${e.message}',
      );
      if (!mounted) return;
      _showSnack(
        e.message.trim().isEmpty
            ? 'Erreur assignation transporteur.'
            : e.message,
      );
    } catch (e) {
      debugPrint('Erreur assignation transporteur: $e');
      if (!mounted) return;
      _showSnack('Erreur assignation transporteur.');
    }
  }

  void _onRefuser() {
    Navigator.of(context).maybePop(false);
  }

  Future<void> _callNumber(String? raw) async {
    final number = raw?.trim();
    if (number == null || number.isEmpty) {
      _showSnack('Numero introuvable.');
      return;
    }
    try {
      final uri = Uri.parse('tel:$number');
      if (!await launchUrl(uri)) {
        _showSnack('Impossible de lancer l\'appel');
      }
    } catch (_) {
      _showSnack('Impossible de lancer l\'appel');
    }
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _callDepart() async {
    await _callNumber(widget.commande.telDepart);
    if (!mounted) return;
    try {
      final api = context.read<Api>();
      final service = CommandeService(api);
      var updated = await service.demarrerAppelClient1(widget.commande.id);
      if (_hasSameContactNumber) {
        // Un seul appel couvre le depart et l'arrivee. Avancer aussi le statut
        // du premier contact pour permettre la confirmation de la reponse.
        updated = await service.marquerAppelClient1(widget.commande.id);
      }
      if (mounted) {
        context.read<HomeController>().updateCommande(updated);
      }
    } catch (e) {
      debugPrint('Erreur debut appel client 1: $e');
      _showSnack('Erreur debut appel client 1.');
    }
    setState(() {
      _departCalled = true;
      if (_hasSameContactNumber) {
        _arriveeCalled = true;
      }
    });
  }

  Future<void> _callArrivee() async {
    await _callNumber(widget.commande.telArrivee);
    if (!mounted) return;
    try {
      final api = context.read<Api>();
      final service = CommandeService(api);
      final updated = await service.marquerAppelClient1(widget.commande.id);
      if (mounted) {
        context.read<HomeController>().updateCommande(updated);
      }
      setState(() {
        _arriveeCalled = true;
      });
    } catch (e) {
      debugPrint('Erreur marquer appel client 1: $e');
      _showSnack('Erreur appel client 1.');
    }
  }

  Future<void> _markNonReponse({required bool sameNumber}) async {
    if (!_departCalled) return;
    try {
      final api = context.read<Api>();
      final service = CommandeService(api);
      Commande updated;
      if (sameNumber) {
        updated = await service.marquerNonReponseClient1(widget.commande.id);
      } else if (_arriveeCalled) {
        updated = await service.marquerNonReponseClient2(widget.commande.id);
      } else {
        updated = await service.marquerNonReponseClient1(widget.commande.id);
      }
      if (mounted) {
        context.read<HomeController>().updateCommande(updated);
      }
    } catch (e) {
      debugPrint('Erreur marquer non reponse: $e');
      _showSnack('Erreur non reponse.');
    }
  }

  Future<void> _confirmNonReponse({required bool sameNumber}) async {
    if (!_departCalled) return;
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verification requise'),
          content: const Text(
            'Cette commande sera verifiee avec l\'administration avant toute suite.'
            ' Merci de confirmer la non-reponse du client.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuer'),
            ),
          ],
        );
      },
    );

    if (shouldContinue == true) {
      await _markNonReponse(sameNumber: sameNumber);
    }
  }

  Future<void> _markReponseArrivee() async {
    if (!_arriveeCalled) return;
    try {
      final api = context.read<Api>();
      final service = CommandeService(api);
      final updated = await service.marquerAppelClient2(widget.commande.id);
      if (mounted) {
        context.read<HomeController>().updateCommande(updated);
      }
      if (!mounted) return;
      final homeCtrl = context.read<HomeController>();
      homeCtrl.setNavigationMode(false);
      homeCtrl.clearSelection();
      Navigator.of(context).maybePop(true);
    } catch (e) {
      debugPrint('Erreur marquer appel client 2: $e');
      _showSnack('Erreur appel client 2.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModePaiementBadge(
                label: _modePaiementLabel(widget.commande.modePaiement),
                color: _modePaiementColor(widget.commande.modePaiement),
              ),
              const SizedBox(height: 16),
              Text(
                'Liste des produits',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildProduitsSection(theme)),
              const SizedBox(height: 20),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final statut = widget.commande.statut?.trim().toLowerCase();
    final isNonRepond =
        statut == 'non_repondre_client_1' || statut == 'non_repondre_client_2';
    final isCallFlow =
        statut == 'en_appelle' ||
        statut == 'appelle_client_1' ||
        statut == 'appelle_client_2';

    if (isNonRepond) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cette commande est en attente de verification. Merci de patienter.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Continuer'),
            ),
          ),
        ],
      );
    }

    if (isCallFlow || widget.isMine || _accepted) {
      final bool sameNumber = _hasSameContactNumber;
      final bool canCallDepart = true;
      final bool canCallArrivee =
          _departCalled ||
          statut == 'appelle_client_1' ||
          statut == 'appelle_client_2';
      final bool canMarkNonReponse =
          _departCalled ||
          statut == 'appelle_client_1' ||
          statut == 'appelle_client_2';
      final bool canMarkReponse =
          _arriveeCalled || statut == 'appelle_client_2';
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: canCallDepart ? _callDepart : null,
                  child: Text(
                    sameNumber ? 'Appeler depart et arrivee' : 'Appeler depart',
                  ),
                ),
              ),
              if (!sameNumber) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: canCallArrivee ? _callArrivee : null,
                    child: const Text('Appeler arrivee'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: canMarkReponse ? _markReponseArrivee : null,
                  child: const Text('Numero repondu'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      canMarkNonReponse
                          ? () => _confirmNonReponse(sameNumber: sameNumber)
                          : null,
                  child: const Text('Numero non repondu'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _onRefuser,
            child: const Text('Refuser'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _onAccepter,
            child: const Text('Accepter'),
          ),
        ),
      ],
    );
  }

  Widget _buildProduitsSection(ThemeData theme) {
    if (_isLoading) {
      return const Align(
        alignment: Alignment.center,
        heightFactor: 1,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Align(
        alignment: Alignment.center,
        heightFactor: 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _fetchProduits,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    if (_produits.isEmpty) {
      return Align(
        alignment: Alignment.center,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Aucun produit trouve pour cette commande.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: _produits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final produit = _produits[index];
        return _ProduitTile(
          produit: produit,
          onDetails: () => _onProduitDetails(produit),
        );
      },
    );
  }

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
        return Colors.green;
      case 'depart':
        return Colors.orange;
      case 'arrivee':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }
}

class _ProduitTile extends StatelessWidget {
  final Produit produit;
  final VoidCallback onDetails;

  const _ProduitTile({required this.produit, required this.onDetails});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quantite = produit.quantite;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _ProduitImage(
            imageUrls: [produit.image1, produit.image2, produit.image3],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Quantite: ${quantite ?? '-'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: onDetails,
              child: const Text('Detail'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePaiementBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ModePaiementBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          'Mode de paiement :',
          style: theme.textTheme.bodyMedium?.copyWith(
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

class _ProduitImage extends StatelessWidget {
  final List<String?> imageUrls;

  const _ProduitImage({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    const double size = 64;
    final theme = Theme.of(context);
    String? resolvedUrl;
    for (final imageUrl in imageUrls) {
      resolvedUrl = ProductImageUrl.resolve(imageUrl);
      if (resolvedUrl != null) break;
    }

    if (resolvedUrl == null) {
      return _PlaceholderImage(theme: theme, size: size);
    }
    final displayUrl = resolvedUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        displayUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) {
          final host = Uri.tryParse(displayUrl)?.host ?? 'hote inconnu';
          debugPrint('Image produit inaccessible ($host): $error');
          return _PlaceholderImage(theme: theme, size: size);
        },
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final ThemeData theme;
  final double size;

  const _PlaceholderImage({required this.theme, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceVariant,
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
