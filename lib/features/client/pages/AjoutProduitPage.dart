import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cilent_service.dart'; // Update with your actual path
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:image_picker/image_picker.dart';

class AjoutProduitPage extends StatefulWidget {
  const AjoutProduitPage({super.key});

  @override
  State<AjoutProduitPage> createState() => _AjoutProduitPageState();
}

class _AjoutProduitPageState extends State<AjoutProduitPage> {
  final _formKey = GlobalKey<FormState>();
  String _nom = '';
  String _type = '';
  int _quantite = 1;
  bool _fragile = false;
  XFile? _image;
  bool _loading = false;

  Future<void> _handleAddProduit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final userId = Provider.of<AuthController>(context, listen: false).currentUser.value?.id;
      final produitService = ProduitService();

      Map<String, dynamic> payload = {
        'nom': _nom,
        'type': _type,
        'quantite': _quantite,
        'fragile': _fragile,
        // Add additional fields as needed
      };

      final produit = await produitService.addProduitForUser(
        userId: userId!,
        formPayload: payload,
        imagePath: _image?.path,
      );
      Navigator.of(context).pop(); // Success, go back to cart
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final selected = await picker.pickImage(source: ImageSource.gallery);
    if (selected != null) setState(() => _image = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un produit')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v == null || v.isEmpty ? 'Nom obligatoire' : null,
                onChanged: (v) => _nom = v,
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  'Standard (≤ 5kg)', 'Moyen (5–15kg)', 'Gros (15–50kg)', 'Mobilier', 'Électroménager'
                ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                validator: (v) => v == null || v.isEmpty ? 'Type obligatoire' : null,
                onChanged: (v) => _type = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
                initialValue: '1',
                validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Doit être ≥ 1' : null,
                onChanged: (v) => _quantite = int.tryParse(v) ?? 1,
              ),
              SwitchListTile(
                value: _fragile,
                title: const Text('Produit fragile ?'),
                onChanged: (v) => setState(() => _fragile = v),
              ),
              FormField(
                validator: (v) => _image == null ? 'Image obligatoire' : null,
                builder: (FormFieldState state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: Text(_image == null ? 'Choisir une image' : 'Image sélectionnée'),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            state.errorText ?? '',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _handleAddProduit,
                child: _loading ? const CircularProgressIndicator() : const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
