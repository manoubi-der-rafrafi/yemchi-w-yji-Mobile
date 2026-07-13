import 'package:flutter/material.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/produit.dart';
import 'package:yemchi_wyji/features/produit/data/produit_service.dart';

class CommandeProduitsPage extends StatefulWidget {
  final Commande commande;

  const CommandeProduitsPage({super.key, required this.commande});

  @override
  State<CommandeProduitsPage> createState() => _CommandeProduitsPageState();
}

class _CommandeProduitsPageState extends State<CommandeProduitsPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits de la commande'),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
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
      return Center(
        child: Text(
          'Aucun produit associe a cette commande.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: _produits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final produit = _produits[index];
        return _ProduitTile(produit: produit);
      },
    );
  }
}

class _ProduitTile extends StatelessWidget {
  final Produit produit;

  const _ProduitTile({required this.produit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quantityLabel =
        produit.quantite != null ? '${produit.quantite}' : '-';

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
                  'Quantite : $quantityLabel',
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
        errorBuilder:
            (_, __, ___) => _PlaceholderImage(theme: theme, size: size),
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
