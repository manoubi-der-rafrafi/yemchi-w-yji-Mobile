import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Update these paths to match your project structure
import 'package:yemchi_wyji/features/client/pages/AjoutProduitPage.dart'; 
import '../services/cilent_service.dart'; // This is the file you just created (ServiceComplet.dart)
import '../models/produit.dart'; 
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'ConfirmationCommandePage.dart';

class LivrerPage extends StatefulWidget {
  const LivrerPage({super.key});

  @override
  State<LivrerPage> createState() => _LivrerPageState();
}

class _LivrerPageState extends State<LivrerPage> {
  bool isLoading = false;
  String? loadError;
  List<Produit> produits = [];
  String? currentCommandeId; // Store the active cart ID here

  // Use the service we created (ensure the file name matches your import)
  final ProduitService _produitService = ProduitService();
  final CommandeService _commandeService = CommandeService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final userId = Provider.of<AuthController>(context, listen: false).currentUser.value?.id;
      if (userId == null) {
        throw Exception('Utilisateur non connecté.');
      }

      // 1. Get or create the active command to ensure we have an ID
      final commande = await _commandeService.getOrCreateActiveCommande(userId);
      currentCommandeId = commande.id;

      // 2. Fetch products associated with this command
      // We can use the helper method or fetch directly by ID since we have it now
      final produitsList = await _produitService.getByCommande(commande.id);

      setState(() {
        produits = produitsList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        loadError = e.toString();
        isLoading = false;
      });
    }
  }

  bool hasProduits() => produits.isNotEmpty;

  void goAjoutProduitClient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.95,
          child: const AjoutProduitPage(),
        ),
      ),
      useSafeArea: true,
    ).then((_) => _loadData()); // Reload after closing sheet
  }

  void detailProduit(Produit produit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(produit.nom ?? 'Produit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((produit.image1 ?? '').isNotEmpty)
              Image.network(
                produit.image1!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
              ),
            const SizedBox(height: 10),
            Text("Type: ${produit.type ?? '-'}"),
            Text("Quantité: ${produit.quantite}"),
            if (produit.poids != null) Text("Poids: ${produit.poids} kg"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fermer"),
          )
        ],
      ),
    );
  }

  Future<void> supprimerProduit(Produit produit) async {
    try {
      await _produitService.delete(produit.id);
      setState(() {
        produits.removeWhere((p) => p.id == produit.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit supprimé du panier')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Future<void> updateQuantite(Produit produit, int nouvelleQuantite) async {
    try {
      setState(() {
        produit.quantite = nouvelleQuantite;
      });
      await _produitService.update(produit.id, {'quantite': nouvelleQuantite});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur maj quantité: ${e.toString()}')),
      );
    }
  }

  Future<void> confirmerCommande() async {
    if (currentCommandeId == null) return;
    /*
    try {
      setState(() => isLoading = true);
      await _commandeService.confirmerCommande(currentCommandeId!);
      
      setState(() {
        produits.clear();
        currentCommandeId = null;
        isLoading = false;
      });

      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Succès"),
          content: const Text("Votre commande a été confirmée avec succès !"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _loadData(); // Start a new fresh cart
              },
              child: const Text("OK"),
            )
          ],
        ),
      );

    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur confirmation: $e")),
      );
    }*/
    goToConfirmationPage();
  }

 void goToConfirmationPage() {
    if (currentCommandeId == null || !hasProduits()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter des produits d\'abord.')),
      );
      return;
    }

    // Navigue vers la nouvelle page en passant l'ID de la commande active
     Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfirmationCommandePage(commandeId: currentCommandeId!), 
      ),
    ).then((result) {
      // Si la confirmation finale a réussi sur la page suivante (result est true)
      if (result == true) { // <-- Si ConfirmationCommandePage pop(true)
        _loadData(); // <-- Recharge la page
      }
    }); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits Pour Livrer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : loadError != null
              ? _buildErrorState()
              : hasProduits()
                  ? _buildContentState()
                  : _buildEmptyState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text("🛒", style: TextStyle(fontSize: 48)),
          SizedBox(height: 18),
          Text("Chargement du panier…", style: TextStyle(fontSize: 24)),
          SizedBox(height: 8),
          CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("⚠️", style: TextStyle(fontSize: 48)),
            const SizedBox(height: 18),
            const Text("Oups, un problème est survenu",
                style: TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(loadError ?? "Erreur inconnue",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text("Réessayer"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🛒", style: TextStyle(fontSize: 48)),
          const SizedBox(height: 18),
          const Text("Votre panier est vide",
              style: TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              "Ajoutez votre premier produit pour démarrer votre commande.\nVous pourrez ensuite ajuster les quantités et confirmer.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: goAjoutProduitClient,
            child: const Text("+ Ajouter un produit"),
          ),
        ],
      ),
    );
  }

  Widget _buildContentState() {
    return Column(
      children: [
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Gérez votre commande ici avant de confirmer",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: produits.length,
            itemBuilder: (ctx, i) {
              final produit = produits[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: (produit.image1 ?? '').isNotEmpty
                        ? Image.network(
                            produit.image1!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          )
                        : const Icon(Icons.inventory_2, size: 48, color: Colors.grey),
                  ),
                  title: Text(produit.nom ?? 'Produit', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${produit.type} \nRef: ${produit.id.substring(0, 4)}..."),
                  trailing: SizedBox(
                    width: 140,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                          onPressed: () {
                            if (produit.quantite > 1) {
                              updateQuantite(produit, produit.quantite - 1);
                            }
                          },
                        ),
                        Text("${produit.quantite}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                          onPressed: () {
                            updateQuantite(produit, produit.quantite + 1);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => supprimerProduit(produit),
                        ),
                      ],
                    ),
                  ),
                  onTap: () => detailProduit(produit),
                ),
              );
            },
          ),
        ),
        _buildResumeCommande(),
      ],
    );
  }

  Widget _buildResumeCommande() {
    final total = produits.fold<double>(
      0,
      (sum, p) => sum + (p.prix ?? p.prixUnitaire ?? 0) * p.quantite,
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (total > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total estimé', style: TextStyle(color: Colors.grey)),
                  Text(
                    '${total.toStringAsFixed(2)} TND',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: goAjoutProduitClient,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text("AJOUTER"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: hasProduits() ? goToConfirmationPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                  ),
                  child: const Text("CONFIRMER COMMANDE", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
