import 'dart:async';
import 'dart:io'; // Import required for HttpOverrides

import 'package:flutter/material.dart';

// --- REAL IMPORTS ---
import '../../amis/data/amis_service.dart'; // Using the real service now
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/core/network/api.dart'; // Ensure this exports Api and ApiException

class AmisPage extends StatefulWidget {
  const AmisPage({super.key});

  @override
  State<AmisPage> createState() => _AmisPageState();
}

class _AmisPageState extends State<AmisPage> {
  // Services - Using the Real AmiService
  final AmiService _amiService = AmiService();
  late final AuthUserService _authUserService;
  
  // We removed AuthService as requested.

  // State Variables
  String viewMode = 'amis';
  Utilisateur? currentUser;
  bool isLoadingUser = true;

  List<Utilisateur> amis = [];
  List<Utilisateur> receivedInvitations = [];

  String searchQuery = '';
  Utilisateur? searchedUser;
  bool searchError = false;
  Timer? _debounce;

  bool inviteLoading = false;
  RelationStatus? searchedRelationStatus;
  String? inviteError;

  String? currentUserId;

  @override
  void initState() {
    super.initState();
    
    // --- ENABLE NETWORK DEBUGGING ---
    HttpOverrides.global = DebugHttpOverrides(); 
    print("🐞 DEBUG MODE: HttpOverrides enabled. Check terminal for URIs.");

    _authUserService = AuthUserService(Api());
    _initData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Helper for consistent logging
  void _log(String tag, String message, {bool isError = false}) {
    final color = isError ? '\x1B[31m' : '\x1B[32m'; // Red or Green
    final reset = '\x1B[0m';
    print('$color[$tag] $message$reset');
  }

  Future<void> _initData() async { 
    final authController = Provider.of<AuthController>(context, listen: false);
    currentUserId = authController.currentUser.value?.id;

    if (currentUserId != null) {
      try {
        setState(() {
          currentUser = authController.currentUser.value;
          isLoadingUser = false;
        });
        
        if (currentUser?.id != null) {
          _log("INIT", "User loaded: ${currentUser!.id}");
          _chargerAmis();
          _loadReceivedInvitations();
        }
      } catch (e) {
        _log("INIT", "Error parsing user: $e", isError: true);
        setState(() => isLoadingUser = false);
      }
    } else {
      _log("INIT", "No user found in SharedPreferences", isError: true);
      setState(() => isLoadingUser = false);
    }
  }

  // --- API LOADERS ---

  void _chargerAmis() {
    if (currentUser == null) return;
    
    _log("API_REQ", "GET Amis for user: ${currentUser!.id}");

    _amiService.getAmis(currentUser!.id).then((data) {
      _log("API_RES", "GET Amis Success. Count: ${data.length}");
      setState(() {
        amis = data;
      });
    }).catchError((err) {
      _log("API_ERR", "GET Amis Failed: $err", isError: true);
    });
  }

  void _loadReceivedInvitations() {
    if (currentUser == null) return;

    _log("API_REQ", "GET Invitations for user: ${currentUser!.id}");

    _amiService.getReceivedInvitationSenders(currentUser!.id).then((users) {
      _log("API_RES", "GET Invitations Success. Count: ${users.length}");
      setState(() {
        receivedInvitations = users;
      });
    }).catchError((err) {
      _log("API_ERR", "GET Invitations Failed: $err", isError: true);
    });
  }

  // --- ACTIONS ---

  void _supprimerAmi(Utilisateur ami) {
    // Note: Assuming logic to delete friend exists, for now just local removal
    _log("ACTION", "Deleting friend locally: ${ami.id}");
    setState(() {
      amis.removeWhere((u) => u.id == ami.id);
    });
  }

  void _onAcceptInvitation(Utilisateur sender) {
    if (currentUser == null) return;

    _log("API_REQ", "ACCEPT Invite from: ${sender.id}");

    _amiService
        .accepterInvitationParUtilisateurs(sender.id, currentUser!.id)
        .then((_) {
      _log("API_RES", "ACCEPT Invite Success");
      setState(() {
        receivedInvitations.removeWhere((u) => u.id == sender.id);
        amis.add(sender);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vous êtes maintenant amis avec ${sender.prenom}")),
      );
    }).catchError((err) {
      _log("API_ERR", "ACCEPT Invite Failed: $err", isError: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'acceptation")),
      );
    });
  }

  void _onRefuseInvitation(Utilisateur sender) {
    if (currentUser == null) return;

    _log("API_REQ", "REFUSE Invite from: ${sender.id}");

    setState(() {
      receivedInvitations.removeWhere((u) => u.id == sender.id);
    });

    _amiService
        .refuserInvitationParUtilisateurs(sender.id, currentUser!.id)
        .then((_) {
      _log("API_RES", "REFUSE Invite Backend Success");
    }).catchError((err) {
      _log("API_ERR", "REFUSE Invite Failed: $err", isError: true);
    });
  }

  // --- SEARCH & INVITE LOGIC ---

  static RelationStatus _parseStatus(String? status) {
    switch (status) {
      case 'NONE': return RelationStatus.NONE;
      case 'EN_ATTENTE': return RelationStatus.EN_ATTENTE;
      case 'EN_ATTENTE_RECU': return RelationStatus.EN_ATTENTE_RECU;
      case 'ACCEPTE': return RelationStatus.ACCEPTE;
      case 'REFUSE': return RelationStatus.REFUSE;
      default: return RelationStatus.UNKNOWN;
    }
  }

  void _fetchRelationStatus(Utilisateur user) {
    if (currentUser == null) return;

    _log("API_REQ", "STATUS for: ${user.id}");
    _amiService.getStatus(currentUser!.id, user.id).then((response) {
      final resolvedUser = response.user ?? user;
      _log("API_RES", "STATUS: ${response.status} for ${resolvedUser.id}");

      setState(() {
        searchedUser = resolvedUser;
        searchedRelationStatus = response.status;
        searchError = false;
      });
    }).catchError((e) {
      _log("API_ERR", "STATUS Failed: $e", isError: true);
      setState(() => searchError = true);
    });
  }

  void _rechercheSmart(String query) {
    final v = query.trim();
    setState(() {
      searchQuery = query;
      inviteError = null;
      searchedRelationStatus = null;
      searchedUser = null;
      searchError = false;
    });

    if (v.isEmpty || currentUser == null) return;

    // Search the user by email or numero, then fetch relation status.
    _authUserService.chercherParEmail(v).then((user) {
      setState(() {
        searchedUser = user;
        searchError = false;
      });
      _fetchRelationStatus(user);
    }).catchError((e) {
      // If not found by email, try numero
      _authUserService.chercherParNumero(v).then((user) {
        setState(() {
          searchedUser = user;
          searchError = false;
        });
        _fetchRelationStatus(user);
      }).catchError((e) {
        setState(() {
          searchError = true;
        });
      });
    });
  }


  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _rechercheSmart(query);
    });
  }

  void _envoyerInvitation() {
    if (searchedUser == null || currentUser == null) return;

    if (currentUser!.id == searchedUser!.id) {
      setState(() => inviteError = "Vous ne pouvez pas vous inviter vous-même.");
      return;
    }

    _log("API_REQ", "SEND INVITE to ${searchedUser!.id}");

    setState(() {
      inviteLoading = true;
      inviteError = null;
    });

    _amiService.inviter(currentUser!.id, searchedUser!.id).then((_) {
      _log("API_RES", "SEND INVITE Success");
      setState(() {
        inviteLoading = false;
        searchedRelationStatus = RelationStatus.EN_ATTENTE;
      });
    }).catchError((err) {
      _log("API_ERR", "SEND INVITE Failed: $err", isError: true);
      setState(() {
        inviteLoading = false;
        inviteError = "Échec de l'invitation.";
      });
    });
  }

  // --- UI Helpers ---
  ImageProvider _getUserImage(Utilisateur u) {
    return const AssetImage('assets/avatar.png');
  }

  bool _canInviteToSearchedUser() {
    final status = searchedRelationStatus;
    if (status == null) return true;
    return status == RelationStatus.NONE ||
        status == RelationStatus.REFUSE ||
        status == RelationStatus.UNKNOWN;
  }

  String _inviteButtonLabel() {
    if (inviteLoading) return "...";

    switch (searchedRelationStatus) {
      case RelationStatus.EN_ATTENTE:
        return "En attente";
      case RelationStatus.EN_ATTENTE_RECU:
        return "Invitation recue";
      case RelationStatus.ACCEPTE:
        return "Amis";
      case RelationStatus.REFUSE:
        return "Ajouter";
      default:
        return "Ajouter";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes amis'),
        centerTitle: true,
      ),
      body: isLoadingUser 
          ? const Center(child: CircularProgressIndicator()) 
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(child: _buildTabButton('Mes amis', 'amis', true)),
                    Expanded(child: _buildTabButton('Mes invitations', 'invitations', false)),
                  ],
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add, size: 20),
                    label: const Text("Ajouter"),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Numéro ou Nom...",
                        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: const Icon(Icons.search),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ],
              ),
              if (searchedUser != null)
                Container(
                  margin: const EdgeInsets.only(top: 14, bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 24, backgroundImage: _getUserImage(searchedUser!)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${searchedUser!.nom} ${searchedUser!.prenom}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(searchedUser!.email ?? ''),
                                Text(searchedUser!.telephone ?? ''),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: (inviteLoading || !_canInviteToSearchedUser()) ? null : _envoyerInvitation,
                            child: Text(_inviteButtonLabel()),
                          ),
                        ],
                      ),
                      if (inviteError != null)
                        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(inviteError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                    ],
                  ),
                )
              else if (searchError)
                 Padding(padding: const EdgeInsets.only(top: 10), child: Text("Aucun utilisateur trouvé.", style: TextStyle(color: Colors.red.shade400))),
              const SizedBox(height: 10),
              viewMode == 'amis' ? _buildAmisList() : _buildInvitationsList(),
            ],
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildTabButton(String label, String mode, bool isLeft) {
    final scheme = Theme.of(context).colorScheme;
    final bool isActive = viewMode == mode;
    return ElevatedButton(
      onPressed: () => setState(() => viewMode = mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? scheme.primary : scheme.surfaceVariant,
        foregroundColor: isActive ? Colors.white : scheme.onSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
                left: isLeft ? const Radius.circular(16) : Radius.zero,
                right: !isLeft ? const Radius.circular(16) : Radius.zero)),
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildAmisList() {
    if (amis.isEmpty) {
      return Padding(padding: const EdgeInsets.only(top: 22), child: Center(child: Text("Vous n’avez pas encore d’amis 🥲", style: TextStyle(color: Colors.grey.shade600, fontSize: 16))));
    }
    return Column(
      children: amis.map((ami) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(backgroundImage: _getUserImage(ami), radius: 26),
            title: Row(children: [
                Text("${ami.nom} ${ami.prenom}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(margin: const EdgeInsets.only(left: 8), width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              ]),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (ami.email != null) Text(ami.email!),
                if (ami.adresse != null) Text(ami.adresse!),
              ]),
            trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _supprimerAmi(ami)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInvitationsList() {
    if (receivedInvitations.isEmpty) {
      return Padding(padding: const EdgeInsets.only(top: 22), child: Center(child: Text("Aucune invitation reçue ✉️", style: TextStyle(color: Colors.grey.shade600, fontSize: 16))));
    }
    return Column(
      children: receivedInvitations.map((user) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(backgroundImage: _getUserImage(user), radius: 26),
            title: Text("${user.nom} ${user.prenom}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (user.email != null) Text(user.email!),
                if (user.telephone != null) Text(user.telephone!),
              ]),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: const Size(38, 32),
                  ),
                  onPressed: () => _onAcceptInvitation(user),
                  child: const Text("Accepter", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: const Size(38, 32),
                  ),
                  onPressed: () => _onRefuseInvitation(user),
                  child: const Text("Refuser", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ]),
          ),
        );
      }).toList(),
    );
  }
}

// =================================================================
// 🐞 DEBUG NETWORK LOGGER
// =================================================================
class DebugHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (Uri uri) {
      print("🌐 [NETWORK] Requesting URI: $uri");
      return "DIRECT";
    };
    return client;
  }
}
