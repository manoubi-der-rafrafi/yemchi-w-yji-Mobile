import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cilent_service.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';

class AjoutProduitPage extends StatefulWidget {
  const AjoutProduitPage({super.key});

  @override
  State<AjoutProduitPage> createState() => _AjoutProduitPageState();
}

class _AjoutProduitPageState extends State<AjoutProduitPage> {
  final _formKey = GlobalKey<FormState>();
  final _produitService = ProduitService();

  // ── Controllers ──────────────────────────────────────────────
  final _nomCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _hauteurCtrl = TextEditingController();
  final _largeurCtrl = TextEditingController();
  final _profondeurCtrl = TextEditingController();
  final _matiereCtrl = TextEditingController();
  final _fragileDetailCtrl = TextEditingController();

  // ── Form state ────────────────────────────────────────────────
  String _type = '';
  bool _fragile = false;
  bool _showDetails = false;

  // ── Images ───────────────────────────────────────────────────
  XFile? _image1;
  XFile? _image2;
  XFile? _image3;

  // ── Upload / analysis state ───────────────────────────────────
  bool _image1Uploading = false;
  bool _image1Analyzing = false;
  String? _image1Error;
  String? _uploadedImage1Url;

  // ── Submit state ─────────────────────────────────────────────
  bool _submitting = false;

  static const List<String> _types = [
    'Standard',
    'Moyen',
    'Gros',
    'Mobilier',
    'Electromenager',
  ];

  @override
  void dispose() {
    _nomCtrl.dispose();
    _poidsCtrl.dispose();
    _prixCtrl.dispose();
    _hauteurCtrl.dispose();
    _largeurCtrl.dispose();
    _profondeurCtrl.dispose();
    _matiereCtrl.dispose();
    _fragileDetailCtrl.dispose();
    super.dispose();
  }

  // ── Image 1 selection: upload + detect in parallel ────────────
  Future<void> _onImage1Selected(XFile file) async {
    setState(() {
      _image1 = file;
      _image1Error = null;
      _image1Uploading = true;
      _image1Analyzing = false;
      _showDetails = false;
      _uploadedImage1Url = null;
    });

    final ioFile = File(file.path);

    // Run upload and detect in parallel
    final results = await Future.wait([
      _produitService.uploadProduitImageAuth(file.path).then<String?>((v) => v).catchError((_) => null),
    ]);

    if (!mounted) return;

    final uploadedUrl = results[0] as String?;

    if (uploadedUrl == null) {
      setState(() {
        _image1Uploading = false;
        _image1Error = "Échec de l'upload de l'image.";
      });
      return;
    }

    setState(() {
      _uploadedImage1Url = uploadedUrl;
      _image1Uploading = false;
      _image1Analyzing = true;
      _image1Error = null;
    });

    // Now deep-analyze via uploaded URL
    try {
      final analysis = await _produitService.analyzeUploadedImage(uploadedUrl);
      if (!mounted) return;

      if (analysis.productName.isNotEmpty) {
        _nomCtrl.text = analysis.productName;
      }
      if (analysis.estimatedPriceTnd != null && _prixCtrl.text.isEmpty) {
        _prixCtrl.text = analysis.estimatedPriceTnd!.toStringAsFixed(2);
      }
      if (analysis.heightCm != null && _hauteurCtrl.text.isEmpty) {
        _hauteurCtrl.text = analysis.heightCm!.toStringAsFixed(1);
      }
      if (analysis.widthCm != null && _largeurCtrl.text.isEmpty) {
        _largeurCtrl.text = analysis.widthCm!.toStringAsFixed(1);
      }
      if (analysis.depthCm != null && _profondeurCtrl.text.isEmpty) {
        _profondeurCtrl.text = analysis.depthCm!.toStringAsFixed(1);
      }
    } catch (_) {
      // Analysis failure is non-fatal — form fields remain empty for manual entry
    }

    if (!mounted) return;
    setState(() {
      _image1Analyzing = false;
      _showDetails = true;
    });
  }

  String _normalizeType(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('mobilier')) return 'Mobilier';
    if (lower.contains('electro') || lower.contains('menager')) return 'Electromenager';
    if (lower.contains('gros')) return 'Gros';
    if (lower.contains('moyen')) return 'Moyen';
    return 'Standard';
  }

  Future<void> _pickImage(int slot) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    if (slot == 1) {
      await _onImage1Selected(picked);
    } else if (slot == 2) {
      setState(() => _image2 = picked);
    } else {
      setState(() => _image3 = picked);
    }
  }

  // ── Submit ────────────────────────────────────────────────────
  Future<void> _handleAddProduit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image1 == null || _uploadedImage1Url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez attendre la fin de l'upload de l'image 1.")),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final userId = Provider.of<AuthController>(context, listen: false).currentUser.value?.id;
      if (userId == null) throw Exception('Utilisateur non connecté.');

      // Upload image2 and image3 if selected
      String? image2Url;
      String? image3Url;
      if (_image2 != null) {
        image2Url = await _produitService.uploadProduitImageAuth(_image2!.path);
      }
      if (_image3 != null) {
        image3Url = await _produitService.uploadProduitImageAuth(_image3!.path);
      }

      final payload = <String, dynamic>{
        'nom': _nomCtrl.text.trim(),
        'type': _type,
        'poids': double.tryParse(_poidsCtrl.text.trim()),
        'prixUnitaire': double.tryParse(_prixCtrl.text.trim()),
        'hauteur': double.tryParse(_hauteurCtrl.text.trim()),
        'largeur': double.tryParse(_largeurCtrl.text.trim()),
        'profondeur': double.tryParse(_profondeurCtrl.text.trim()),
        'matiere': _matiereCtrl.text.trim().isEmpty ? null : _matiereCtrl.text.trim(),
        'fragile': _fragile.toString(),
        'fragileDetail': _fragile ? _fragileDetailCtrl.text.trim() : null,
        'quantite': 1,
        'image': _uploadedImage1Url,
        'image1': _uploadedImage1Url,
        'image2': image2Url,
        'image3': image3Url,
      };

      await _produitService.addProduitForUser(
        userId: userId,
        formPayload: payload,
        // imagePath omitted — already uploaded, URL is in payload
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un produit')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Image 1 (required, triggers AI) ──────────────────
            _buildImageSlot(
              slot: 1,
              label: 'Photo du produit *',
              file: _image1,
              uploading: _image1Uploading,
              analyzing: _image1Analyzing,
              error: _image1Error,
            ),
            const SizedBox(height: 20),

            // ── Details block (shown after AI completes) ──────────
            if (_showDetails) ...[
              // Nom
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom du produit *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
              ),
              const SizedBox(height: 12),

              // Type
              DropdownButtonFormField<String>(
                initialValue: _type.isEmpty ? null : _type,
                decoration: const InputDecoration(labelText: 'Type *'),
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                validator: (v) => (v == null || v.isEmpty) ? 'Type obligatoire' : null,
                onChanged: (v) => setState(() => _type = v ?? ''),
              ),
              const SizedBox(height: 12),

              // Poids
              TextFormField(
                controller: _poidsCtrl,
                decoration: const InputDecoration(labelText: 'Poids (kg)', suffixText: 'kg'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                validator: _type == 'Mobilier' || _type == 'Electromenager'
                    ? (v) => (v == null || v.trim().isEmpty) ? 'Poids obligatoire pour ce type' : null
                    : null,
              ),
              const SizedBox(height: 12),

              // Prix unitaire
              TextFormField(
                controller: _prixCtrl,
                decoration: const InputDecoration(labelText: 'Prix estimé (TND)', suffixText: 'TND'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              ),
              const SizedBox(height: 12),

              // Dimensions (only shown for Mobilier / Electromenager)
              if (_type == 'Mobilier' || _type == 'Electromenager') ...[
                const Text('Dimensions', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildDimensionField(_hauteurCtrl, 'H (cm)')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDimensionField(_largeurCtrl, 'L (cm)')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDimensionField(_profondeurCtrl, 'P (cm)')),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Matière
              TextFormField(
                controller: _matiereCtrl,
                decoration: const InputDecoration(labelText: 'Matière (optionnel)'),
              ),
              const SizedBox(height: 12),

              // Fragile
              SwitchListTile(
                value: _fragile,
                title: const Text('Produit fragile ?'),
                onChanged: (v) => setState(() => _fragile = v),
                contentPadding: EdgeInsets.zero,
              ),
              if (_fragile) ...[
                TextFormField(
                  controller: _fragileDetailCtrl,
                  decoration: const InputDecoration(labelText: 'Précisions (fragile)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
              ],

              
              const SizedBox(height: 24),

              // Submit
              ElevatedButton(
                onPressed: _submitting ? null : _handleAddProduit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('+ Ajouter au panier'),
              ),
            ] else if (_image1 == null) ...[
              const Center(
                child: Text(
                  'Prenez une photo du produit pour commencer.\nL\'IA remplira les informations automatiquement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlot({
    required int slot,
    required String label,
    XFile? file,
    bool uploading = false,
    bool analyzing = false,
    String? error,
    bool compact = false,
  }) {
    final hasImage = file != null;
    final busy = uploading || analyzing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        GestureDetector(
          onTap: busy ? null : () => _pickImage(slot),
          child: Container(
            height: compact ? 90 : 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: error != null ? Colors.red : Colors.grey.shade300,
              ),
            ),
            child: busy
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        uploading ? 'Upload en cours...' : 'Analyse IA...',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  )
                : hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(file.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: compact ? 28 : 40, color: Colors.grey),
                          if (!compact) ...[
                            const SizedBox(height: 6),
                            Text(label,
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ],
                      ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildDimensionField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: _type == 'Mobilier' || _type == 'Electromenager'
          ? (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null
          : null,
    );
  }
}
