// ConfirmationCommandePage.dart
import 'package:flutter/material.dart';
import '../services/cilent_service.dart'; // Importez votre service
import '../models/commande.dart'; // Importez votre modèle Commande

// Note: Pour une implémentation complète des cartes/géoloc/autocomplete,
// vous aurez besoin de packages supplémentaires (ex: geolocator, flutter_map, etc.).
// Ici, les boutons de géoloc/carte sont des stubs pour suivre la logique du front-end.

class ConfirmationCommandePage extends StatefulWidget {
  final String commandeId; // L'ID de la commande en cours

  const ConfirmationCommandePage({super.key, required this.commandeId});

  @override
  State<ConfirmationCommandePage> createState() =>
      _ConfirmationCommandePageState();
}

class _ConfirmationCommandePageState extends State<ConfirmationCommandePage> {
  final CommandeService _commandeService = CommandeService();
  int step = 1;
  bool isLoading = false;
  String? loadError;

  // --- Contrôleurs de formulaire ---
  final TextEditingController _departCtrl = TextEditingController();
  final TextEditingController _telDepartCtrl = TextEditingController();
  final TextEditingController _destinationCtrl = TextEditingController();
  final TextEditingController _telArriveeCtrl = TextEditingController();

  // Modèle de commande pour pré-remplissage et état (facultatif mais recommandé)
  Commande? _commande;

  // Étape 3: Mode de paiement
  String _modePaiement = 'en_ligne';
  String? _initialClientId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Pré-chargement des détails de commande pour pré-remplir les champs
  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      // Vous devez ajouter un getById(id) à votre CommandeService si ce n'est pas fait
      // Mais pour le flow, on peut assumer que la commande existe.
      // Appel d'API pour récupérer la commande complète:
      // _commande = await _commandeService.getById(widget.commandeId);

      // Simule un pré-remplissage (si votre API le permet)
      //_departCtrl.text = _commande?.localisation_depart ?? ""; // Si déjà stocké
      //_telDepartCtrl.text = _commande?.telDepart ?? "216xxxxxxx"; // Numéro client par défaut
    } catch (e) {
      loadError = "Impossible de charger les détails initiaux.";
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- Navigation & Validation ---

  bool _isStep1Valid() {
    return _departCtrl.text.trim().length > 3 &&
        _telDepartCtrl.text.trim().isNotEmpty &&
        RegExp(r'^\+?\d{6,15}$').hasMatch(_telDepartCtrl.text.trim());
  }

  bool _isStep2Valid() {
    // Version simplifiée (pas de mode ami)
    return _destinationCtrl.text.trim().length > 3 &&
        _telArriveeCtrl.text.trim().isNotEmpty &&
        RegExp(r'^\+?\d{6,15}$').hasMatch(_telArriveeCtrl.text.trim());
  }

  void goToNextStep() {
    if (step == 1 && !_isStep1Valid()) return;
    if (step == 2 && !_isStep2Valid()) return;

    setState(() {
      step = step < 3 ? step + 1 : 3;
    });
  }

  void goToPreviousStep() {
    setState(() {
      step = step > 1 ? step - 1 : 1;
    });
  }

  // --- Action Finale (Appel API) ---
  Future<void> finalConfirmation() async {
    // Valide le mode de paiement à l'étape 3
    if (_modePaiement.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir un mode de paiement.')),
      );
      return;
    }

    setState(() => isLoading = true);

    // 1. Construire le payload final (équivalent à this.buildCommandeFromForm() du front)
    final payload = {
      // Étape 1
      'localisation_depart': _departCtrl.text.trim(),
      'telDepart': _telDepartCtrl.text.trim(),
      // Étape 2
      'destination': _destinationCtrl.text.trim(),
      'telArrivee': _telArriveeCtrl.text.trim(),
      // Étape 3
      'mode_paiement': _modePaiement,

      // Statut crucial pour la confirmation finale
      'statut': 'confirmer',
      // Inclure les autres champs non modifiables si nécessaire (ex: clientId, prix)
      // Si votre API ne requiert que les champs modifiés, ces 6 champs suffisent.
    };

    try {
      // 2. Appel API de mise à jour/confirmation
      // Le service utilise l'ID de la commande et envoie le payload
      await _commandeService.updateCommande(widget.commandeId, payload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Commande confirmée avec succès !')),
      );

      // 3. Ferme la page et retourne 'true' (équivalent au router.navigate(['/panier']) du front)
      // 'true' indique à LivrerPage de recharger/vider le panier
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur confirmation finale: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confirmer ma commande - Étape $step/3')),
      body:
          isLoading && _commande == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStepper(),
                    const SizedBox(height: 30),

                    // Contenu basé sur l'étape
                    if (step == 1) _buildStep1(),
                    if (step == 2) _buildStep2(),
                    if (step == 3) _buildStep3(),

                    const SizedBox(height: 50),
                    _buildActions(),
                  ],
                ),
              ),
    );
  }

  // --- Widgets de construction ---

  Widget _buildStepper() {
    // Simule la barre de progression (très simplifiée)
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _stepperNode(1, "Départ", step),
        _stepperBar(step > 1),
        _stepperNode(2, "Arrivée", step),
        _stepperBar(step > 2),
        _stepperNode(3, "Paiement", step),
      ],
    );
  }

  Widget _stepperNode(int num, String label, int currentStep) {
    final isDone = currentStep > num;
    final isCurrent = currentStep == num;
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor:
              isCurrent
                  ? Colors.blue
                  : isDone
                  ? Colors.green
                  : Colors.grey.shade300,
          child: Text(
            '$num',
            style: TextStyle(
              color: isCurrent || isDone ? Colors.white : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? Colors.blue : Colors.black,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _stepperBar(bool filled) {
    return Expanded(
      child: Container(
        height: 2,
        color: filled ? Colors.green : Colors.grey.shade300,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Adresse de départ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _departCtrl,
                decoration: const InputDecoration(
                  hintText: "Rue, ville, code postal",
                ),
                validator:
                    (v) => (v?.length ?? 0) < 4 ? "Adresse obligatoire." : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
            // Stubs pour la géolocalisation
            IconButton(
              onPressed: () => print("TODO: Geoloc depart"),
              icon: const Icon(Icons.location_on),
            ),
            IconButton(
              onPressed: () => print("TODO: Map Picker depart"),
              icon: const Icon(Icons.map),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          "Numéro de départ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _telDepartCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: "+216 ..."),
                validator:
                    (v) =>
                        RegExp(r'^\+?\d{6,15}$').hasMatch(v ?? '')
                            ? null
                            : "Numéro invalide.",
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
            TextButton.icon(
              onPressed: () => print("TODO: Utiliser mon numéro"),
              icon: const Icon(Icons.phone),
              label: const Text("Utiliser mon numéro"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    // Mode simplifié: seulement les champs classiques (destination et tel)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TODO: Ajouter la logique complexe de "Envoyer à un ami" si nécessaire.
        Text(
          "Adresse d’arrivée",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _destinationCtrl,
                decoration: const InputDecoration(
                  hintText: "Rue, ville, code postal",
                ),
                validator:
                    (v) => (v?.length ?? 0) < 4 ? "Adresse obligatoire." : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
            // Stubs
            IconButton(
              onPressed: () => print("TODO: Map Picker arrivee"),
              icon: const Icon(Icons.map),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          "Numéro d’arrivée",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        TextFormField(
          controller: _telArriveeCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: "+216 ..."),
          validator:
              (v) =>
                  RegExp(r'^\+?\d{6,15}$').hasMatch(v ?? '')
                      ? null
                      : "Numéro invalide.",
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Mode de paiement",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        _buildPaymentOption(
          'en_ligne',
          '💳 Paiement en ligne',
          'Recommandé: Carte bancaire / wallet sécurisé',
        ),
        _buildPaymentOption(
          'depart',
          '🏁 Au départ',
          'Remise au livreur avant le trajet',
        ),
        _buildPaymentOption(
          'arrivee',
          '📦 À l’arrivée',
          'Pratique: Paiement lors de la livraison',
        ),

        // Mini Récap (comme sur le front-end Angular)
        const SizedBox(height: 30),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecapRow("Départ", _departCtrl.text),
                _buildRecapRow("Arrivée", _destinationCtrl.text),
                _buildRecapRow("Paiement", _getPaymentLabel(_modePaiement)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String value, String title, String subtitle) {
    return Card(
      color: _modePaiement == value ? Colors.blue.shade50 : null,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight:
                _modePaiement == value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Radio<String>(
          value: value,
          groupValue: _modePaiement,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _modePaiement = newValue);
            }
          },
        ),
        onTap: () {
          setState(() => _modePaiement = value);
        },
      ),
    );
  }

  String _getPaymentLabel(String value) {
    switch (value) {
      case 'en_ligne':
        return 'En ligne';
      case 'depart':
        return 'Au départ';
      case 'arrivee':
        return 'À l’arrivée';
      default:
        return '-';
    }
  }

  Widget _buildRecapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text("$label :", style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (step > 1)
          TextButton(onPressed: goToPreviousStep, child: const Text("Retour")),

        const Spacer(),

        if (step < 3)
          ElevatedButton(
            onPressed: isLoading ? null : goToNextStep,
            child: const Text("Suivant"),
          ),

        if (step == 3)
          ElevatedButton(
            onPressed: isLoading ? null : finalConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            child:
                isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text("✔ Confirmer"),
          ),
      ],
    );
  }
}
