import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import '../services/cilent_service.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import '../models/utilisateur.dart';
import 'package:intl/intl.dart';
import 'ConfirmationCommandePage.dart';

class CommandesPage extends StatefulWidget {
  const CommandesPage({super.key});

  @override
  State<CommandesPage> createState() => _CommandesPageState();
}

class _CommandesPageState extends State<CommandesPage> {
  final CommandeService _commandeService = CommandeService();

  String viewMode = 'mes';
  String search = '';
  String status = 'tous';
  bool loading = true;
  String? error;

  List<Commande> commandesMesCache = [];
  List<Commande> commandesEnvCache = [];
  List<Commande> commandesSource = [];
  List<Commande> filtered = [];

  int pageIndex = 1;
  int pageSize = 5;
  final List<int> pageSizes = [5, 10, 20];

  final Map<String, Utilisateur> userCache = {};

  String? currentUserId;

  @override
  void initState() {
    super.initState();
    final authController = Provider.of<AuthController>(context, listen: false);
    currentUserId = authController.currentUser.value?.id;

    if (currentUserId != null) {
      _loadHistorique(currentUserId!);
    } else {
      loading = false;
      error = "Erreur: Utilisateur non connecte ou ID introuvable.";
    }
  }

  Future<void> _loadHistorique(String clientId) async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final mes = await _commandeService.getByClient(clientId);
      commandesMesCache = mes.toList()
        ..sort((a, b) => (b.dateDemande?.compareTo(a.dateDemande ?? DateTime(0)) ?? 0));

      /*final envoyees = await _commandeService.getByIdAmie(clientId);
      commandesEnvCache = envoyees.toList()
          ..sort((a, b) => (b.dateDemande?.compareTo(a.dateDemande ?? DateTime(0)) ?? 0));*/


      _syncCommandesSource();
    } catch (e) {
      error = e.toString();
      commandesMesCache = [];
      commandesEnvCache = [];
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void _syncCommandesSource() {
    commandesSource = viewMode == 'mes' ? commandesMesCache : commandesEnvCache;
    _applyFilters(true);
  }

  void _applyFilters([bool resetToFirstPage = false]) {
    final q = search.toLowerCase().trim();

    filtered = commandesSource.where((c) {
      final statutLower = (c.statut ?? '').toLowerCase().replaceAll('Ǹ', 'e').replaceAll('��', 'e');
      final statusFilterLower = status.toLowerCase().replaceAll('Ǹ', 'e').replaceAll('��', 'e');

      final matchText = q.isEmpty ||
          (c.id ?? '').toLowerCase().contains(q) ||
          (c.localisationDepart ?? '').toLowerCase().contains(q) ||
          (c.destination ?? '').toLowerCase().contains(q);

      final matchStatut = status == 'tous' || statutLower == statusFilterLower;

      return matchText && matchStatut;
    }).toList();

    if (resetToFirstPage) pageIndex = 1;

    if (pageIndex > totalPages) pageIndex = totalPages.clamp(1, 9999);
    if (pageIndex < 1) pageIndex = 1;

    setState(() {});
  }

  int get totalPages => (filtered.isEmpty ? 1 : (filtered.length / pageSize).ceil());
  int get totalItems => filtered.length;

  List<Commande> get pageSlice {
    if (filtered.isEmpty) return [];
    final start = (pageIndex - 1) * pageSize;
    final end = (start + pageSize).clamp(0, totalItems);
    return filtered.sublist(start, end);
  }

  void onChangePageSize(int? newSize) {
    if (newSize == null) return;
    pageSize = newSize;
    _applyFilters(true);
  }

  void prev() {
    if (pageIndex > 1) setState(() => pageIndex--);
  }

  void next() {
    if (pageIndex < totalPages) setState(() => pageIndex++);
  }

  void goToPage(int p) {
    setState(() => pageIndex = p);
  }

  void _onChnageClick(Commande c) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (context) => ConfirmationCommandePage(commandeId: c.id!),
        ))
        .then((_) => _loadHistorique(currentUserId!));
  }

  void _acceptCommand(Commande c) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (context) => ConfirmationCommandePage(commandeId: c.id!),
        ))
        .then((_) => _loadHistorique(currentUserId!));
  }

  void _accepterAction(Commande c) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (context) => ConfirmationCommandePage(commandeId: c.id!),
        ))
        .then((_) => _loadHistorique(currentUserId!));
  }

  String mapPaiement(String? v) {
    final x = (v ?? '').toLowerCase();
    switch (x) {
      case 'en_ligne':
        return 'En ligne';
      case 'depart':
        return 'Au depart';
      case 'arrivee':
        return 'A l arrivee';
      default:
        return '--';
    }
  }

  Color getStatusColor(String? statut) {
    final s = (statut ?? '').toLowerCase().replaceAll('Ǹ', 'e').replaceAll('��', 'e');
    if (s.contains('attente')) return Colors.deepOrange;
    if (s.contains('confirmer') || s.contains('confirmee')) return Colors.blue;
    if (s.contains('cours')) return Colors.purple;
    if (s.contains('livree')) return Colors.green;
    if (s.contains('annulee')) return Colors.red;
    if (s.contains('envoyee')) return Colors.teal;
    if (s.contains('accepter') || s.contains('acceptee')) return Colors.deepPurple;
    return Colors.grey;
  }

  Utilisateur? _getUser(String? id) {
    if (id == null) return null;

    final cached = userCache[id];
    if (cached != null) return cached;

    userCache[id] = Utilisateur(id: id, nom: 'Chargement...');
    return userCache[id];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique de mes commandes'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: loading && error == null
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 20)),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Historique de mes commandes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text("Consultez et suivez vos commandes passees facilement", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        const SizedBox(height: 18),
                        _buildFilters(),
                        const SizedBox(height: 12),
                        Expanded(child: _buildOrderList()),
                        if (pageSlice.isNotEmpty) _buildPaginationBar(),
                      ],
                    ),
                  ),
                ),
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSegmentButton('mes', 'Mes commandes', isLeft: true),
            _buildSegmentButton('envoyees', 'Commandes envoyees', isRight: true),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (s) {
                  setState(() => search = s);
                  _applyFilters(true);
                },
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: status,
                  borderRadius: BorderRadius.circular(12),
                  items: ['tous', 'en attente', 'confirmer', 'en cours', 'livree', 'annulee', 'envoyee', 'accepter']
                      .map((s) => DropdownMenuItem(value: s.replaceAll(' ', '_'), child: Text(s[0].toUpperCase() + s.substring(1))))
                      .toList(),
                  onChanged: (val) {
                    setState(() => status = val!);
                    _applyFilters(true);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegmentButton(String mode, String label, {bool isLeft = false, bool isRight = false}) {
    final bool isActive = viewMode == mode;
    return ElevatedButton(
      onPressed: () {
        setState(() => viewMode = mode);
        _syncCommandesSource();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.green : Colors.grey.shade200,
        foregroundColor: isActive ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: isLeft ? const Radius.circular(14) : Radius.zero,
            bottomLeft: isLeft ? const Radius.circular(14) : Radius.zero,
            topRight: isRight ? const Radius.circular(14) : Radius.zero,
            bottomRight: isRight ? const Radius.circular(14) : Radius.zero,
          ),
        ),
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildOrderList() {
    if (pageSlice.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Text(
              viewMode == 'mes' ? 'Aucune commande trouvee.' : 'Aucune commande envoyee a vous par un ami.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ),
      );
    }

    return ListView.separated(
      itemCount: pageSlice.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = pageSlice[index];
        final statut = (c.statut ?? '').toLowerCase();
        final statusColor = getStatusColor(statut);

        if (viewMode == 'mes') {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.localisationDepart ?? '--',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statut.replaceAll('_', ' '),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(c.destination ?? '--', style: const TextStyle(fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                        c.dateDemande != null ? DateFormat('yyyy-MM-dd HH:mm').format(c.dateDemande!) : "--",
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statut != 'envoyee' ? "${c.prix?.toStringAsFixed(2) ?? '0.00'} DT" : "--",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Text(
                      statut != 'envoyee' ? mapPaiement(c.modePaiement) : "--",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildMesActions(c, statut),
                ),
              ],
            ),
          );
        } else {
          final sender = _getUser(c.clientId);
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildSenderCell(sender)),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statut.replaceAll('_', ' '),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(c.localisationDepart ?? '--', style: const TextStyle(fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildEnvoyeesActions(c, statut),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildMesActions(Commande c, String statut) {
    if (statut == 'envoyee') {
      return TextButton(onPressed: () => _onChnageClick(c), child: const Text('Changer'));
    } else if (statut == 'accepter') {
      return TextButton(onPressed: () => _accepterAction(c), child: const Text('Completer'));
    }
    return const Text('--');
  }

  Widget _buildEnvoyeesActions(Commande c, String statut) {
    if (statut == 'envoyee') {
      return ElevatedButton(
        onPressed: () => _acceptCommand(c),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
        child: const Text('Accepter', style: TextStyle(color: Colors.white)),
      );
    } else if (statut == 'accepter') {
      return const Text('Acceptee');
    }
    return const Text('--');
  }

  Widget _buildSenderCell(Utilisateur? cli) {
    final bool isLoading = cli?.nom == 'Chargement...';

    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          child: isLoading ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.person),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${cli?.prenom ?? "--"} ${cli?.nom ?? ""}', style: const TextStyle(fontWeight: FontWeight.w500)),
            Row(
              children: [
                Text(cli?.telephone ?? "--", style: const TextStyle(fontSize: 12)),
                Text(" · ", style: TextStyle(color: Colors.grey.shade600)),
                Text(cli?.email ?? "--", style: const TextStyle(fontSize: 12)),
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget _buildPaginationBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Afficher", style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              DropdownButton<int>(
                value: pageSize,
                onChanged: onChangePageSize,
                items: pageSizes.map((s) => DropdownMenuItem(value: s, child: Text('$s'))).toList(),
              ),
              const Text("par page"),
            ],
          ),
          Text(
            "De ${(pageIndex - 1) * pageSize + 1}"
            " a "
            "${(pageIndex * pageSize).clamp(1, totalItems)}"
            " sur $totalItems",
            style: const TextStyle(color: Colors.grey),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: pageIndex == 1 ? null : prev,
                icon: const Icon(Icons.chevron_left),
              ),
              TextButton(
                onPressed: () => goToPage(1),
                child: Text('1', style: TextStyle(fontWeight: pageIndex == 1 ? FontWeight.bold : FontWeight.normal)),
              ),
              if (totalPages > 1) const Text('...'),
              if (totalPages > 1)
                TextButton(
                  onPressed: () => goToPage(totalPages),
                  child: Text('$totalPages', style: TextStyle(fontWeight: pageIndex == totalPages ? FontWeight.bold : FontWeight.normal)),
                ),
              IconButton(
                onPressed: pageIndex == totalPages ? null : next,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
