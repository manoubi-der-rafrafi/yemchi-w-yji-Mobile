import 'package:flutter/material.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/produit.dart';
import 'package:yemchi_wyji/features/produit/data/produit_service.dart';

class CommandeDetailsSheet extends StatefulWidget {
  final Commande commande;

  const CommandeDetailsSheet({super.key, required this.commande});

  @override
  State<CommandeDetailsSheet> createState() => _CommandeDetailsSheetState();
}

class _CommandeDetailsSheetState extends State<CommandeDetailsSheet> {
  final ProduitService _produitService = ProduitService();

  bool _isLoading = true;
  List<Produit> _produits = const <Produit>[];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProduits();
  }

  Future<void> _fetchProduits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final produits =
          await _produitService.getByCommande(widget.commande.id);
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

  void _onAccepter() {
    Navigator.of(context).maybePop(true);
  }

  void _onRefuser() {
    Navigator.of(context).maybePop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Liste des produits',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: _buildProduitsSection(theme),
            ),
            const SizedBox(height: 20),
            Row(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitsSection(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
      );
    }

    if (_produits.isEmpty) {
      return Center(
        child: Text(
          'Aucun produit trouve pour cette commande.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
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
}

class _ProduitTile extends StatelessWidget {
  final Produit produit;
  final VoidCallback onDetails;

  const _ProduitTile({
    required this.produit,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quantite = produit.quantite;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
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
          _ProduitImage(imageUrl: produit.image1),
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

class _ProduitImage extends StatelessWidget {
  final String? imageUrl;

  const _ProduitImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const double size = 64;
    final theme = Theme.of(context);

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _PlaceholderImage(theme: theme, size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _PlaceholderImage(theme: theme, size: size),
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
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
