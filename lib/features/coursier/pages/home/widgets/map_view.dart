import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/controllers/home_controller.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/widgets/commande_details_sheet.dart';

import '../services/route_service.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  MapViewState createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _posSub;
  final RouteService _routeService = RouteService();

  LatLng? _myPos; // dernière position connue
  double? _accuracyMeters;
  bool _following =
      true; // si vrai, la caméra suit automatiquement l'utilisateur
  List<LatLng>? _routePoints;
  Commande? _routeCommande;
  String? _pendingRouteCommandeId;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    // 1) Services & permissions
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // L'utilisateur pourra activer ensuite depuis les réglages
      await Geolocator.openLocationSettings();
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      // Impossible d'obtenir la permission sans passer par les réglages
      return;
    }

    // 2) Position initiale
    try {
      final initial = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _updateFromPosition(initial, jumpToMap: true);
    } catch (_) {
      // Si on ne peut pas récupérer la position initiale, on continue quand même
    }

    // 3) Suivi en continu
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3, // mètres (mettre 0 pour toutes les MAJ)
      ),
    ).listen((pos) => _updateFromPosition(pos));
    final auth = context.read<AuthController>();
    final zoneInit = auth.currentUser.value?.zone?.name; // ex: "GRAND_TUNIS"
    if (zoneInit != null && zoneInit.isNotEmpty) {
      // Lance le compteur + premier fetch tout de suite
      await context.read<HomeController>().setZoneAndRefresh(
        zoneInit,
        silent: true,
      );
    }
  }

  // en haut du State
  DateTime? _lastSentAt;

  // ...

  void _updateFromPosition(Position p, {bool jumpToMap = false}) async {
    if (!mounted) return; // ✅ garde-fou 1

    final latLng = LatLng(p.latitude, p.longitude);

    // ✅ garde-fou 2 avant setState
    if (!mounted) return;
    setState(() {
      _myPos = latLng;
      _accuracyMeters = p.accuracy;
    });

    // (optionnel) Throttle des appels réseau : 1 envoi toutes les 5s
    final now = DateTime.now();
    final shouldSend =
        _lastSentAt == null || now.difference(_lastSentAt!).inSeconds >= 5;

    if (shouldSend) {
      _lastSentAt = now;
      try {
        final auth = context.read<AuthController>();
        await auth.updateLocalisation(
          latitude: p.latitude,
          longitude: p.longitude,
        );
      } catch (e) {
        debugPrint('updateLocalisation error: $e');
      }
    }

    if (!mounted) return; // si entre-temps le widget a été démonté
    if (_following) {
      _mapController.move(latLng, _mapController.camera.zoom);
    } else if (jumpToMap) {
      _mapController.move(latLng, 15);
    }

    Map<String, String>? zoneEtSouszone = resolveZone(p.latitude, p.longitude);

    if (zoneEtSouszone != null) {
      final auth = context.read<AuthController>();

      // --- 1) MISE À JOUR DE LA ZONE SI ELLE CHANGE ---
      final currentZone =
          auth.currentUser.value?.zone?.name; // ex: "GRAND_TUNIS"
      final detectedZone = zoneEtSouszone['zone']; // ex: "GRAND_TUNIS"

      if (detectedZone != null &&
          detectedZone.toUpperCase() != (currentZone ?? '').toUpperCase()) {
        print(
          '🌍 Nouvelle zone détectée : $detectedZone (ancienne : $currentZone)',
        );
        try {
          final newZone = Zone.values.firstWhere(
            (z) => z.name.toUpperCase() == detectedZone.toUpperCase(),
          );

          final ok = await auth.updateZone(newZone);
          if (ok) {
            print('✅ Zone mise à jour vers $newZone');
          } else {
            print('⚠️ Échec updateZone');
          }
        } catch (e) {
          print('❌ Zone inconnue : $detectedZone — $e');
        }
      }

      // --- 2) MISE À JOUR DE LA SOUS-ZONE SI ELLE CHANGE ---
      final currentSous =
          auth.currentUser.value?.sousZone?.name; // ex: "TUNIS_CENTRE"
      final detectedSous = zoneEtSouszone['sousZone']; // ex: "TUNIS_CENTRE"

      if (detectedSous != null &&
          detectedSous.toUpperCase() != (currentSous ?? '').toUpperCase()) {
        print(
          '🗺️ Nouvelle sous-zone détectée : $detectedSous (ancienne : $currentSous)',
        );
        try {
          final newSous = SousZone.values.firstWhere(
            (s) => s.name.toUpperCase() == detectedSous.toUpperCase(),
          );

          final ok2 = await auth.updateSousZone(newSous);
          if (ok2) {
            print('✅ Sous-zone mise à jour vers $newSous');
          } else {
            print('⚠️ Échec updateSousZone');
          }
        } catch (e) {
          print('❌ Sous-zone inconnue : $detectedSous — $e');
        }
      }
    } else {
      print('❌ Position hors zones définies');
    }

    // if (zoneEtSouszone != null) {
    //   print("Zone : ${zoneEtSouszone['zone']}, Sous-zone : ${zoneEtSouszone['sousZone']}");
    // } else {
    //   print("Position hors zones définies");
    // }
  }

  /// Méthode publique appelée depuis HomeCoursierPage via GlobalKey
  Future<void> centerOnMe({double zoom = 16}) async {
    if (_myPos == null) {
      try {
        final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        _myPos = LatLng(p.latitude, p.longitude);
        _accuracyMeters = p.accuracy;
      } catch (_) {
        return;
      }
    }
    _following = true; // réactive le suivi
    _mapController.move(_myPos!, zoom);
    if (mounted) setState(() {});
  }

  /// Active/désactive le suivi caméra -> utilisateur (optionnel)
  void enableFollow(bool value) {
    setState(() => _following = value);
    if (value && _myPos != null) {
      _mapController.move(_myPos!, _mapController.camera.zoom);
    }
  }

  List<Marker> _buildCommandeMarkers(
    List<Commande> commandes, {
    String? selectedCommandeId,
  }) {
    Iterable<Commande> visibles = commandes;
    if (selectedCommandeId != null) {
      final selectedOnly =
          commandes.where((c) => c.id == selectedCommandeId).toList();
      if (selectedOnly.isNotEmpty) {
        visibles = selectedOnly;
      }
    }

    return visibles
        .where((c) => c.latitudeDepart != null && c.longitudeDepart != null)
        .map(
          (commande) => Marker(
            point: LatLng(commande.latitudeDepart!, commande.longitudeDepart!),
            width: 80,
            height: 80,
            child: _CommandeMarker(
              commande: commande,
              onTap: () => _handleCommandeTap(commande),
            ),
          ),
        )
        .toList();
  }

  void _handleCommandeTap(Commande commande) {
    if (!mounted) return;
    final homeCtrl = context.read<HomeController>();
    final bool isMine =
        homeCtrl.mesCommandes.any((c) => c.id == commande.id);
    homeCtrl.selectCommande(commande);
    _loadRouteForSelectedCommande(commande, isMine: isMine);
  }

  void _loadRouteForSelectedCommande(
    Commande commande, {
    required bool isMine,
  }) {
    final currentPos = _myPos;
    if (isMine && currentPos != null) {
      final bool goToArrival = commande.qrCodeDepartScanne == true;
      final double? targetLat = goToArrival
          ? commande.latitudeDestination
          : commande.latitudeDepart;
      final double? targetLng = goToArrival
          ? commande.longitudeDestination
          : commande.longitudeDepart;
      if (targetLat != null && targetLng != null) {
        _loadRouteForCommande(
          commande,
          startOverride: currentPos,
          endOverride: LatLng(targetLat, targetLng),
        );
        return;
      }
    }

    final hasDepart =
        commande.latitudeDepart != null && commande.longitudeDepart != null;
    final hasDestination = commande.latitudeDestination != null &&
        commande.longitudeDestination != null;

    if (hasDepart && hasDestination) {
      _loadRouteForCommande(commande);
      return;
    }

    setState(() {
      _routePoints = null;
      _routeCommande = null;
    });
  }

  Future<void> _loadRouteForCommande(
    Commande commande, {
    LatLng? startOverride,
    LatLng? endOverride,
  }) async {
    LatLng? start = startOverride;
    LatLng? end = endOverride;

    start ??= (commande.latitudeDepart != null &&
            commande.longitudeDepart != null)
        ? LatLng(commande.latitudeDepart!, commande.longitudeDepart!)
        : null;
    end ??= (commande.latitudeDestination != null &&
            commande.longitudeDestination != null)
        ? LatLng(commande.latitudeDestination!, commande.longitudeDestination!)
        : null;

    if (start == null || end == null) {
      setState(() {
        _routePoints = null;
        _routeCommande = null;
      });
      return;
    }

    final LatLng routeStart = start;
    final LatLng routeEnd = end;

    setState(() {
      _routeCommande = commande;
    });

    try {
      final route =
          await _routeService.fetchRoute(start: routeStart, end: routeEnd);
      if (!mounted) return;
      final points =
          route.isEmpty ? <LatLng>[routeStart, routeEnd] : route;
      setState(() {
        _routePoints = points;
      });
      _fitCameraToBounds(LatLngBounds.fromPoints(points));
    } catch (e) {
      if (!mounted) return;
      debugPrint('Route fetch error: $e');
      setState(() {
        _routePoints = [routeStart, routeEnd];
        _routeCommande = commande;
      });
      _fitCameraToBounds(LatLngBounds.fromPoints(_routePoints!));
    }
  }

  void _fitCameraToBounds(LatLngBounds bounds) {
    if (!mounted) return;
    setState(() => _following = false);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  Future<void> _showCommandeDetails(Commande commande) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => CommandeDetailsSheet(commande: commande),
    );
  }

  Future<void> openCommandeDetails(Commande commande) {
    return _showCommandeDetails(commande);
  }

  @override
  Widget build(BuildContext context) {
    final homeCtrl = context.watch<HomeController>();
    final commandes = homeCtrl.activeCommandes;
    final selectedCommande = homeCtrl.selectedCommande;
    final selectedId = selectedCommande?.id;

    final commandeMarkers = _buildCommandeMarkers(
      commandes,
      selectedCommandeId: selectedId,
    );

    final bool selectedIsMine = selectedCommande != null &&
        homeCtrl.mesCommandes.any((c) => c.id == selectedCommande.id);
    final currentPos = _myPos;
    final bool hasDepartCoords = selectedCommande?.latitudeDepart != null &&
        selectedCommande?.longitudeDepart != null;
    final bool hasDestinationCoords =
        selectedCommande?.latitudeDestination != null &&
            selectedCommande?.longitudeDestination != null;
    final bool hasCustomData = selectedCommande != null &&
        selectedIsMine &&
        currentPos != null &&
        ((selectedCommande.qrCodeDepartScanne == true
                ? hasDestinationCoords
                : hasDepartCoords));
    final bool hasDefaultData =
        selectedCommande != null && hasDepartCoords && hasDestinationCoords;

    if (selectedCommande != null &&
        selectedCommande.id != _routeCommande?.id &&
        _pendingRouteCommandeId != selectedCommande.id &&
        (hasCustomData || hasDefaultData)) {
      final commandeToLoad = selectedCommande;
      final bool isMineForLoad = selectedIsMine;
      _pendingRouteCommandeId = commandeToLoad.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pendingRouteCommandeId = null;
        _loadRouteForSelectedCommande(
          commandeToLoad,
          isMine: isMineForLoad,
        );
      });
    } else if (selectedCommande == null && _routePoints != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _routePoints = null;
          _routeCommande = null;
          _pendingRouteCommandeId = null;
        });
      });
    }

    final Polyline? scooterRoute = (_routePoints != null && _routePoints!.length > 1)
        ? Polyline(
            points: _routePoints!,
            strokeWidth: 5,
            color: Colors.deepPurpleAccent.withOpacity(0.9),
            borderColor: Colors.white.withOpacity(0.6),
            borderStrokeWidth: 2,
          )
        : null;
    final Marker? arrivalRouteMarker = (scooterRoute != null)
        ? Marker(
            point: _routePoints!.last,
            width: 42,
            height: 42,
            child: const _RouteEndpointMarker(isStart: false),
          )
        : null;
    final startCenter =
        _myPos ?? const LatLng(36.8065, 10.1815); // Tunis par défaut

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: startCenter,
        initialZoom: 12,
        onPositionChanged: (camera, hasGesture) {
          // Si l'utilisateur déplace/zoome manuellement la carte, on stoppe le suivi
          if (hasGesture && _following) {
            setState(() => _following = false);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.yemchiwyji.app',
          // attributionBuilder: (_) => const Text('© OSM, © CARTO'),
        ),

        if (scooterRoute != null)
          PolylineLayer(
            polylines: [scooterRoute],
          ),

        if (commandeMarkers.isNotEmpty) MarkerLayer(markers: commandeMarkers),

        if (arrivalRouteMarker != null)
          MarkerLayer(
            markers: [arrivalRouteMarker],
          ),

        // Cercle d'accuracy (optionnel)
        if (_myPos != null && _accuracyMeters != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: _myPos!,
                radius: _accuracyMeters!, // mètres
                useRadiusInMeter: true,
                color: Colors.blue.withOpacity(0.12),
                borderColor: Colors.blue.withOpacity(0.35),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),

        // Marqueur position utilisateur
        if (_myPos != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _myPos!,
                width: 44,
                height: 44,
                child: _MyLocationPin(isMoving: _following),
              ),
            ],
          ),
      ],
    );
  }
}

class _MyLocationPin extends StatelessWidget {
  final bool isMoving;
  const _MyLocationPin({required this.isMoving});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: isMoving ? 1.05 : 1.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white, width: 2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}


class _RouteEndpointMarker extends StatelessWidget {
  final bool isStart;
  const _RouteEndpointMarker({required this.isStart});

  @override
  Widget build(BuildContext context) {
    final Color fillColor =
        isStart ? const Color(0xFF34D058) : const Color(0xFFEA4335);
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isStart ? Icons.flag : Icons.location_on,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _CommandeMarker extends StatelessWidget {
  final Commande commande;
  final VoidCallback onTap;

  const _CommandeMarker({required this.commande, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = commande.localisationDepart ?? 'Point pickup';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.78),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.circle, size: 0),
          ),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// Table des zones (bornes simples rectangulaires)
const List<Map<String, Object>> kZones = [
  {
    "name": "TUNIS_CENTRE",
    "zone": "GRAND_TUNIS",
    "latMin": 36.75,
    "latMax": 36.92,
    "lngMin": 10.10,
    "lngMax": 10.30,
  },
  {
    "name": "ARIANA_NORD",
    "zone": "GRAND_TUNIS",
    "latMin": 36.80,
    "latMax": 36.97,
    "lngMin": 10.05,
    "lngMax": 10.20,
  },
  {
    "name": "BEN_AROUS_SUD",
    "zone": "GRAND_TUNIS",
    "latMin": 36.65,
    "latMax": 36.83,
    "lngMin": 10.15,
    "lngMax": 10.35,
  },
  {
    "name": "MANOUBA_OUEST",
    "zone": "GRAND_TUNIS",
    "latMin": 36.72,
    "latMax": 36.93,
    "lngMin": 9.95,
    "lngMax": 10.12,
  },
  {
    "name": "BIZERTE_METRO",
    "zone": "COTIER_NORD",
    "latMin": 37.15,
    "latMax": 37.32,
    "lngMin": 9.75,
    "lngMax": 9.98,
  },
  {
    "name": "NABEUL_HAMMAMET",
    "zone": "COTIER_NORD",
    "latMin": 36.33,
    "latMax": 36.50,
    "lngMin": 10.40,
    "lngMax": 10.70,
  },
  {
    "name": "SOUSSE",
    "zone": "CENTRE_EST",
    "latMin": 35.75,
    "latMax": 35.90,
    "lngMin": 10.55,
    "lngMax": 10.70,
  },
  {
    "name": "MONASTIR",
    "zone": "CENTRE_EST",
    "latMin": 35.67,
    "latMax": 35.85,
    "lngMin": 10.75,
    "lngMax": 10.95,
  },
  {
    "name": "MAHDIA",
    "zone": "CENTRE_EST",
    "latMin": 35.35,
    "latMax": 35.60,
    "lngMin": 10.95,
    "lngMax": 11.10,
  },
  {
    "name": "SFAX",
    "zone": "SFAX",
    "latMin": 34.63,
    "latMax": 34.83,
    "lngMin": 10.60,
    "lngMax": 10.85,
  },
  {
    "name": "GABES",
    "zone": "SUD_EST",
    "latMin": 33.80,
    "latMax": 33.95,
    "lngMin": 10.00,
    "lngMax": 10.20,
  },
  {
    "name": "DJERBA_ZARZIS",
    "zone": "SUD_EST",
    "latMin": 33.40,
    "latMax": 33.90,
    "lngMin": 10.60,
    "lngMax": 11.20,
  },
  {
    "name": "KAIROUAN",
    "zone": "INTERIEUR",
    "latMin": 35.55,
    "latMax": 35.75,
    "lngMin": 10.00,
    "lngMax": 10.20,
  },
];
Map<String, String>? resolveZone(double lat, double lng) {
  for (final z in kZones) {
    final latMin = z["latMin"] as double;
    final latMax = z["latMax"] as double;
    final lngMin = z["lngMin"] as double;
    final lngMax = z["lngMax"] as double;
    if (lat >= latMin && lat <= latMax && lng >= lngMin && lng <= lngMax) {
      return {"zone": z["zone"] as String, "sousZone": z["name"] as String};
    }
  }
  return null; // hors zones
}
