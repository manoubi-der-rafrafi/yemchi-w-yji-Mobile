import 'package:flutter/material.dart';
import '../services/cilent_service.dart'; // Update with your actual path
import '../models/produit.dart'; // Update with your actual path

class LivrerPage extends StatefulWidget {
  const LivrerPage({super.key});

  @override
  State<LivrerPage> createState() => _LivrerPageState();
}

class _LivrerPageState extends State<LivrerPage> {
  bool isLoading = false;
  String? loadError;
  List<Produit> produits = [];

  final ProduitService _service = ProduitService();

  @override
  void initState() {
    super.initState();
    _loadProduits();
  }

  Future<void> _loadProduits() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final produitsList = await _service.getAll();
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

  void GoAjoutProduitClient() {
    // Example: route to add product page or open dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ajoutez un produit!")),
    );
  }

  void detailProduit(Produit produit) {
    // Example: show product details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Détail: ${produit.nom}')),
    );
  }

  Future<void> supprimerProduit(Produit produit) async {
    try {
      await _service.delete(produit.id);
      setState(() {
        produits.removeWhere((p) => p.id == produit.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  void confirmerCommande() {
    // Example: call API to confirm order if required
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Commande confirmée!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits Pour Livrer'),
        centerTitle: true,
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
          Text("Veuillez patienter.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("⚠️", style: TextStyle(fontSize: 48)),
          const SizedBox(height: 18),
          const Text("Oups, un problème est survenu",
              style: TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(loadError ?? "",
              style: const TextStyle(color: Colors.red, fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: GoAjoutProduitClient,
            child: const Text("Ajouter un produit"),
          ),
        ],
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
          const Text(
            "Ajoutez votre premier produit pour démarrer votre commande.\nVous pourrez ensuite ajuster les quantités et confirmer.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: GoAjoutProduitClient,
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
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            "Gérez votre commande ici avant de confirmer",
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: produits.length,
            itemBuilder: (ctx, i) {
              final produit = produits[i];
              return Card(
                child: ListTile(
                  leading: Image.network(
                  produit.image1,
                  width: 48,
                  height: 48,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.broken_image, size: 48), // or local asset
                ),
                  title: Text(produit.nom),
                  subtitle: Text(produit.type),
                  trailing: SizedBox(
                    width: 120,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SizedBox(
                            width: 48,
                            child: TextFormField(
                              initialValue: produit.quantite.toString(),
                              keyboardType: TextInputType.number,
                              onChanged: (v) async {
                                final int? n = int.tryParse(v);
                                if (n != null && n > 0) {
                                  setState(() {
                                    produit.quantite = n;
                                  });
                                  // If you want to update on server:
                                  // await _service.update(produit.id, produit.toJson());
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: "Qté",
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          tooltip: "DÉTAIL",
                          onPressed: () => detailProduit(produit),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: "SUPPRIMER",
                          onPressed: () => supprimerProduit(produit),
                        ),
                      ],
                    ),
                  ),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: GoAjoutProduitClient,
              child: const Text("AJOUTER UN PRODUIT"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: hasProduits() ? confirmerCommande : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("CONFIRMER COMMANDE"),
            ),
          ),
        ],
      ),
    );
  }
}
