import 'package:flutter/material.dart';

class CommandesPage extends StatefulWidget {
  const CommandesPage({super.key});

  @override
  State<CommandesPage> createState() => _CommandesPageState();
}

class _CommandesPageState extends State<CommandesPage> {
  String viewMode = 'mes'; // or 'envoyees'
  String search = '';
  String status = 'tous';
  bool loading = false;
  String? error;

  // Pagination:
  int pageIndex = 1;
  int pageSize = 5;
  final List<int> pageSizes = [5, 10, 20];

  // Static demo orders
  List<Map<String, dynamic>> allOrders = [
    {
      'id': '1',
      'date_demande': DateTime(2025, 11, 1, 14, 22),
      'localisation_depart': 'Paris',
      'destination': 'Lyon',
      'statut': 'Confirmée',
      'prix': 29.99,
      'mode_paiement': 'Carte',
      'clientId': '101',
    },
    {
      'id': '2',
      'date_demande': DateTime(2025, 11, 2, 10, 5),
      'localisation_depart': 'Marseille',
      'destination': 'Nice',
      'statut': 'En attente',
      'prix': 18.00,
      'mode_paiement': 'Espèces',
      'clientId': '102',
    },
    {
      'id': '3',
      'date_demande': DateTime(2025, 10, 29, 9, 40),
      'localisation_depart': 'Paris',
      'destination': 'Lille',
      'statut': 'Envoyee',
      'prix': 37.5,
      'mode_paiement': 'Carte',
      'clientId': '103',
    },
    {
      'id': '4',
      'date_demande': DateTime(2025, 10, 28, 15, 12),
      'localisation_depart': 'Dijon',
      'destination': 'Strasbourg',
      'statut': 'Livrée',
      'prix': 41.10,
      'mode_paiement': 'Carte',
      'clientId': '104',
    },
  ];

  // Static clients for envoyees
  Map<String, Map<String, String>> clients = {
    '101': {
      'nom': 'Maya',
      'prenom': 'Durant',
      'image': 'assets/avatar.png',
      'telephone': '+33 6 12 44 33 27',
      'email': 'maya.durant@email.com',
    },
    '102': {
      'nom': 'Léo',
      'prenom': 'Martin',
      'image': 'assets/avatar.png',
      'telephone': '+33 7 66 55 44 33',
      'email': 'leo.martin@email.com',
    },
    '103': {
      'nom': 'Ines',
      'prenom': 'Benoit',
      'image': 'assets/avatar.png',
      'telephone': '+33 6 52 61 70 89',
      'email': 'ines.benoit@email.com',
    },
    '104': {
      'nom': 'Lucas',
      'prenom': 'Tremblay',
      'image': 'assets/avatar.png',
      'telephone': '+33 6 11 22 33 44',
      'email': 'lucas.tremblay@email.com',
    },
  };

  List<Map<String, dynamic>> get filtered {
    var list = allOrders
        .where((o) =>
            (viewMode == 'mes'
                ? true
                : o['statut'].toString().toLowerCase() == 'envoyee') &&
            (status == 'tous' ||
                (o['statut'] ?? '')
                        .toLowerCase()
                        .replaceAll("é", "e")
                        .replaceAll("è", "e") ==
                    status) &&
            (search.isEmpty ||
                o['id'] == search ||
                (o['localisation_depart'] as String)
                    .toLowerCase()
                    .contains(search.toLowerCase()) ||
                (o['destination'] as String)
                    .toLowerCase()
                    .contains(search.toLowerCase())))
        .toList();
    return list;
  }

  int get totalPages => (filtered.length / pageSize).ceil().clamp(1, 9999);
  int get totalItems => filtered.length;

  List<Map<String, dynamic>> get pageSlice {
    final start = (pageIndex - 1) * pageSize;
    final end = (start + pageSize).clamp(0, totalItems);
    return filtered.sublist(start, end);
  }

  String mapPaiement(String? mode) {
    switch (mode) {
      case "Carte":
        return "Carte";
      case "Espèces":
        return "Espèces";
      default:
        return "—";
    }
  }

  String getStatusClass(String? statut) {
    switch ((statut ?? '').toLowerCase()) {
      case 'en attente':
        return 'orange';
      case 'confirmee':
        return 'blue';
      case 'en cours':
        return 'violet';
      case 'livree':
        return 'green';
      case 'annulee':
        return 'red';
      case 'envoyee':
        return 'teal';
      case 'acceptee':
      case 'accepter':
        return 'purple';
      default:
        return 'grey';
    }
  }

  Color getStatusColor(String? statut) {
    switch (getStatusClass(statut)) {
      case 'orange':
        return Colors.deepOrange;
      case 'blue':
        return Colors.blue;
      case 'violet':
        return Colors.purple;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      case 'purple':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  void applyFilters([_]) {
    setState(() {
      pageIndex = 1;
    });
  }

  void onChangePageSize(int? newSize) {
  if (newSize == null) return;
  setState(() {
    pageSize = newSize;
    pageIndex = 1;
  });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique de mes commandes'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Text(error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 20)),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & subtitle
                      const Text(
                        "Historique de mes commandes",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text("Consultez et suivez vos commandes passées facilement",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14)),
                      const SizedBox(height: 18),
                      // Segmented control & filters
                      Row(
                        children: [
                          // Segment
                          Expanded(
                            child: Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => viewMode = 'mes');
                                    applyFilters();
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: viewMode == 'mes'
                                          ? Colors.green
                                          : Colors.grey.shade200,
                                      foregroundColor: viewMode == 'mes'
                                          ? Colors.white
                                          : Colors.black87,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(14),
                                              bottomLeft: Radius.circular(14))),
                                      elevation: 0),
                                  child: const Text('Mes commandes'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => viewMode = 'envoyees');
                                    applyFilters();
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: viewMode == 'envoyees'
                                          ? Colors.green
                                          : Colors.grey.shade200,
                                      foregroundColor: viewMode == 'envoyees'
                                          ? Colors.white
                                          : Colors.black87,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(14),
                                              bottomRight: Radius.circular(14))),
                                      elevation: 0),
                                  child: const Text('Commandes envoyées'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Search
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText:
                                          'Rechercher (id, départ, destination)…',
                                      contentPadding: const EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      suffixIcon: const Icon(Icons.search),
                                    ),
                                    onChanged: (s) {
                                      setState(() {
                                        search = s;
                                        applyFilters();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Status dropdown
                                DropdownButton<String>(
                                  value: status,
                                  borderRadius: BorderRadius.circular(12),
                                  items: [
                                    'tous',
                                    'en attente',
                                    'confirmee',
                                    'en cours',
                                    'livree',
                                    'annulee',
                                    'envoyee',
                                    'accepter'
                                  ]
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s[0].toUpperCase() +
                                                s.substring(1)),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      status = val!;
                                      applyFilters();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Orders table/list
                      Expanded(
                        child: pageSlice.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 22),
                                  child: Text(
                                      viewMode == 'mes'
                                          ? 'Aucune commande trouvée.'
                                          : 'Aucune commande envoyée à vous par un ami.',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16)),
                                ),
                              )
                            : ListView(
                                children: [
                                  DataTable(
                                    columns: viewMode == 'mes'
                                        ? const [
                                            DataColumn(label: Text('Date')),
                                            DataColumn(label: Text('Départ')),
                                            DataColumn(label: Text('Destination')),
                                            DataColumn(label: Text('Statut')),
                                            DataColumn(label: Text('Prix')),
                                            DataColumn(label: Text('Paiement')),
                                          ]
                                        : const [
                                            DataColumn(label: Text('Expéditeur')),
                                            DataColumn(label: Text('Départ')),
                                            DataColumn(label: Text('Statut')),
                                          ],
                                    rows: pageSlice.map((c) {
                                      if (viewMode == 'mes') {
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(
                                                "${c['date_demande'].year}-${c['date_demande'].month.toString().padLeft(2, '0')}-${c['date_demande'].day.toString().padLeft(2, '0')} ${c['date_demande'].hour.toString().padLeft(2, '0')}:${c['date_demande'].minute.toString().padLeft(2, '0')}")),
                                            DataCell(Text(c['localisation_depart'])),
                                            DataCell(Text(c['destination'])),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 3,
                                                    horizontal: 10
                                                ),
                                                decoration: BoxDecoration(
                                                  color: getStatusColor(
                                                      c['statut'])
                                                      .withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  c['statut'],
                                                  style: TextStyle(
                                                    color: getStatusColor(c['statut']),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(c['statut'].toString().toLowerCase() != 'envoyee'
                                                ? "${c['prix']} DT"
                                                : "--")),
                                            DataCell(Text(c['statut'].toString().toLowerCase() != 'envoyee'
                                                ? mapPaiement(c['mode_paiement'])
                                                : "--")),
                                          ],
                                        );
                                      } else {
                                        // envoyees
                                        final cli = clients[(c['clientId']).toString()];
                                        return DataRow(
                                          cells: [
                                            DataCell(Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundImage: AssetImage(cli?['image'] ?? 'assets/avatar.png'),
                                                  radius: 17,
                                                ),
                                                const SizedBox(width: 7),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('${cli?['nom'] ?? "—"} ${cli?['prenom'] ?? ""}',
                                                        style: const TextStyle(fontWeight: FontWeight.w500)),
                                                    Row(
                                                      children: [
                                                        Text(cli?['telephone'] ?? "—",
                                                            style: const TextStyle(fontSize: 12)),
                                                        Text(" • ", style: TextStyle(color: Colors.grey.shade600)),
                                                        Text(cli?['email'] ?? "—", style: const TextStyle(fontSize: 12)),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ],
                                            )),
                                            DataCell(Text(c['localisation_depart'])),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 3,
                                                    horizontal: 10
                                                ),
                                                decoration: BoxDecoration(
                                                  color: getStatusColor(
                                                      c['statut'])
                                                      .withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  c['statut'],
                                                  style: TextStyle(
                                                    color: getStatusColor(c['statut']),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                    }).toList(),
                                  ),
                                ],
                              ),
                      ),
                      // Pagination bar
                      if (pageSlice.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 10),
                          child: Row(
                            children: [
                              const Text("Afficher", style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              DropdownButton<int>(
                                value: pageSize,
                                onChanged: onChangePageSize,
                                items: pageSizes
                                    .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                                    .toList(),
                              ),
                              const Text("par page"),
                              const SizedBox(width: 20),
                              Text(
                                "• ${(pageIndex - 1) * pageSize + 1}"
                                " – "
                                "${(pageIndex * pageSize).clamp(1, totalItems)}"
                                " sur $totalItems",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: pageIndex == 1 ? null : prev,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              for (int i = 1; i <= totalPages; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1),
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                        foregroundColor: i == pageIndex
                                            ? Colors.green
                                            : Colors.black),
                                    onPressed: () => goToPage(i),
                                    child: Text('$i',
                                        style: TextStyle(
                                            fontWeight: i == pageIndex
                                                ? FontWeight.bold
                                                : FontWeight.normal)),
                                  ),
                                ),
                              IconButton(
                                onPressed: pageIndex == totalPages ? null : next,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
      backgroundColor: Colors.grey.shade100,
    );
  }
}
