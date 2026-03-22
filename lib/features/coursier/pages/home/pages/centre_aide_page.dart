import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/produit.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/commande/data/commande_service.dart';
import 'package:yemchi_wyji/features/commande/dto/commande_produits_response.dart';

enum _HelpAction {
  panneOuAccident,
  clientNonRepondu,
}

enum _IncidentType { panne, accident }

class CentreAidePage extends StatefulWidget {
  const CentreAidePage({super.key});

  @override
  State<CentreAidePage> createState() => _CentreAidePageState();
}

class _CentreAidePageState extends State<CentreAidePage> {
  _HelpAction? _selectedAction;
  _IncidentType? _incidentType;
  int _stepIndex = 0;

  bool _loadingProduits = false;
  String? _produitsError;
  List<CommandeProduitsResponse> _commandeProduits =
      const <CommandeProduitsResponse>[];
  final Set<String> _selectedProduitIds = <String>{};
  final Map<String, int> _selectedProduitQuantitesAffectees = <String, int>{};

  bool get _isPanne => _incidentType == _IncidentType.panne;
  bool get _isAccident => _incidentType == _IncidentType.accident;
  List<Produit> get _produitsAccident =>
      _commandeProduits.expand((entry) => entry.produits).toList();

  String _selectionKeyForProduit(Produit produit, int index) {
    if (produit.id.trim().isNotEmpty) {
      return produit.id.trim();
    }
    final nom = produit.nom?.trim() ?? '';
    return '$nom-$index';
  }

  int get _lastStepIndex => _isPanne ? 0 : 1;

  String get _stepTitle {
    switch (_stepIndex) {
      case 0:
        return 'Etape 1 - Type d incident';
      case 1:
        return 'Etape 2 - Produits affectes';
      default:
        return 'Signalement';
    }
  }

  bool _canContinueCurrentStep() {
    switch (_stepIndex) {
      case 0:
        return _incidentType != null;
      case 1:
        return !_loadingProduits &&
            _produitsError == null &&
            _produitsAccident.asMap().entries.every((entry) {
              final selectionKey = _selectionKeyForProduit(entry.value, entry.key);
              return _isQuantiteAffecteeValide(
                selectionKey: selectionKey,
                produit: entry.value,
              );
            });
      default:
        return false;
    }
  }

  bool _isQuantiteAffecteeValide({
    required String selectionKey,
    required Produit produit,
  }) {
    if (!_selectedProduitIds.contains(selectionKey)) return true;
    final quantite = produit.quantite ?? 1;
    if (quantite <= 1) return true;
    final quantiteAffectee = _selectedProduitQuantitesAffectees[selectionKey];
    return quantiteAffectee != null &&
        quantiteAffectee >= 1 &&
        quantiteAffectee <= quantite;
  }

  Future<void> _loadProduitsAccident() async {
    final auth = context.read<AuthController>();
    final api = context.read<Api>();
    final transporteurId = auth.currentUser.value?.id;

    if (transporteurId == null || transporteurId.isEmpty) {
      setState(() {
        _loadingProduits = false;
        _produitsError = 'Livreur introuvable.';
        _commandeProduits = const <CommandeProduitsResponse>[];
        _selectedProduitIds.clear();
        _selectedProduitQuantitesAffectees.clear();
      });
      return;
    }

    setState(() {
      _loadingProduits = true;
      _produitsError = null;
      _commandeProduits = const <CommandeProduitsResponse>[];
      _selectedProduitIds.clear();
      _selectedProduitQuantitesAffectees.clear();
    });

    try {
      final service = CommandeService(api);
      final responses = await service.getCommandesEnRouteAvecProduitsByTransporteur(
        transporteurId,
      );
      final filtered = responses.where((entry) {
        final statut = entry.commande.statut?.trim().toLowerCase();
        return statut == 'en_route' && entry.commande.qrCodeDepartScanne == true;
      }).toList();

      if (!mounted) return;
      setState(() {
        _loadingProduits = false;
        _commandeProduits = filtered;
        _produitsError = filtered.isEmpty
            ? 'Aucun produit disponible.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProduits = false;
        _produitsError = 'Impossible de recuperer les produits. ($e)';
      });
    }
  }

  Map<String, int> _buildProduitsAffectes() {
    return Map<String, int>.fromEntries(_produitsAccident.asMap().entries.where((entry) {
      final selectionKey = _selectionKeyForProduit(entry.value, entry.key);
      return _selectedProduitIds.contains(selectionKey);
    }).map((entry) {
      final selectionKey = _selectionKeyForProduit(entry.value, entry.key);
      final quantite = entry.value.quantite ?? 1;
      final quantiteAffecter = quantite <= 1
          ? 1
          : _selectedProduitQuantitesAffectees[selectionKey];
      return MapEntry(entry.value.id, quantiteAffecter ?? 1);
    }));
  }

  List<String> _buildProduitsNonAffectes() {
    return _produitsAccident.asMap().entries.where((entry) {
      final selectionKey = _selectionKeyForProduit(entry.value, entry.key);
      return !_selectedProduitIds.contains(selectionKey);
    }).map((entry) {
      return entry.value.id;
    }).toList();
  }

  void _showSubmissionFeedback() {
    final typeLabel = _isPanne ? 'panne du vehicule' : 'accident';
    final details = _isAccident
        ? ' (${_selectedProduitIds.length} produit(s) affecte(s))'
        : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Signalement $typeLabel enregistre localement$details. Aucune BDD n est utilisee.',
        ),
      ),
    );

    _resetFlow();
  }

  Future<void> _goNext() async {
    if (!_canContinueCurrentStep()) return;

    if (_stepIndex < _lastStepIndex) {
      setState(() {
        _stepIndex++;
      });
      return;
    }

    if (_isPanne) {
      final auth = context.read<AuthController>();
      final ok = await auth.marquerTransporteurEnPanne();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              auth.error.value ?? 'Impossible de marquer le transporteur en panne.',
            ),
          ),
        );
        return;
      }
    }

    if (_isAccident) {
      final auth = context.read<AuthController>();
      final ok = await auth.declarerAccidentAvecProduits(
        produitsAffectes: _buildProduitsAffectes(),
        produitsNonAffectes: _buildProduitsNonAffectes(),
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              auth.error.value ??
                  'Impossible de declarer l accident avec produits.',
            ),
          ),
        );
        return;
      }
    }

    _showSubmissionFeedback();
  }

  void _goBack() {
    if (_stepIndex == 0) return;
    setState(() {
      _stepIndex--;
    });
  }

  void _resetFlow() {
    setState(() {
      _selectedAction = null;
      _incidentType = null;
      _stepIndex = 0;
      _loadingProduits = false;
      _produitsError = null;
      _commandeProduits = const <CommandeProduitsResponse>[];
      _selectedProduitIds.clear();
      _selectedProduitQuantitesAffectees.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Centre d'aide"),
      ),
      body: SafeArea(
        child: _selectedAction == null
            ? _buildActionSelector()
            : _selectedAction == _HelpAction.panneOuAccident
                ? _buildIncidentFlow()
                : _buildClientNotAnsweredPlaceholder(),
      ),
    );
  }

  Widget _buildActionSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Centre d'aide",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez le type de demande a traiter.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          _ActionButtonCard(
            icon: Icons.warning_amber_rounded,
            title: 'Panne ou accident',
            subtitle: 'Ouvrir le parcours de signalement.',
            onTap: () {
              setState(() {
                _selectedAction = _HelpAction.panneOuAccident;
                _stepIndex = 0;
                _incidentType = null;
              });
            },
          ),
          const SizedBox(height: 16),
          _ActionButtonCard(
            icon: Icons.phone_disabled_outlined,
            title: "Client n'a pas repondu",
            subtitle: 'Option presente, sans traitement metier pour le moment.',
            onTap: () {
              setState(() {
                _selectedAction = _HelpAction.clientNonRepondu;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentFlow() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Signaler un incident',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _isPanne
                ? 'La panne sera enregistree telle quelle.'
                : 'Selectionnez uniquement les produits affectes.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          _ProgressHeader(
            currentStep: _stepIndex,
            lastStep: _lastStepIndex,
            title: _stepTitle,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCurrentStep(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _stepIndex == 0 ? _resetFlow : _goBack,
                  child: Text(
                    _stepIndex == 0 ? "Retour au centre d'aide" : 'Retour',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _canContinueCurrentStep()
                      ? () {
                          _goNext();
                        }
                      : null,
                  child: Text(
                    _stepIndex == _lastStepIndex
                        ? (_isPanne ? 'Enregistrer la panne' : 'Terminer')
                        : 'Continuer',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_stepIndex) {
      case 0:
        return _buildTypeStep();
      case 1:
        return _buildProduitsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quel type d incident ?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        RadioListTile<_IncidentType>(
          value: _IncidentType.panne,
          groupValue: _incidentType,
          title: const Text('Panne du vehicule'),
          onChanged: (value) {
            setState(() {
              _incidentType = value;
              _loadingProduits = false;
              _produitsError = null;
              _commandeProduits = const <CommandeProduitsResponse>[];
              _selectedProduitIds.clear();
              _selectedProduitQuantitesAffectees.clear();
            });
          },
        ),
        RadioListTile<_IncidentType>(
          value: _IncidentType.accident,
          groupValue: _incidentType,
          title: const Text('Accident'),
          onChanged: (value) {
            setState(() {
              _incidentType = value;
            });
            if (value == _IncidentType.accident) {
              _loadProduitsAccident();
            }
          },
        ),
      ],
    );
  }

  Widget _buildProduitsStep() {
    if (_loadingProduits) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_produitsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _produitsError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadProduitsAccident,
            child: const Text('Reessayer'),
          ),
        ],
      );
    }

    final produits = _produitsAccident;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez les produits affectes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (produits.isEmpty)
          const Text('Aucun produit disponible.')
        else
          ...produits.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final produit = entry.value;
              final selectionKey = _selectionKeyForProduit(produit, index);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProduitSelectionTile(
                  produit: produit,
                  selected: _selectedProduitIds.contains(selectionKey),
                  quantiteAffectee:
                      _selectedProduitQuantitesAffectees[selectionKey],
                  onChanged: () {
                    setState(() {
                      if (_selectedProduitIds.contains(selectionKey)) {
                        _selectedProduitIds.remove(selectionKey);
                        _selectedProduitQuantitesAffectees.remove(selectionKey);
                      } else {
                        _selectedProduitIds.add(selectionKey);
                        final quantite = produit.quantite ?? 1;
                        if (quantite <= 1) {
                          _selectedProduitQuantitesAffectees[selectionKey] = 1;
                        }
                      }
                    });
                  },
                  onQuantiteAffecteeChanged: (value) {
                    setState(() {
                      if (value == null) {
                        _selectedProduitQuantitesAffectees.remove(selectionKey);
                      } else {
                        _selectedProduitQuantitesAffectees[selectionKey] = value;
                      }
                    });
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildClientNotAnsweredPlaceholder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Client n'a pas repondu",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cette section est affichee mais son traitement n est pas encore implemente.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Bouton ajoute. Le traitement "Client n a pas repondu" pourra etre implemente ensuite.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _resetFlow,
              child: const Text('Retour menu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.currentStep,
    required this.lastStep,
    required this.title,
  });

  final int currentStep;
  final int lastStep;
  final String title;

  @override
  Widget build(BuildContext context) {
    final totalSteps = lastStep + 1;
    final progress = (currentStep + 1) / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 8),
        Text('Etape ${currentStep + 1} sur $totalSteps'),
      ],
    );
  }
}

class _ActionButtonCard extends StatelessWidget {
  const _ActionButtonCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProduitSelectionTile extends StatelessWidget {
  const _ProduitSelectionTile({
    required this.produit,
    required this.selected,
    required this.quantiteAffectee,
    required this.onChanged,
    required this.onQuantiteAffecteeChanged,
  });

  final Produit produit;
  final bool selected;
  final int? quantiteAffectee;
  final VoidCallback onChanged;
  final ValueChanged<int?> onQuantiteAffecteeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quantityLabel = produit.quantite != null ? '${produit.quantite}' : '-';
    final quantite = produit.quantite ?? 1;
    final showQuantiteAffecteeField = selected && quantite > 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onChanged,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: selected ? 2 : 1,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.08)
                : theme.colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (_) => onChanged(),
                  ),
                  const SizedBox(width: 8),
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
              if (showQuantiteAffecteeField) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: quantiteAffectee,
                  decoration: const InputDecoration(
                    labelText: 'Quantite affecter',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    quantite,
                    (index) => DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text('${index + 1}'),
                    ),
                  ),
                  onChanged: onQuantiteAffecteeChanged,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProduitImage extends StatelessWidget {
  const _ProduitImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const double size = 64;
    final theme = Theme.of(context);

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _PlaceholderImage(theme: theme, size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl!.trim(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _PlaceholderImage(theme: theme, size: size),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({
    required this.theme,
    required this.size,
  });

  final ThemeData theme;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
