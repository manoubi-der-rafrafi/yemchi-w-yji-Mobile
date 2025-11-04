import 'package:flutter/material.dart';

class AmisPage extends StatefulWidget {
  const AmisPage({super.key});

  @override
  State<AmisPage> createState() => _AmisPageState();
}

class _AmisPageState extends State<AmisPage> {
  String viewMode = 'amis'; // 'amis' or 'invitations'
  String searchQuery = '';
  Map<String, dynamic>? searchedUser;

  // Static sample data
  List<Map<String, dynamic>> amis = [
    {
      'nom': 'Jean',
      'prenom': 'Martin',
      'image': 'assets/avatar.png',
      'email': 'jean.martin@email.com',
      'adresse': 'Lyon',
      'statut': 'actif'
    },
    {
      'nom': 'Sophie',
      'prenom': 'Durand',
      'image': 'assets/avatar.png',
      'email': 'sophie.durand@email.com',
      'adresse': 'Paris',
      'statut': 'inactif'
    },
  ];

  List<Map<String, dynamic>> receivedInvitations = [
    {
      'nom': 'Paul',
      'prenom': 'Leroux',
      'image': 'assets/avatar.png',
      'email': 'paul.leroux@email.com',
      'telephone': '+33 6 88 12 34 56',
    },
  ];

  bool inviteLoading = false;
  bool inviteSent = false;
  String? inviteError;

  void rechercheSmart(String query) {
    setState(() {
      searchQuery = query;
      searchedUser = query.isNotEmpty
          ? {
              'nom': 'Camille',
              'prenom': 'Moreau',
              'image': 'assets/avatar.png',
              'email': 'camille.moreau@email.com',
              'telephone': '+33 6 77 88 99 00'
            }
          : null;
      inviteLoading = false;
      inviteSent = false;
      inviteError = null;
    });
  }

  void envoyerInvitation(String id) async {
    setState(() { inviteLoading = true; });
    await Future.delayed(const Duration(seconds: 1)); // simulate network send
    setState(() {
      inviteLoading = false;
      inviteSent = true;
    });
  }

  bool isSelf(String id) => false; // always false in static sample

  void supprimerAmi(int i) {
    setState(() {
      amis.removeAt(i);
    });
  }

  void onAcceptInvitation(int i) {
    setState(() {
      amis.add(receivedInvitations[i]);
      receivedInvitations.removeAt(i);
    });
  }

  void onRefuseInvitation(int i) {
    setState(() {
      receivedInvitations.removeAt(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes amis'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented control
              Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => viewMode = 'amis'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: viewMode == 'amis'
                              ? Colors.green
                              : Colors.grey.shade300,
                          foregroundColor:
                              viewMode == 'amis' ? Colors.white : Colors.black87,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16))),
                          elevation: 0,
                        ),
                        child: const Text('Mes amis'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => viewMode = 'invitations'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: viewMode == 'invitations'
                              ? Colors.green
                              : Colors.grey.shade300,
                          foregroundColor: viewMode == 'invitations'
                              ? Colors.white
                              : Colors.black87,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(16),
                                  bottomRight: Radius.circular(16))),
                          elevation: 0,
                        ),
                        child: const Text('Mes invitations'),
                      ),
                    ),
                  ],
                ),
              ),
              // Add friend button and search field
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add, size: 20),
                    label: const Text("Ajouter un ami"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        searchedUser = null;
                        searchQuery = '';
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Numéro (8 chiffres) ou email…",
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: const Icon(Icons.search),
                      ),
                      onChanged: rechercheSmart,
                    ),
                  ),
                ],
              ),
              // Search result area
              if (searchedUser != null)
                Container(
                  margin: const EdgeInsets.only(top: 14, bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage:
                                AssetImage(searchedUser!['image'] ?? ''),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${searchedUser!['nom']} ${searchedUser!['prenom']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(searchedUser!['email']),
                                Text(searchedUser!['telephone']),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: (inviteLoading || inviteSent) ? null : () => envoyerInvitation("1"),
                            child: Text(inviteSent
                                ? "Invitation envoyée"
                                : inviteLoading
                                    ? "Envoi…"
                                    : "Ajouter Ami(e)"),
                          ),
                        ],
                      ),
                      if (inviteError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(inviteError!,
                              style:
                                  const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              // Segment content
              viewMode == 'amis'
                  ? amis.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 22),
                          child: Center(
                              child: Text(
                                  "Vous n’avez pas encore d’amis 🥲",
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 16))),
                        )
                      : Column(
                          children: amis.asMap().entries.map((entry) {
                            final i = entry.key;
                            final ami = entry.value;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: AssetImage(ami['image']),
                                  radius: 26,
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      "${ami['nom']} ${ami['prenom']}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    if (ami['statut'] == 'actif')
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    else
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ami['email']),
                                    Text(ami['adresse']),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.red),
                                  tooltip: 'Supprimer',
                                  onPressed: () => supprimerAmi(i),
                                ),
                              ),
                            );
                          }).toList(),
                        )
                  : receivedInvitations.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 22),
                          child: Center(
                              child: Text(
                                  "Aucune invitation reçue pour le moment ✉️",
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 16))),
                        )
                      : Column(
                          children: receivedInvitations.asMap().entries.map((entry) {
                            final i = entry.key;
                            final u = entry.value;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: AssetImage(u['image']),
                                  radius: 26,
                                ),
                                title: Text(
                                  "${u['nom']} ${u['prenom']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u['email']),
                                    Text(u['telephone']),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        minimumSize: const Size(38, 32),
                                      ),
                                      onPressed: () => onAcceptInvitation(i),
                                      child: const Text("Accepter",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        minimumSize: const Size(38, 32),
                                      ),
                                      onPressed: () => onRefuseInvitation(i),
                                      child: const Text("Refuser",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }
}
