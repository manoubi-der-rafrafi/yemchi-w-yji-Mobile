// ConfirmationCommandePage.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import '../services/cilent_service.dart'; // Importez votre service
import 'package:yemchi_wyji/core/models/commande.dart'; 
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/amis/data/amis_service.dart';
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';
import 'package:yemchi_wyji/core/network/api.dart';// Importez votre modèle Commande
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Note: Pour une implémentation complète des cartes/géoloc/autocomplete, 
// vous aurez besoin de packages supplémentaires (ex: geolocator, flutter_map, etc.). 
// Ici, les boutons de géoloc/carte sont des stubs pour suivre la logique du front-end.

class ConfirmationCommandePage extends StatefulWidget {
  final String commandeId; // L'ID de la commande en cours

  const ConfirmationCommandePage({super.key, required this.commandeId});

  @override
  State<ConfirmationCommandePage> createState() => _ConfirmationCommandePageState();
}

class _ConfirmationCommandePageState extends State<ConfirmationCommandePage> {
  final CommandeService _commandeService = CommandeService();
  final AmiService _amiService = AmiService();
  late final AuthUserService _authUserService;
  int step = 1;
  bool isLoading = false;
  String? loadError;
  Utilisateur? currentUser;
  
  // --- Contrôleurs de formulaire ---
  final TextEditingController _departCtrl = TextEditingController();
  final TextEditingController _telDepartCtrl = TextEditingController();
  final TextEditingController _destinationCtrl = TextEditingController();
  final TextEditingController _telArriveeCtrl = TextEditingController();
  final TextEditingController _amiIdentifiantCtrl = TextEditingController();
  
  // Modèle de commande pour pré-remplissage et état (facultatif mais recommandé)
  Commande? _commande; 
  
  // Étape 3: Mode de paiement
  String _modePaiement = 'en_ligne'; 
  String? _initialClientId; 
  bool _envoyerAmi = false;
  bool _sharePending = false;
  String? _pendingFriendLabel;
  Utilisateur? _selectedFriend;
  List<Utilisateur> _friendResults = [];
  bool _friendSearchLoading = false;
  String? _friendError;
  Timer? _friendDebounce;

  final MapController _mapController = MapController();
  LatLng _mapCenter = const LatLng(36.8065, 10.1815);
  LatLng? _selectedLatLng;
  String? _reverseAddress;
  bool _reverseLoading = false;
  String? _mapError;
  String _mapTarget = 'depart';
  bool _locatingDepart = false;


  @override
  void initState() {
    super.initState();
    _authUserService = AuthUserService(Api());
    _loadInitialData();
  }

  @override
  void dispose() {
    _departCtrl.dispose();
    _telDepartCtrl.dispose();
    _destinationCtrl.dispose();
    _telArriveeCtrl.dispose();
    _amiIdentifiantCtrl.dispose();
    _friendDebounce?.cancel();
    super.dispose();
  }
  
  // Pré-chargement des détails de commande pour pré-remplir les champs
  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
    currentUser = authController.currentUser.value;
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
    if (_envoyerAmi) {
      return _selectedFriend != null;
    }
    return _destinationCtrl.text.trim().length > 3 && 
           _telArriveeCtrl.text.trim().isNotEmpty &&
           RegExp(r'^\+?\d{6,15}$').hasMatch(_telArriveeCtrl.text.trim());  
    }
void goToNextStep() {
    if (step == 1 && !_isStep1Valid()) return;
    if (step == 2 && !_isStep2Valid()) return;

    if (step == 2 && _envoyerAmi) {
      _sendCommandeToFriend();
      return;
    }
    
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

  Future<void> _sendCommandeToFriend() async {
    if (_sharePending || _selectedFriend == null) return;
    if (!_isStep1Valid()) return;

    setState(() {
      isLoading = true;
      _friendError = null;
    });

    final payload = {
      'localisation_depart': _departCtrl.text.trim(),
      'telDepart': _telDepartCtrl.text.trim(),
      'destination': _destinationCtrl.text.trim(),
      'telArrivee': _telArriveeCtrl.text.trim(),
      'statut': 'envoyee',
      'idAmie': _selectedFriend!.id,
    };

    try {
      await _commandeService.updateCommande(widget.commandeId, payload);
      if (!mounted) return;
      setState(() {
        _sharePending = true;
        _pendingFriendLabel = _displayFriend(_selectedFriend!);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Commande envoyee a ${_pendingFriendLabel ?? 'votre ami'}')),
      );
    } catch (e) {
      setState(() {
        _friendError = 'Echec de l\'envoi: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _useMyLocation(String target) async {
    setState(() {
      if (target == 'depart') {
        _locatingDepart = true;
      }
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le service de localisation est desactive.')),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission de localisation refusee.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final address = await _reverseGeocodeLatLng(position.latitude, position.longitude);
      final value = (address == null || address.isEmpty)
          ? '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'
          : address;

      if (target == 'depart') {
        _departCtrl.text = value;
      } else {
        _destinationCtrl.text = value;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur localisation: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (target == 'depart') {
            _locatingDepart = false;
          }
        });
      }
    }
  }

  Future<String?> _reverseGeocodeLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = <String>[];
      if (p.street != null && p.street!.trim().isNotEmpty) parts.add(p.street!.trim());
      if (p.locality != null && p.locality!.trim().isNotEmpty) parts.add(p.locality!.trim());
      if (p.postalCode != null && p.postalCode!.trim().isNotEmpty) parts.add(p.postalCode!.trim());
      if (p.country != null && p.country!.trim().isNotEmpty) parts.add(p.country!.trim());
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<void> _openMapPicker(String target) async {
    setState(() {
      _mapTarget = target;
      _selectedLatLng = null;
      _reverseAddress = null;
      _mapError = null;
    });

    await _setMapCenterToCurrentLocation();

    var dialogOpen = true;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 520,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _mapTarget == 'depart' ? 'Choisir position depart' : 'Choisir position arrivee',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _mapCenter,
                          initialZoom: 13,
                          onTap: (tapPosition, point) => _onMapTap(
                            point,
                            dialogSetState: setDialogState,
                            isDialogOpen: () => dialogOpen,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                            userAgentPackageName: 'com.example.yemchi_wyji',
                          ),
                          if (_selectedLatLng != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedLatLng!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_reverseLoading)
                            const Text('Recherche adresse...'),
                          if (_mapError != null)
                            Text(_mapError!, style: const TextStyle(color: Colors.red)),
                          if (_reverseAddress != null && _reverseAddress!.isNotEmpty)
                            Text(_reverseAddress!),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _selectedLatLng == null || _reverseLoading ? null : _confirmMapPick,
                            child: const Text('Utiliser cet emplacement'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    dialogOpen = false;

  }

  Future<void> _setMapCenterToCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final center = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _mapCenter = center);
      _mapController.move(center, 15);
    } catch (_) {}
  }

  void _onMapTap(
    LatLng point, {
    StateSetter? dialogSetState,
    bool Function()? isDialogOpen,
  }) {
    _updateMapDialogState(
      () {
        _selectedLatLng = point;
        _reverseAddress = null;
        _mapError = null;
      },
      dialogSetState: dialogSetState,
      isDialogOpen: isDialogOpen,
    );
    _reverseGeocode(point, dialogSetState: dialogSetState, isDialogOpen: isDialogOpen);
  }

  Future<void> _reverseGeocode(
    LatLng point, {
    StateSetter? dialogSetState,
    bool Function()? isDialogOpen,
  }) async {
    _updateMapDialogState(
      () {
        _reverseLoading = true;
        _mapError = null;
        _reverseAddress = null;
      },
      dialogSetState: dialogSetState,
      isDialogOpen: isDialogOpen,
    );
    final address = await _reverseGeocodeLatLng(point.latitude, point.longitude);
    if (!mounted) return;
    _updateMapDialogState(
      () {
        _reverseLoading = false;
        if (address == null || address.isEmpty) {
          _mapError = 'Adresse introuvable.';
        } else {
          _reverseAddress = address;
        }
      },
      dialogSetState: dialogSetState,
      isDialogOpen: isDialogOpen,
    );
  }

  void _confirmMapPick() {
    if (_selectedLatLng == null) return;
    final picked = _reverseAddress;
    final value = (picked == null || picked.isEmpty)
        ? '${_selectedLatLng!.latitude.toStringAsFixed(6)}, ${_selectedLatLng!.longitude.toStringAsFixed(6)}'
        : picked;
    if (_mapTarget == 'depart') {
      _departCtrl.text = value;
    } else {
      _destinationCtrl.text = value;
    }
    Navigator.pop(context);
  }

  void _updateMapDialogState(
    VoidCallback fn, {
    StateSetter? dialogSetState,
    bool Function()? isDialogOpen,
  }) {
    if (dialogSetState != null) {
      if (isDialogOpen != null && !isDialogOpen()) return;
      dialogSetState(fn);
      return;
    }
    if (!mounted) return;
    setState(fn);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmer ma commande - Étape $step/3'),
      ),
      body: isLoading && _commande == null
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
          backgroundColor: isCurrent ? Colors.blue : isDone ? Colors.green : Colors.grey.shade300,
          child: Text(
            '$num',
            style: TextStyle(color: isCurrent || isDone ? Colors.white : Colors.grey.shade600, fontSize: 12),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isCurrent ? Colors.blue : Colors.black, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
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
        Text("Adresse de départ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Row(
          children: [
            Expanded(child: TextFormField(
              controller: _departCtrl,
              decoration: const InputDecoration(hintText: "Rue, ville, code postal"),
              validator: (v) => (v?.length ?? 0) < 4 ? "Adresse obligatoire." : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            )),
            IconButton(
              onPressed: _locatingDepart ? null : () => _useMyLocation('depart'),
              icon: _locatingDepart
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.location_on),
            ),
            IconButton(
              onPressed: () => _openMapPicker('depart'),
              icon: const Icon(Icons.map),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text("Numéro de départ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Row(
          children: [
            Expanded(child: TextFormField(
              controller: _telDepartCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: "+216 ..."),
              validator: (v) => RegExp(r'^\+?\d{6,15}$').hasMatch(v ?? '') ? null : "Numéro invalide.",
              autovalidateMode: AutovalidateMode.onUserInteraction,
            )),
            TextButton.icon(
              onPressed: () {
                final tel = currentUser?.telephone?.trim();
                if (tel == null || tel.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aucun numéro enregistré pour ce compte.')),
                  );
                  return;
                }
                _telDepartCtrl.text = tel;
              },
              icon: const Icon(Icons.phone), 
              label: const Text("Utiliser mon numéro")
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_sharePending)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Commande envoyee a ${_pendingFriendLabel ?? 'votre ami'}. Attendez sa confirmation.',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        OutlinedButton.icon(
          onPressed: _sharePending
              ? null
              : () {
                  setState(() {
                    _envoyerAmi = !_envoyerAmi;
                    if (!_envoyerAmi) {
                      _selectedFriend = null;
                      _amiIdentifiantCtrl.clear();
                      _friendResults = [];
                      _friendError = null;
                    }
                  });
                },
          icon: Icon(_envoyerAmi ? Icons.undo : Icons.send),
          label: Text(_envoyerAmi ? 'Revenir a la saisie' : 'Envoyer a un ami'),
        ),
        const SizedBox(height: 12),
        if (_envoyerAmi) ...[
          Text("Coordonnee de l'ami (nom, email ou numero)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextFormField(
            controller: _amiIdentifiantCtrl,
            decoration: InputDecoration(
              hintText: "Nom complet, email ou numero",
              suffixIcon: _friendSearchLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search),
            ),
            onChanged: _onFriendQueryChanged,
            enabled: !_sharePending,
          ),
          if (_friendError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_friendError!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 8),
          if (_friendResults.isNotEmpty)
            Column(
              children: _friendResults.map((u) {
                final label = _displayFriend(u);
                return Card(
                  child: ListTile(
                    title: Text(label),
                    subtitle: Text(u.email ?? u.telephone ?? ''),
                    trailing: _selectedFriend?.id == u.id
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: _sharePending
                        ? null
                        : () {
                            setState(() {
                              _selectedFriend = u;
                              _amiIdentifiantCtrl.text = label;
                              _friendResults = [u];
                              _friendError = null;
                            });
                          },
                  ),
                );
              }).toList(),
            ),
        ] else ...[
          Text("Adresse d’arrivée", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Row(
            children: [
              Expanded(child: TextFormField(
                controller: _destinationCtrl,
                decoration: const InputDecoration(hintText: "Rue, ville, code postal"),
                validator: (v) => (v?.length ?? 0) < 4 ? "Adresse obligatoire." : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              )),
              IconButton(onPressed: () => _openMapPicker('arrivee'), icon: const Icon(Icons.map)),
            ],
          ),
          const SizedBox(height: 20),
          Text("Numéro d’arrivée", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextFormField(
            controller: _telArriveeCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: "+216 ..."),
            validator: (v) => RegExp(r'^\+?\d{6,15}$').hasMatch(v ?? '') ? null : "Numéro invalide.",
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ],
      ],
    );
  }
  
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Mode de paiement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        _buildPaymentOption('en_ligne', '💳 Paiement en ligne', 'Recommandé: Carte bancaire / wallet sécurisé'),
        _buildPaymentOption('depart', '🏁 Au départ', 'Remise au livreur avant le trajet'),
        _buildPaymentOption('arrivee', '📦 À l’arrivée', 'Pratique: Paiement lors de la livraison'),
        
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
        )
      ],
    );
  }

  Widget _buildPaymentOption(String value, String title, String subtitle) {
    return Card(
      color: _modePaiement == value ? Colors.blue.shade50 : null,
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: _modePaiement == value ? FontWeight.bold : FontWeight.normal)),
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
      case 'en_ligne': return 'En ligne';
      case 'depart': return 'Au départ';
      case 'arrivee': return 'À l’arrivée';
      default: return '-';
    }
  }

  Widget _buildRecapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text("$label :", style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
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
          
        if (step == 2 && _sharePending)
          ElevatedButton(
            onPressed: isLoading ? null : () => Navigator.pop(context, true),
            child: const Text("Terminer"),
          )
        else if (step < 3)
          ElevatedButton(
            onPressed: isLoading ? null : goToNextStep, 
            child: Text(_envoyerAmi && step == 2 ? "Envoyer" : "Suivant")
          ),
          
        if (step == 3)
          ElevatedButton(
            onPressed: isLoading ? null : finalConfirmation, 
            child: isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Text("✔ Confirmer"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
            ),
          ),
      ],
    );
  }

  void _onFriendQueryChanged(String query) {
    _friendDebounce?.cancel();
    _friendDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchFriends(query);
    });
  }

  Future<void> _searchFriends(String query) async {
    final v = query.trim();
    if (currentUser == null || v.isEmpty) {
      setState(() {
        _friendResults = [];
        _friendError = null;
      });
      return;
    }

    setState(() {
      _friendSearchLoading = true;
      _friendError = null;
    });

    try {
      List<Utilisateur> results = [];
      if (_isEmail(v)) {
        final u = await _authUserService.chercherParEmail(v);
        results = u.id.isNotEmpty ? [u] : [];
      } else if (_isPhoneLike(v)) {
        final digits = v.replaceAll(RegExp(r'\\D'), '');
        final last8 = digits.length > 8 ? digits.substring(digits.length - 8) : digits;
        results = await _amiService.searchMyFriendsByNumero(currentUser!.id, last8);
      } else if (_isFullName(v)) {
        final parts = v.split(RegExp(r'\\s+')).where((p) => p.isNotEmpty).toList();
        final prenom = parts.first;
        final nom = parts.sublist(1).join(' ');
        results = await _amiService.searchMyFriendsByNomEtPrenom(currentUser!.id, nom, prenom);
        if (results.isEmpty) {
          results = await _amiService.searchMyFriendsByNomPrenom(currentUser!.id, v);
        }
      } else {
        results = await _amiService.searchMyFriendsByNomPrenom(currentUser!.id, v);
      }

      setState(() {
        _friendResults = results;
        if (results.isEmpty) {
          _friendError = 'Aucun utilisateur trouve.';
        }
      });
    } catch (e) {
      setState(() {
        _friendResults = [];
        _friendError = 'Erreur de recherche.';
      });
    } finally {
      if (mounted) {
        setState(() => _friendSearchLoading = false);
      }
    }
  }

  String _displayFriend(Utilisateur u) {
    final parts = <String>[];
    if (u.prenom != null && u.prenom!.trim().isNotEmpty) {
      parts.add(u.prenom!.trim());
    }
    if (u.nom != null && u.nom!.trim().isNotEmpty) {
      parts.add(u.nom!.trim());
    }
    if (parts.isNotEmpty) return parts.join(' ');
    return u.email ?? u.telephone ?? 'Utilisateur';
  }

  bool _isEmail(String v) {
    return RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]{2,}\$').hasMatch(v);
  }

  bool _isPhoneLike(String v) {
    return RegExp(r'^[+\\-\\s\\d]{6,}\$').hasMatch(v);
  }

  bool _isFullName(String v) {
    return RegExp(r"^[A-Za-z'\\-]+(?:\\s+[A-Za-z'\\-]+)+\$").hasMatch(v);
  }
}
