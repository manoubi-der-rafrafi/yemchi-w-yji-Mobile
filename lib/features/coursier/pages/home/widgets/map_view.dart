import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/commande/dto/commande_transporteur_principal_response.dart';
import 'package:yemchi_wyji/features/commande/dto/transporteur_panne_commandes_response.dart';
import 'package:yemchi_wyji/features/commande/dto/transporteur_secours_commandes_response.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/controllers/home_controller.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/pages/transporteur_panne_details_page.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/pages/transporteur_secours_details_page.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/widgets/commande_details_sheet.dart';

import '../services/route_service.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  MapViewState createState() => MapViewState();
}

enum _MapFollowMode { free, centered, heading }

class MapViewState extends State<MapView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const MethodChannel _screenChannel = MethodChannel('yemchi/screen');
  static const String _defaultMapboxAccessToken = '';
  static const String _mapboxAccessToken = String.fromEnvironment(
    'ACCESS_TOKEN',
    defaultValue: _defaultMapboxAccessToken,
  );
  static const String _fallbackTileUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const String _webMapboxTileUrlTemplate =
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}{r}?access_token=$_mapboxAccessToken';
  final MapController _webMapController = MapController();
  mbx.MapboxMap? _mapboxMap;
  mbx.CircleAnnotationManager? _markerAnnotationManager;
  mbx.PolylineAnnotationManager? _polylineAnnotationManager;
  final Map<String, VoidCallback> _annotationTapHandlers =
      <String, VoidCallback>{};
  StreamSubscription<Position>? _posSub;
  StreamSubscription<CompassEvent>? _compassSub;
  final RouteService _routeService = RouteService();
  static const Color _markerArrivalColor = Color(0xFF34D058);
  static const Color _markerDepartColor = Color(0xFF2575FC);
  static const double _navigationZoom = 17.0;
  static const double _navigationPitch = 45.0;
  static const double _navigationTurnNearDistanceMeters = 45.0;
  static const double _navigationTurnApproachDistanceMeters = 95.0;
  static const double _navigationLookAheadMinMeters = 28.0;
  static const double _navigationLookAheadMaxMeters = 110.0;
  static const double _navigationLookAheadPerKmh = 2.2;
  static const double _navigationTurnDetectionAngleDegrees = 24.0;
  static const double _navigationRouteSnapBlend = 0.28;
  static const double _navigationRouteSnapMaxMeters = 12.0;
  static const double _navigationLocalBearingAheadMeters = 24.0;
  static const double _navigationStoppedPitch = 0.0;
  static const double _navigationSlowPitch = 14.0;
  static const double _navigationMediumPitch = 24.0;
  static const double _navigationCruisePitch = 34.0;
  static const double _navigationTurnPitch = 16.0;
  static const double _navigationNearTurnPitch = 8.0;
  static const LatLng _defaultInitialCenter = LatLng(36.8065, 10.1815);
  late final MapOptions _webMapOptions;
  LatLng _cameraCenter = _defaultInitialCenter;
  double _cameraZoom = 12;
  double _cameraRotation = 0;
  double _cameraPitch = 0;
  mbx.MbxEdgeInsets _cameraPadding = mbx.MbxEdgeInsets(
    top: 0,
    left: 0,
    bottom: 0,
    right: 0,
  );
  bool _mapboxStyleReady = false;
  bool _mapboxManagersReady = false;
  bool _mapboxOverlaySyncRunning = false;
  bool _mapboxOverlaySyncQueued = false;

  LatLng? _myPos; // derniÃ¨re position connue
  double? _accuracyMeters;
  double? _headingDegrees;
  _MapFollowMode _manualFollowMode = _MapFollowMode.free;
  bool _navigationModeActive = false;
  String? _pendingRouteCommandeId;
  String? _failedRouteCommandeId;
  DateTime? _lastRouteFailureAt;
  static const Duration _routeFailureRetryDelay = Duration(seconds: 15);
  static const double _minGpsDistanceMeters = 1.2;
  static const double _gpsAccuracyIgnoreAboveMeters = 60;
  static const double _gpsJitterAccuracyMeters = 35;
  static const double _headingReliableSpeedKmh = 5.0;
  static const double _headingVeryReliableSpeedKmh = 18.0;
  static const double _exactHeadingLowSpeedKmh = 4.0;
  static const double _headingBearingDistanceMeters = 8;
  static const double _headingFastBearingDistanceMeters = 4.0;
  static const double _headingFastSmoothingFactor = 0.8;
  static const double _headingSlowSmoothingFactor = 0.35;
  static const double _headingMinMovementMeters = 2.5;
  static const double _headingMaxAccuracyMeters = 35.0;
  static const double _headingJumpRejectDegrees = 85.0;
  static const double _headingJumpRejectMoveMeters = 20.0;
  static const double _compassStrongSmoothingFactor = 0.18;
  static const double _compassFastCatchupSmoothingFactor = 0.35;
  static const double _compassDeadbandDegrees = 1.5;
  static const double _compassJumpRejectDegrees = 70.0;
  static const Duration _compassFreshness = Duration(seconds: 3);
  static const double _compassLowConfidenceAccuracy = 22.0;
  static const Duration _cameraAnimationDuration = Duration(milliseconds: 350);
  late final AnimationController _cameraAnimationController;
  static const Duration _userMarkerAnimationDuration = Duration(
    milliseconds: 250,
  );
  late final AnimationController _userMarkerAnimationController;
  Animation<LatLng>? _userMarkerAnimation;
  VoidCallback? _userMarkerAnimationListener;
  static const Duration _userMarkerCoalesceDuration = Duration(
    milliseconds: 140,
  );
  Timer? _userMarkerCoalesceTimer;
  LatLng? _pendingUserMarkerTarget;
  bool _pendingUserMarkerFlushAfterAnimation = false;
  LatLng? _smoothedMyPos;
  LatLng? get _displayedMyPos => _smoothedMyPos ?? _myPos;
  final ValueNotifier<_UserLocationVisual?> _userLocationNotifier =
      ValueNotifier<_UserLocationVisual?>(null);
  double? _lastSpeedKmh;
  static const double _slowSpeedThresholdKmh = 10;
  static const double _fastSpeedThresholdKmh = 30;
  static const double _slowSpeedZoom = 17.0;
  static const double _mediumSpeedZoom = 16.0;
  static const double _fastSpeedZoom = 15.0;
  static const bool _enableFollowCameraThrottle = true;
  static const double _followCameraDistanceThresholdMeters = 9;
  static const double _followCameraHeadingThresholdDegrees = 4;
  static const Duration _followCameraMinInterval = Duration(milliseconds: 1200);
  static const Duration _cameraRotationMinInterval = Duration(
    milliseconds: 320,
  );
  static const double _navigationFollowCameraDistanceThresholdMeters = 3.2;
  static const double _navigationFollowCameraHeadingThresholdDegrees = 1.4;
  static const Duration _navigationFollowCameraMinInterval = Duration(
    milliseconds: 260,
  );
  static const Duration _navigationCameraRotationMinInterval = Duration(
    milliseconds: 140,
  );
  static const double _manualCenterSnapDistanceMeters = 18;
  static const double _manualCenterZoomDeltaThreshold = 0.2;
  static const double _manualCenterRotationThresholdDegrees = 10;
  static const bool _enableUserNotifierDebounce = true;
  static const double _userNotifierDistanceThresholdMeters = 1.5;
  static const double _userNotifierHeadingThresholdDegrees = 7;
  static const Duration _polylineUpdateMinInterval = Duration(
    milliseconds: 450,
  );
  HomeController? _homeController;
  VoidCallback? _homeControllerListener;
  final ValueNotifier<List<LatLng>?> _polylineNotifier =
      ValueNotifier<List<LatLng>?>(null);
  final ValueNotifier<List<Marker>> _commandeMarkersNotifier =
      ValueNotifier<List<Marker>>(const <Marker>[]);
  final ValueNotifier<LatLng?> _routeArrivalNotifier = ValueNotifier<LatLng?>(
    null,
  );
  final ValueNotifier<double> _mapRotationNotifier = ValueNotifier<double>(0.0);
  LatLng? _lastCameraUpdateCenter;
  double? _lastCameraUpdateRotation;
  DateTime? _lastCameraUpdateAt;
  DateTime? _lastCenterUpdateAt;
  DateTime? _lastRotationUpdateAt;
  bool _cameraAnimationActive = false;
  List<LatLng>? _lastPolylineSnapshot;
  int _lastActiveCommandesSignature = 0;
  int _lastMesCommandesSignature = 0;
  int _lastMinTransporteursSignature = 0;
  int _lastTransporteursEnPanneSignature = 0;
  int _lastTransporteursSecoursSignature = 0;
  String? _lastSelectedCommandeId;
  LatLng? _lastArrivalPoint;
  List<LatLng>? _pendingPolylineSnapshot;
  bool _hasPendingPolylineSnapshot = false;
  String? _deferredRouteRefreshCommandeId;
  bool _deferredRouteRefreshForce = false;
  Timer? _polylineThrottleTimer;
  DateTime? _lastPolylineEmitAt;
  bool _homeControllerSyncScheduled = false;
  DateTime? _lastAcceptedGpsAt;
  double? _filteredCompassHeading;
  DateTime? _lastCompassUpdateAt;
  bool _compassCalibrationHintShown = false;
  mbx.PuckBearing? _lastNativePuckBearing;
  bool _nativeGestureFollowResetCheckInFlight = false;

  double _cameraRotationFromHeading(double heading) {
    final normalizedHeading = ((heading % 360) + 360) % 360;
    if (kIsWeb) {
      return (360 - normalizedHeading) % 360;
    }
    return normalizedHeading;
  }

  mbx.Point _toMapboxPoint(LatLng point) =>
      mbx.Point(coordinates: mbx.Position(point.longitude, point.latitude));

  LatLng _fromMapboxPoint(mbx.Point point) => LatLng(
    point.coordinates.lat.toDouble(),
    point.coordinates.lng.toDouble(),
  );

  int _colorToArgb(Color color) =>
      (((color.a * 255).round() & 0xff) << 24) |
      (((color.r * 255).round() & 0xff) << 16) |
      (((color.g * 255).round() & 0xff) << 8) |
      ((color.b * 255).round() & 0xff);

  bool get _useAdvancedNavigationCamera => _navigationModeActive;

  bool get _following => _manualFollowMode != _MapFollowMode.free;

  bool get _isManualHeadingFollowEnabled =>
      _manualFollowMode == _MapFollowMode.heading;

  bool get _isFollowRotationEnabled =>
      _isManualHeadingFollowEnabled || _useAdvancedNavigationCamera;

  double _resolvedCameraPitch() {
    if (_useAdvancedNavigationCamera) {
      return _navigationPitch;
    }
    if (_isManualHeadingFollowEnabled) {
      return _navigationPitch;
    }
    return 0;
  }

  mbx.MbxEdgeInsets _resolvedCameraPadding({double? distanceToTurnMeters}) {
    if (!_useAdvancedNavigationCamera) {
      return mbx.MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);
    }
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenSize = mediaQuery?.size;
    final safeArea = mediaQuery?.padding ?? EdgeInsets.zero;
    final double screenHeight = screenSize?.height ?? 800;
    final double screenWidth = screenSize?.width ?? 400;
    final bool nearTurn =
        distanceToTurnMeters != null &&
        distanceToTurnMeters <= _navigationTurnNearDistanceMeters;
    final bool approachingTurn =
        distanceToTurnMeters != null &&
        distanceToTurnMeters <= _navigationTurnApproachDistanceMeters;
    // Keep the puck above the bottom sheet and bring it closer to the middle
    // as the next turn approaches.
    final double top =
        safeArea.top +
        screenHeight * (nearTurn ? 0.28 : (approachingTurn ? 0.36 : 0.42));
    final double bottom =
        safeArea.bottom +
        screenHeight * (nearTurn ? 0.20 : (approachingTurn ? 0.16 : 0.14));
    final double horizontal = math.max(24, screenWidth * 0.06);
    return mbx.MbxEdgeInsets(
      top: top,
      left: horizontal,
      bottom: bottom,
      right: horizontal,
    );
  }

  void _cacheCameraPadding(mbx.MbxEdgeInsets padding) {
    _cameraPadding = mbx.MbxEdgeInsets(
      top: padding.top,
      left: padding.left,
      bottom: padding.bottom,
      right: padding.right,
    );
  }

  bool _cameraPaddingChanged(mbx.MbxEdgeInsets padding) {
    return (_cameraPadding.top - padding.top).abs() > 0.5 ||
        (_cameraPadding.left - padding.left).abs() > 0.5 ||
        (_cameraPadding.bottom - padding.bottom).abs() > 0.5 ||
        (_cameraPadding.right - padding.right).abs() > 0.5;
  }

  Duration _resolveCameraAnimationDuration({
    required LatLng center,
    required double zoom,
    required double rotation,
    required double pitch,
  }) {
    final double distanceMeters = _distance.as(
      LengthUnit.Meter,
      _cameraCenter,
      center,
    );
    final double zoomDelta = (_cameraZoom - zoom).abs();
    final double rotationDelta = _angleDelta(_cameraRotation, rotation);
    final double pitchDelta = (_cameraPitch - pitch).abs();
    final double score =
        distanceMeters +
        rotationDelta * 1.4 +
        zoomDelta * 40 +
        pitchDelta * 1.8;
    if (score < 15) {
      return const Duration(milliseconds: 160);
    }
    if (score < 40) {
      return const Duration(milliseconds: 220);
    }
    if (score < 90) {
      return const Duration(milliseconds: 280);
    }
    if (score < 180) {
      return const Duration(milliseconds: 340);
    }
    return const Duration(milliseconds: 420);
  }

  double _resolveNavigationPitchForContext({
    required double? speedKmh,
    double? distanceToTurnMeters,
  }) {
    if (!_useAdvancedNavigationCamera) {
      return 0;
    }
    final double resolvedSpeed =
        (speedKmh != null && speedKmh.isFinite)
            ? speedKmh
            : (_lastSpeedKmh ?? 0);
    if (distanceToTurnMeters != null &&
        distanceToTurnMeters <= _navigationTurnNearDistanceMeters) {
      return _navigationNearTurnPitch;
    }
    if (distanceToTurnMeters != null &&
        distanceToTurnMeters <= _navigationTurnApproachDistanceMeters) {
      return _navigationTurnPitch;
    }
    if (resolvedSpeed < 3) {
      return _navigationStoppedPitch;
    }
    if (resolvedSpeed < _slowSpeedThresholdKmh) {
      return _navigationSlowPitch;
    }
    if (resolvedSpeed < _fastSpeedThresholdKmh) {
      return _navigationMediumPitch;
    }
    return _navigationCruisePitch;
  }

  double _resolveNavigationZoomForContext({
    required double? speedKmh,
    double? distanceToTurnMeters,
  }) {
    if (distanceToTurnMeters != null &&
        distanceToTurnMeters <= _navigationTurnNearDistanceMeters) {
      return 17.9;
    }
    if (distanceToTurnMeters != null &&
        distanceToTurnMeters <= _navigationTurnApproachDistanceMeters) {
      return 17.5;
    }
    final double resolvedSpeed =
        (speedKmh != null && speedKmh.isFinite)
            ? speedKmh
            : (_lastSpeedKmh ?? 0);
    if (resolvedSpeed < _slowSpeedThresholdKmh) {
      return 17.2;
    }
    if (resolvedSpeed < _fastSpeedThresholdKmh) {
      return 16.9;
    }
    return 16.4;
  }

  double _resolveNavigationLookAheadDistance({
    required double? speedKmh,
    double? distanceToTurnMeters,
  }) {
    final double resolvedSpeed =
        (speedKmh != null && speedKmh.isFinite)
            ? speedKmh
            : (_lastSpeedKmh ?? 0);
    double lookAhead =
        _navigationLookAheadMinMeters +
        resolvedSpeed * _navigationLookAheadPerKmh;
    lookAhead = lookAhead.clamp(
      _navigationLookAheadMinMeters,
      _navigationLookAheadMaxMeters,
    );
    if (distanceToTurnMeters != null && distanceToTurnMeters.isFinite) {
      lookAhead = math.min(lookAhead, math.max(18, distanceToTurnMeters * 0.7));
    }
    return lookAhead;
  }

  double? _resolveNavigationHeading({
    double? localRouteBearing,
    double? predictiveRouteBearing,
    double? distanceToTurnMeters,
  }) {
    final deviceHeading = _headingDegrees;
    final routeBearing = localRouteBearing ?? predictiveRouteBearing;
    if (routeBearing == null) {
      return deviceHeading;
    }
    if (deviceHeading == null) {
      return routeBearing;
    }
    final double resolvedSpeed =
        (_lastSpeedKmh != null && _lastSpeedKmh!.isFinite) ? _lastSpeedKmh! : 0;
    if (resolvedSpeed <= _exactHeadingLowSpeedKmh) {
      return deviceHeading;
    }
    if (distanceToTurnMeters != null &&
        distanceToTurnMeters <= _navigationTurnNearDistanceMeters) {
      return localRouteBearing ?? routeBearing;
    }
    if (distanceToTurnMeters != null &&
        distanceToTurnMeters <= _navigationTurnApproachDistanceMeters) {
      final targetTurnBearing = localRouteBearing ?? routeBearing;
      if (_angleDelta(deviceHeading, targetTurnBearing) >= 30) {
        return targetTurnBearing;
      }
      return _lerpHeading(targetTurnBearing, deviceHeading, 0.2);
    }
    if (resolvedSpeed < _headingReliableSpeedKmh) {
      return localRouteBearing ?? routeBearing;
    }
    final baseRouteBearing =
        predictiveRouteBearing ?? localRouteBearing ?? routeBearing;
    if (_angleDelta(deviceHeading, baseRouteBearing) >= 35) {
      return baseRouteBearing;
    }
    final double deviceWeight =
        resolvedSpeed < _fastSpeedThresholdKmh ? 0.18 : 0.10;
    return _lerpHeading(baseRouteBearing, deviceHeading, deviceWeight);
  }

  Future<void> _syncNativeLocationComponent() async {
    if (kIsWeb) return;
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    final double resolvedSpeed =
        (_lastSpeedKmh != null && _lastSpeedKmh!.isFinite) ? _lastSpeedKmh! : 0;
    final bool shouldUseExactHeading =
        resolvedSpeed <= _exactHeadingLowSpeedKmh;
    final puckBearing =
        shouldUseExactHeading
            ? mbx.PuckBearing.HEADING
            : mbx.PuckBearing.COURSE;
    if (_lastNativePuckBearing == puckBearing) {
      return;
    }
    await mapboxMap.location.updateSettings(
      mbx.LocationComponentSettings(
        enabled: true,
        showAccuracyRing: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
        puckBearing: puckBearing,
      ),
    );
    _lastNativePuckBearing = puckBearing;
  }

  @override
  void initState() {
    super.initState();
    print('MapView initState called');
    _homeControllerListener = _handleHomeControllerChanged;
    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: _cameraAnimationDuration,
    );
    _userMarkerAnimationController = AnimationController(
      vsync: this,
      duration: _userMarkerAnimationDuration,
    );
    _webMapOptions = MapOptions(
      initialCenter: _defaultInitialCenter,
      initialZoom: 12,
      onPositionChanged: (camera, hasGesture) {
        if (!mounted) return;
        _cameraCenter = camera.center;
        _cameraZoom = camera.zoom;
        _cameraRotation = camera.rotation;
        _updateRotationNotifier(camera.rotation);
        if (hasGesture && _following) {
          _updateFollowing(false);
        }
      },
    );
    _commandeMarkersNotifier.addListener(_scheduleMapboxOverlaySync);
    _polylineNotifier.addListener(_scheduleMapboxOverlaySync);
    _routeArrivalNotifier.addListener(_scheduleMapboxOverlaySync);
    _initLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final HomeController controller = context.read<HomeController>();
    if (!identical(_homeController, controller)) {
      if (_homeControllerListener != null && _homeController != null) {
        _homeController!.removeListener(_homeControllerListener!);
      }
      _homeController = controller;
      if (_homeControllerListener != null) {
        _homeController!.addListener(_homeControllerListener!);
      }
      _syncHomeControllerState();
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _compassSub?.cancel();
    unawaited(_setNavigationWakeLock(false));
    _commandeMarkersNotifier.removeListener(_scheduleMapboxOverlaySync);
    _polylineNotifier.removeListener(_scheduleMapboxOverlaySync);
    _routeArrivalNotifier.removeListener(_scheduleMapboxOverlaySync);
    if (_userMarkerAnimationListener != null) {
      _userMarkerAnimationController.removeListener(
        _userMarkerAnimationListener!,
      );
    }
    if (_homeControllerListener != null && _homeController != null) {
      _homeController!.removeListener(_homeControllerListener!);
    }
    _userMarkerCoalesceTimer?.cancel();
    _polylineThrottleTimer?.cancel();
    _userMarkerAnimationController.dispose();
    _cameraAnimationController.dispose();
    _userLocationNotifier.dispose();
    _polylineNotifier.dispose();
    _commandeMarkersNotifier.dispose();
    _routeArrivalNotifier.dispose();
    _mapRotationNotifier.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    // 1) Services & permissions
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // L'utilisateur pourra activer ensuite depuis les rÃ©glages
      await Geolocator.openLocationSettings();
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      // Impossible d'obtenir la permission sans passer par les rÃ©glages
      return;
    }

    // 2) Position initiale
    try {
      final initial = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _updateFromPosition(initial, jumpToMap: true);
    } catch (_) {
      // Si on ne peut pas rÃ©cupÃ©rer la position initiale, on continue quand mÃªme
    }

    // 3) Suivi en continu
    _startCompassStream();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1, // mÃ¨tres (mettre 0 pour toutes les MAJ)
      ),
    ).listen((pos) => _updateFromPosition(pos));
    final auth = context.read<AuthController>();
    final zoneInit = auth.currentUser.value?.zone?.name; // ex: "GRAND_TUNIS"
    debugPrint('zoneInit: $zoneInit');

    if (zoneInit != null && zoneInit.isNotEmpty) {
      // Lance le compteur + premier fetch tout de suite
      await context.read<HomeController>().setZoneAndRefresh(
        zoneInit,
        silent: true,
      );
    }
  }

  void _startCompassStream() {
    _compassSub?.cancel();
    final stream = FlutterCompass.events;
    if (stream == null) {
      return;
    }
    _compassSub = stream.listen((event) {
      if (!mounted) return;
      final raw = event.heading;
      if (raw == null || raw.isNaN || raw.isInfinite) {
        return;
      }
      final normalized = _normalizeHeading(raw);
      if (normalized == null) {
        return;
      }
      _ingestCompassHeading(normalized);
      final accuracy = event.accuracy;
      if (!_compassCalibrationHintShown &&
          accuracy != null &&
          accuracy.isFinite &&
          accuracy > _compassLowConfidenceAccuracy) {
        _compassCalibrationHintShown = true;
        _showSnack(
          'Boussole peu precise. Fais un mouvement en 8 pour calibrer le cap.',
        );
      }
    });
  }

  void _ingestCompassHeading(double heading) {
    final previous = _filteredCompassHeading;
    if (previous == null) {
      _filteredCompassHeading = heading;
      _lastCompassUpdateAt = DateTime.now();
      _maybeApplyLiveCompassHeading(heading);
      return;
    }
    final delta = _angleDelta(previous, heading);
    if (delta < _compassDeadbandDegrees) {
      return;
    }
    final speedKmh = _lastSpeedKmh ?? 0;
    final bool suspiciousJump =
        delta >= _compassJumpRejectDegrees &&
        speedKmh < _headingReliableSpeedKmh;
    if (suspiciousJump) {
      return;
    }
    final smoothing =
        delta >= 25
            ? _compassFastCatchupSmoothingFactor
            : _compassStrongSmoothingFactor;
    _filteredCompassHeading = _lerpHeading(previous, heading, smoothing);
    _lastCompassUpdateAt = DateTime.now();
    _maybeApplyLiveCompassHeading(_filteredCompassHeading!);
  }

  double? _latestCompassHeading() {
    final heading = _filteredCompassHeading;
    if (heading == null) {
      return null;
    }
    final updatedAt = _lastCompassUpdateAt;
    if (updatedAt == null) {
      return null;
    }
    if (DateTime.now().difference(updatedAt) > _compassFreshness) {
      return null;
    }
    return heading;
  }

  void _maybeApplyLiveCompassHeading(double heading) {
    if (!mounted) return;
    final speedKmh = _lastSpeedKmh ?? 0;
    if (speedKmh >= _headingReliableSpeedKmh) {
      return;
    }

    final previousHeading = _headingDegrees;
    final double resolvedHeading;
    if (previousHeading == null) {
      resolvedHeading = heading;
    } else {
      final delta = _angleDelta(previousHeading, heading);
      if (delta < _compassDeadbandDegrees) {
        return;
      }
      resolvedHeading = _lerpHeading(
        previousHeading,
        heading,
        _compassFastCatchupSmoothingFactor,
      );
    }

    _headingDegrees = resolvedHeading;
    _notifyUserLocationVisual();

    final bool rotationEnabled = _isFollowRotationEnabled;
    if (!rotationEnabled) {
      return;
    }

    final navigationPlan =
        _useAdvancedNavigationCamera
            ? _buildNavigationCameraPlan(
              currentPos: _myPos ?? _cameraCenter,
              route: _cachedRoutePoints,
            )
            : null;
    final mapRotation =
        navigationPlan?.rotation ?? _cameraRotationFromHeading(resolvedHeading);
    if (!_shouldUpdateRotation(mapRotation)) {
      return;
    }

    unawaited(
      _applyCameraUpdate(
        center: navigationPlan?.center ?? _cameraCenter,
        zoom: navigationPlan?.zoom ?? _cameraZoom,
        rotation: mapRotation,
        pitch: navigationPlan?.pitch,
        padding: navigationPlan?.padding,
      ),
    );
  }

  void _handleNavigationModeChanged(bool enabled) {
    if (!mounted || _navigationModeActive == enabled) return;

    _navigationModeActive = enabled;
    unawaited(_syncNativeLocationComponent());
    unawaited(_setNavigationWakeLock(enabled));
    _updateFollowing(enabled, notify: false);
    _notifyUserLocationVisual();

    if (enabled) {
      Future.microtask(() async {
        if (!mounted || !_navigationModeActive) return;
        if (_myPos == null) {
          await centerOnMe(zoom: _navigationZoom);
        }
        if (!mounted || !_navigationModeActive) return;
        final target = _myPos;
        if (target != null) {
          final navigationPlan = _buildNavigationCameraPlan(
            currentPos: target,
            route: _cachedRoutePoints,
          );
          await _applyCameraUpdate(
            center: navigationPlan?.center ?? target,
            zoom:
                navigationPlan?.zoom ??
                (_cameraZoom < _navigationZoom ? _navigationZoom : _cameraZoom),
            rotation: navigationPlan?.rotation,
            pitch: navigationPlan?.pitch,
            padding: navigationPlan?.padding,
          );
        }
      });
    } else {
      _resetOffRouteTracking();
      Future.microtask(() async {
        if (!mounted) return;
        await _applyCameraUpdate(
          center: _myPos ?? _cameraCenter,
          zoom: _resolveFollowZoom(
            navigationActive: false,
            speedKmh: _lastSpeedKmh,
          ),
          rotation: null,
          pitch: 0,
          padding: mbx.MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        );
      });
    }
  }

  Future<void> _setNavigationWakeLock(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _screenChannel.invokeMethod('setKeepScreenOn', {
        'enabled': enabled,
      });
    } catch (_) {
      // Ignore if the current platform cannot apply wakelock.
    }
  }

  // en haut du State
  DateTime? _lastSentAt;
  DateTime? _lastRouteRefreshAt;
  static const Duration _routeRefreshInterval = Duration(seconds: 5);
  static const double _minorDeviationMeters = 20;
  static const double _maxDeviationMeters = 60;
  static const double _hardOffRouteMeters = 85;
  static const double _navigationDeviationFloorMeters = 5;
  static const double _navigationDeviationCeilingMeters = 10;
  static const Duration _offRoutePersistence = Duration(seconds: 2);
  static const int _offRouteSamplesBeforeRecalc = 2;
  final Distance _distance = const Distance();
  List<LatLng>? _cachedRoutePoints;
  DateTime? _offRouteSince;
  int _offRouteSampleCount = 0;

  void _updateFromPosition(Position p, {bool jumpToMap = false}) async {
    if (!mounted) return; // garde-fou 1

    final previousPos = _myPos;
    final latLng = LatLng(p.latitude, p.longitude);
    final normalizedGpsHeading = _normalizeHeading(p.heading);
    final filteredCompassHeading = _latestCompassHeading();
    final double currentSpeedKmh = _metersPerSecondToKmh(p.speed);

    final bool sampleAccepted = _shouldAcceptGpsSample(latLng, p.accuracy);
    _accuracyMeters = p.accuracy;
    if (!sampleAccepted) {
      return;
    }

    // garde-fou 2 avant de poursuivre
    if (!mounted) return;
    _myPos = latLng;
    _lastAcceptedGpsAt = DateTime.now();
    final double movedMeters =
        previousPos == null
            ? 0
            : _distance.as(LengthUnit.Meter, previousPos, latLng);
    _maybeUpdateHeading(
      previous: previousPos,
      current: latLng,
      moveMeters: movedMeters,
      gpsHeading: normalizedGpsHeading,
      compassHeading: filteredCompassHeading,
      speedKmh: currentSpeedKmh,
    );
    _animateUserMarkerTo(latLng);
    _lastSpeedKmh = currentSpeedKmh;
    unawaited(_syncNativeLocationComponent());

    // (optionnel) Throttle des appels rÃ©seau : 1 envoi toutes les 5s
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

    if (!mounted) return; // si entre-temps le widget a ?t? d?mont?
    final hasHeading = _headingDegrees != null;
    final navigationActive = _navigationModeActive;
    final rotationEnabled = _isFollowRotationEnabled;
    final navigationPlan =
        navigationActive
            ? _buildNavigationCameraPlan(
              currentPos: latLng,
              route: _cachedRoutePoints,
            )
            : null;
    if (_following) {
      final followZoom =
          navigationPlan?.zoom ??
          _resolveFollowZoom(
            navigationActive: navigationActive,
            speedKmh: _lastSpeedKmh,
          );
      final double? rotation =
          navigationPlan != null
              ? navigationPlan.rotation
              : (rotationEnabled && hasHeading
                  ? _cameraRotationFromHeading(_headingDegrees!)
                  : null);
      final LatLng recenterTarget = navigationPlan?.center ?? latLng;
      final bool shouldRecenter = _shouldRecenterFollowCamera(recenterTarget);
      final bool shouldRotate =
          rotation != null && _shouldUpdateRotation(rotation);
      final bool shouldRetuneNavigationCamera =
          navigationPlan != null &&
          ((_cameraZoom - navigationPlan.zoom).abs() > 0.12 ||
              (!kIsWeb &&
                  ((_cameraPitch - navigationPlan.pitch).abs() > 1 ||
                      _cameraPaddingChanged(navigationPlan.padding))));
      if (shouldRecenter || shouldRotate || shouldRetuneNavigationCamera) {
        final bool applyNavigationPlan =
            navigationPlan != null &&
            (shouldRecenter || shouldRetuneNavigationCamera);
        final targetCenter =
            applyNavigationPlan
                ? navigationPlan.center
                : (shouldRecenter ? latLng : _cameraCenter);
        final targetZoom =
            applyNavigationPlan
                ? navigationPlan.zoom
                : (shouldRecenter ? followZoom : _cameraZoom);
        unawaited(
          _applyCameraUpdate(
            center: targetCenter,
            zoom: targetZoom,
            rotation: shouldRotate ? rotation : null,
            pitch: navigationPlan?.pitch,
            padding: navigationPlan?.padding,
          ),
        );
      }
    } else if (jumpToMap) {
      unawaited(_applyCameraUpdate(center: latLng, zoom: 15, animated: false));
    }

    if (rotationEnabled && !_following) {
      _rotateMapToHeading(navigationPlan: navigationPlan);
    }

    _maybeRefreshActiveRoute();

    Map<String, String>? zoneEtSouszone = resolveZone(p.latitude, p.longitude);

    if (zoneEtSouszone != null) {
      final auth = context.read<AuthController>();

      // --- 1) MISE Ã€ JOUR DE LA ZONE SI ELLE CHANGE ---
      final currentZone =
          auth.currentUser.value?.zone?.name; // ex: "GRAND_TUNIS"
      final detectedZone = zoneEtSouszone['zone']; // ex: "GRAND_TUNIS"

      if (detectedZone != null &&
          detectedZone.toUpperCase() != (currentZone ?? '').toUpperCase()) {
        print(
          'ðŸŒ Nouvelle zone dÃ©tectÃ©e : $detectedZone (ancienne : $currentZone)',
        );
        try {
          final newZone = Zone.values.firstWhere(
            (z) => z.name.toUpperCase() == detectedZone.toUpperCase(),
          );

          final ok = await auth.updateZone(newZone);
          if (ok) {
            print('âœ… Zone mise Ã  jour vers $newZone');
          } else {
            print('âš ï¸ Ã‰chec updateZone');
          }
        } catch (e) {
          print('âŒ Zone inconnue : $detectedZone â€” $e');
        }
      }

      // --- 2) MISE Ã€ JOUR DE LA SOUS-ZONE SI ELLE CHANGE ---
      final currentSous = auth.currentUser.value?.sousZone?.name; // ex: "TUNIS"
      final detectedSous = zoneEtSouszone['sousZone']; // ex: "TUNIS"

      if (detectedSous != null &&
          detectedSous.toUpperCase() != (currentSous ?? '').toUpperCase()) {
        print(
          'ðŸ—ºï¸ Nouvelle sous-zone dÃ©tectÃ©e : $detectedSous (ancienne : $currentSous)',
        );
        try {
          final newSous = SousZone.values.firstWhere(
            (s) => s.name.toUpperCase() == detectedSous.toUpperCase(),
          );

          final ok2 = await auth.updateSousZone(newSous);
          if (ok2) {
            print('âœ… Sous-zone mise Ã  jour vers $newSous');
          } else {
            print('âš ï¸ Ã‰chec updateSousZone');
          }
        } catch (e) {
          print('âŒ Sous-zone inconnue : $detectedSous â€” $e');
        }
      }
    } else {
      print('âŒ Position hors zones dÃ©finies');
    }

    // if (zoneEtSouszone != null) {
    //   print("Zone : ${zoneEtSouszone['zone']}, Sous-zone : ${zoneEtSouszone['sousZone']}");
    // } else {
    //   print("Position hors zones dÃ©finies");
    // }
  }

  void _maybeRefreshActiveRoute() {
    if (!_navigationModeActive || _myPos == null) return;
    final homeCtrl = _homeController;
    if (homeCtrl == null) return;
    if (!homeCtrl.isNavigationMode) return;
    final selectedId = homeCtrl.selectedCommandeId;
    if (selectedId == null) return;

    final cached = _cachedRoutePoints;
    if (cached == null || cached.length < 2) {
      _triggerRouteRecalculation(selectedId);
      return;
    }

    final projection = _projectPositionOnRoute(_myPos!, cached);
    if (projection == null) return;

    final deviation = projection.distanceMeters;
    final accuracy = _accuracyMeters ?? 0;
    final strictNavigation = _navigationModeActive && homeCtrl.isNavigationMode;
    final onRouteTolerance = _resolveDeviationTolerance(
      accuracy,
      strictNavigation: strictNavigation,
    );

    final deviationDecision = _assessRouteDeviation(
      deviationMeters: deviation,
      toleranceMeters: onRouteTolerance,
    );
    if (deviationDecision.shouldRecalculate) {
      _triggerRouteRecalculation(selectedId, force: deviationDecision.force);
      return;
    }
    if (deviation > onRouteTolerance) {
      return;
    }

    _updateCachedRouteWithPosition(
      homeCtrl,
      commandeId: selectedId,
      currentPos: _myPos!,
      projection: projection,
    );
  }

  double _resolveDeviationTolerance(
    double accuracyMeters, {
    required bool strictNavigation,
  }) {
    final safeAccuracy =
        accuracyMeters.isFinite && accuracyMeters > 0
            ? accuracyMeters
            : (strictNavigation
                ? _navigationDeviationFloorMeters
                : _minorDeviationMeters);
    if (!strictNavigation) {
      return math.max(_minorDeviationMeters, safeAccuracy);
    }
    final limitedAccuracy = safeAccuracy.clamp(
      _navigationDeviationFloorMeters,
      _navigationDeviationCeilingMeters,
    );
    return limitedAccuracy.toDouble();
  }

  double _resolveFollowZoom({
    required bool navigationActive,
    required double? speedKmh,
  }) {
    if (navigationActive) {
      return _navigationZoom;
    }
    final double resolvedSpeed;
    if (speedKmh != null && speedKmh.isFinite) {
      resolvedSpeed = speedKmh;
    } else if (_lastSpeedKmh != null && _lastSpeedKmh!.isFinite) {
      resolvedSpeed = _lastSpeedKmh!;
    } else {
      resolvedSpeed = 0;
    }
    if (resolvedSpeed < _slowSpeedThresholdKmh) {
      return _slowSpeedZoom;
    }
    if (resolvedSpeed < _fastSpeedThresholdKmh) {
      return _mediumSpeedZoom;
    }
    return _fastSpeedZoom;
  }

  double _metersPerSecondToKmh(double? speedMps) {
    if (speedMps == null || !speedMps.isFinite) {
      return 0;
    }
    return speedMps * 3.6;
  }

  bool _shouldAcceptGpsSample(LatLng candidate, double? accuracyMeters) {
    final double? accuracy =
        (accuracyMeters != null && accuracyMeters.isFinite)
            ? accuracyMeters
            : null;
    final now = DateTime.now();
    if (accuracy != null && accuracy > _gpsAccuracyIgnoreAboveMeters) {
      if (_lastAcceptedGpsAt != null &&
          now.difference(_lastAcceptedGpsAt!) < const Duration(seconds: 5)) {
        return false;
      }
    }
    final previous = _myPos;
    if (previous != null) {
      final moved = _distance.as(LengthUnit.Meter, previous, candidate);
      if (moved < _minGpsDistanceMeters) {
        if (accuracy == null || accuracy > _gpsJitterAccuracyMeters) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _applyCameraUpdate({
    required LatLng center,
    double? zoom,
    double? rotation,
    double? pitch,
    mbx.MbxEdgeInsets? padding,
    bool animated = true,
    bool recordUpdate = true,
  }) async {
    if (kIsWeb) {
      if (!mounted) return;
      final resolvedZoom = zoom ?? _cameraZoom;
      final resolvedPitch = pitch ?? _resolvedCameraPitch();
      final animationDuration = _resolveCameraAnimationDuration(
        center: center,
        zoom: resolvedZoom,
        rotation: rotation ?? _cameraRotation,
        pitch: resolvedPitch,
      );
      double? desiredRotation = rotation;
      if (desiredRotation != null && !_shouldUpdateRotation(desiredRotation)) {
        desiredRotation = null;
      }
      final resolvedRotation = desiredRotation ?? _cameraRotation;

      if (!animated) {
        _webMapController.moveAndRotate(center, resolvedZoom, resolvedRotation);
        _cameraCenter = center;
        _cameraZoom = resolvedZoom;
        _cameraRotation = resolvedRotation;
        if (recordUpdate) {
          _registerCameraUpdate(center, resolvedRotation);
        }
        return;
      }

      _cameraAnimationActive = true;
      try {
        final startCenter = _cameraCenter;
        final startZoom = _cameraZoom;
        final startRotation = _cameraRotation;
        _cameraAnimationController.duration = animationDuration;
        final curved = CurvedAnimation(
          parent: _cameraAnimationController,
          curve: Curves.easeOutCubic,
        );
        final centerAnim = _LatLngTween(
          begin: startCenter,
          end: center,
        ).animate(curved);
        final zoomAnim = Tween<double>(
          begin: startZoom,
          end: resolvedZoom,
        ).animate(curved);

        void listener() {
          final currentCenter = centerAnim.value;
          final currentZoom = zoomAnim.value;
          final currentRotation = _lerpHeading(
            startRotation,
            resolvedRotation,
            curved.value,
          );
          _webMapController.moveAndRotate(
            currentCenter,
            currentZoom,
            currentRotation,
          );
        }

        _cameraAnimationController
          ..stop()
          ..reset()
          ..addListener(listener);

        try {
          await _cameraAnimationController.forward();
          _cameraCenter = center;
          _cameraZoom = resolvedZoom;
          _cameraRotation = resolvedRotation;
          if (recordUpdate) {
            _registerCameraUpdate(center, resolvedRotation);
          }
        } finally {
          _cameraAnimationController.removeListener(listener);
        }
      } finally {
        _cameraAnimationActive = false;
        _flushCameraAnimationDependents();
      }
      return;
    }

    final mapboxMap = _mapboxMap;
    if (!mounted || mapboxMap == null) return;
    final resolvedZoom = zoom ?? _cameraZoom;
    double? desiredRotation = rotation;
    if (desiredRotation != null && !_shouldUpdateRotation(desiredRotation)) {
      desiredRotation = null;
    }
    final resolvedRotation = desiredRotation ?? _cameraRotation;
    final resolvedPitch = pitch ?? _resolvedCameraPitch();
    final resolvedPadding = padding ?? _resolvedCameraPadding();
    if (!animated) {
      mapboxMap.setCamera(
        mbx.CameraOptions(
          center: _toMapboxPoint(center),
          padding: resolvedPadding,
          zoom: resolvedZoom,
          bearing: resolvedRotation,
          pitch: resolvedPitch,
        ),
      );
      _cameraCenter = center;
      _cameraZoom = resolvedZoom;
      _cameraRotation = resolvedRotation;
      _cameraPitch = resolvedPitch;
      _cacheCameraPadding(resolvedPadding);
      if (recordUpdate) {
        _registerCameraUpdate(center, resolvedRotation);
      }
      return;
    }

    await _animateCamera(
      center: center,
      zoom: resolvedZoom,
      rotation: resolvedRotation,
      pitch: resolvedPitch,
      padding: resolvedPadding,
      recordUpdate: recordUpdate,
    );
  }

  Future<void> _animateCamera({
    required LatLng center,
    required double zoom,
    required double rotation,
    required double pitch,
    required mbx.MbxEdgeInsets padding,
    bool recordUpdate = true,
  }) async {
    final mapboxMap = _mapboxMap;
    if (!mounted || mapboxMap == null) return;

    final centerUnchanged = _latLngAlmostEquals(_cameraCenter, center);
    final zoomUnchanged = (_cameraZoom - zoom).abs() < 0.001;
    final rotationUnchanged = (_cameraRotation - rotation).abs() < 0.1;
    final pitchUnchanged = (_cameraPitch - pitch).abs() < 0.1;
    final paddingUnchanged = !_cameraPaddingChanged(padding);

    if (centerUnchanged &&
        zoomUnchanged &&
        rotationUnchanged &&
        pitchUnchanged &&
        paddingUnchanged) {
      return;
    }

    _cameraAnimationActive = true;
    try {
      final animationDuration = _resolveCameraAnimationDuration(
        center: center,
        zoom: zoom,
        rotation: rotation,
        pitch: pitch,
      );
      await mapboxMap.cancelCameraAnimation();
      await mapboxMap.easeTo(
        mbx.CameraOptions(
          center: _toMapboxPoint(center),
          padding: padding,
          zoom: zoom,
          bearing: rotation,
          pitch: pitch,
        ),
        mbx.MapAnimationOptions(
          duration: animationDuration.inMilliseconds,
          startDelay: 0,
        ),
      );
      _cameraCenter = center;
      _cameraZoom = zoom;
      _cameraRotation = rotation;
      _cameraPitch = pitch;
      _cacheCameraPadding(padding);
    } finally {
      _cameraAnimationActive = false;
      if (recordUpdate) {
        _registerCameraUpdate(center, rotation);
      }
      _flushCameraAnimationDependents();
    }
  }

  void _handleHomeControllerChanged() {
    if (_homeControllerSyncScheduled || !mounted) {
      return;
    }
    _homeControllerSyncScheduled = true;
    scheduleMicrotask(() {
      if (!mounted) {
        _homeControllerSyncScheduled = false;
        return;
      }
      _homeControllerSyncScheduled = false;
      _syncHomeControllerState();
    });
  }

  void _syncHomeControllerState() {
    if (!mounted) return;
    final controller = _homeController;
    if (controller == null) return;

    final currentPolyline = controller.currentPolyline;
    final activeCommandes = controller.activeCommandes;
    final mesCommandes = controller.mesCommandes;
    final mesCommandesSecours = controller.mesCommandesSecours;
    final transporteursEnPanne = controller.transporteursEnPanne;
    final transporteursSecours = controller.transporteursSecours;
    final List<LatLng>? nextPolylineSnapshot =
        currentPolyline == null
            ? null
            : List<LatLng>.unmodifiable(currentPolyline);
    final List<LatLng>? baselineSnapshot =
        _hasPendingPolylineSnapshot
            ? _pendingPolylineSnapshot
            : _lastPolylineSnapshot;
    if (!_latLngListEquals(baselineSnapshot, nextPolylineSnapshot)) {
      _schedulePolylineSnapshot(nextPolylineSnapshot);
    }

    final activeSignature = _computeCommandesSignature(activeCommandes);
    final mesSignature = _computeCommandesSignature(mesCommandes);
    final minTransporteursSignature = controller.minTransporteursSignatureFor(
      activeCommandes,
    );
    final transporteursEnPanneSignature =
        controller.transporteursEnPanneSignature();
    final transporteursSecoursSignature =
        controller.transporteursSecoursSignature();
    final selectedId = controller.selectedCommandeId;
    final selectionChanged = selectedId != _lastSelectedCommandeId;
    if (selectionChanged ||
        activeSignature != _lastActiveCommandesSignature ||
        mesSignature != _lastMesCommandesSignature ||
        minTransporteursSignature != _lastMinTransporteursSignature ||
        transporteursEnPanneSignature != _lastTransporteursEnPanneSignature ||
        transporteursSecoursSignature != _lastTransporteursSecoursSignature) {
      final mesCommandesById = {for (final c in mesCommandes) c.id: c};
      final secoursCommandesById = {
        for (final entry in mesCommandesSecours) entry.commande.id: entry,
      };
      final markers = <Marker>[
        ..._buildCommandeMarkers(
          activeCommandes,
          selectedCommandeId: selectedId,
          mesCommandesById: mesCommandesById,
          secoursCommandesById: secoursCommandesById,
          minTransporteursById: controller.minTransporteursByCommandeId,
          isCurrentTransporteurIndisponible:
              controller.isCurrentTransporteurIndisponible,
          currentTransporteurId: controller.currentTransporteurId,
        ),
        if (controller.isCurrentTransporteurIndisponible)
          ..._buildTransporteursSecoursMarkers(transporteursSecours)
        else
          ..._buildTransporteursEnPanneMarkers(transporteursEnPanne),
      ];
      _commandeMarkersNotifier.value = List<Marker>.unmodifiable(markers);
      _lastActiveCommandesSignature = activeSignature;
      _lastMesCommandesSignature = mesSignature;
      _lastMinTransporteursSignature = minTransporteursSignature;
      _lastTransporteursEnPanneSignature = transporteursEnPanneSignature;
      _lastTransporteursSecoursSignature = transporteursSecoursSignature;
      _lastSelectedCommandeId = selectedId;
    }

    final bool navModeEnabled = controller.isNavigationMode;
    if (navModeEnabled != _navigationModeActive) {
      _handleNavigationModeChanged(navModeEnabled);
    }

    final Commande? selectedCommande = controller.selectedCommande;
    final selectedContactInfo = controller.selectedContactInfo;
    final bool preferCurrentPositionToArrivalWhenDepartScanned =
        selectedContactInfo?.preferCurrentPositionToArrivalWhenDepartScanned ==
        true;
    final LatLng? routeStartOverride =
        selectedContactInfo?.routeStartLatitude != null &&
                selectedContactInfo?.routeStartLongitude != null
            ? LatLng(
              selectedContactInfo!.routeStartLatitude!,
              selectedContactInfo.routeStartLongitude!,
            )
            : null;
    final LatLng? routeTargetOverride =
        selectedContactInfo?.routeTargetLatitude != null &&
                selectedContactInfo?.routeTargetLongitude != null
            ? LatLng(
              selectedContactInfo!.routeTargetLatitude!,
              selectedContactInfo.routeTargetLongitude!,
            )
            : null;
    final _RouteRequest? requestPreview =
        selectedCommande == null
            ? null
            : _deriveRouteRequest(
              selectedCommande,
              isMine: controller.isSelectedCommandeMine,
              currentPos: _myPos,
              preferCurrentPositionToArrivalWhenDepartScanned:
                  preferCurrentPositionToArrivalWhenDepartScanned,
              routeStartOverride: routeStartOverride,
              routeTargetOverride: routeTargetOverride,
            );
    _handleRoutePrefetchState(
      selectedCommande: selectedCommande,
      isPanelOpen: controller.isPanelOpen,
      currentPolyline: currentPolyline,
      requestPreview: requestPreview,
    );
  }

  List<Marker> _buildTransporteursEnPanneMarkers(
    List<TransporteurPanneCommandesResponse> transporteursEnPanne,
  ) {
    final markers = <Marker>[];
    for (final entry in transporteursEnPanne) {
      final lat = entry.transporteur.latitude;
      final lng = entry.transporteur.longitude;
      if (lat == null || lng == null) continue;
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 84,
          height: 84,
          child: _PanneMarker(
            isAccident:
                entry.transporteur.etatIncident == EtatIncident.ACCIDENT,
            onTap: () => _handleTransporteurPanneTap(entry),
          ),
        ),
      );
    }
    return markers;
  }

  List<Marker> _buildTransporteursSecoursMarkers(
    List<TransporteurSecoursCommandesResponse> transporteursSecours,
  ) {
    final markers = <Marker>[];
    for (final entry in transporteursSecours) {
      final lat = entry.transporteurSecours.latitude;
      final lng = entry.transporteurSecours.longitude;
      if (lat == null || lng == null) continue;
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 84,
          height: 84,
          child: _SecoursMarker(
            onTap: () => _handleTransporteurSecoursTap(entry),
          ),
        ),
      );
    }
    return markers;
  }

  void _schedulePolylineSnapshot(List<LatLng>? snapshot) {
    _pendingPolylineSnapshot = snapshot;
    _hasPendingPolylineSnapshot = true;
    _tryFlushPolylineSnapshot();
  }

  void _tryFlushPolylineSnapshot() {
    if (!mounted || _cameraAnimationActive) {
      return;
    }
    if (!_hasPendingPolylineSnapshot) {
      return;
    }
    if (_lastPolylineEmitAt != null) {
      final elapsed = DateTime.now().difference(_lastPolylineEmitAt!);
      if (elapsed < _polylineUpdateMinInterval) {
        final remaining = _polylineUpdateMinInterval - elapsed;
        _polylineThrottleTimer?.cancel();
        _polylineThrottleTimer = Timer(remaining, _tryFlushPolylineSnapshot);
        return;
      }
    }
    final pending = _pendingPolylineSnapshot;
    _pendingPolylineSnapshot = null;
    _hasPendingPolylineSnapshot = false;
    _polylineThrottleTimer?.cancel();
    _polylineThrottleTimer = null;
    _applyPolylineSnapshot(pending);
  }

  void _applyPolylineSnapshot(List<LatLng>? snapshot) {
    if (_latLngListEquals(_lastPolylineSnapshot, snapshot)) {
      return;
    }
    _lastPolylineSnapshot = snapshot;
    _lastPolylineEmitAt = DateTime.now();
    _polylineNotifier.value = snapshot;
    final LatLng? arrivalPoint =
        snapshot != null && snapshot.isNotEmpty ? snapshot.last : null;
    if (!_latLngNullableEquals(_lastArrivalPoint, arrivalPoint)) {
      _lastArrivalPoint = arrivalPoint;
      _routeArrivalNotifier.value = arrivalPoint;
    }
  }

  void _flushCameraAnimationDependents() {
    _tryFlushPolylineSnapshot();
    if (_deferredRouteRefreshCommandeId != null) {
      final commandeId = _deferredRouteRefreshCommandeId!;
      final bool force = _deferredRouteRefreshForce;
      _deferredRouteRefreshCommandeId = null;
      _deferredRouteRefreshForce = false;
      _triggerRouteRecalculation(commandeId, force: force);
    }
  }

  void _rotateMapToHeading({
    bool force = false,
    double? fallbackHeading,
    _NavigationCameraPlan? navigationPlan,
  }) {
    if (!force && !_isFollowRotationEnabled) return;
    final heading = fallbackHeading ?? _headingDegrees;
    final mapRotation =
        navigationPlan?.rotation ??
        (heading != null ? _cameraRotationFromHeading(heading) : null);
    if (mapRotation == null) return;
    final center = navigationPlan?.center ?? _cameraCenter;
    final zoom = navigationPlan?.zoom ?? _cameraZoom;
    unawaited(
      _applyCameraUpdate(
        center: center,
        zoom: zoom,
        rotation: mapRotation,
        pitch: navigationPlan?.pitch,
        padding: navigationPlan?.padding,
      ),
    );
  }

  void _animateUserMarkerTo(LatLng target) {
    if (!mounted) return;
    _pendingUserMarkerTarget = target;
    final bool shouldStartImmediately =
        _smoothedMyPos == null && !_userMarkerAnimationController.isAnimating;
    if (_userMarkerAnimationController.isAnimating) {
      _pendingUserMarkerFlushAfterAnimation = true;
    }
    _userMarkerCoalesceTimer?.cancel();
    _userMarkerCoalesceTimer = Timer(
      _userMarkerCoalesceDuration,
      _consumePendingUserMarkerTarget,
    );
    if (shouldStartImmediately) {
      _userMarkerCoalesceTimer?.cancel();
      _userMarkerCoalesceTimer = null;
      _consumePendingUserMarkerTarget();
    }
  }

  void _consumePendingUserMarkerTarget() {
    if (!mounted) return;
    _userMarkerCoalesceTimer?.cancel();
    _userMarkerCoalesceTimer = null;
    if (_userMarkerAnimationController.isAnimating) {
      _pendingUserMarkerFlushAfterAnimation = true;
      return;
    }
    final target = _pendingUserMarkerTarget;
    _pendingUserMarkerTarget = null;
    if (target != null) {
      _startUserMarkerAnimation(target);
    }
  }

  void _startUserMarkerAnimation(LatLng target) {
    if (!mounted) return;
    _pendingUserMarkerFlushAfterAnimation = false;
    final current = _displayedMyPos ?? _myPos ?? target;
    if (_latLngAlmostEquals(current, target)) {
      final alreadySet =
          _smoothedMyPos != null &&
          _latLngAlmostEquals(_smoothedMyPos!, target);
      if (!alreadySet) {
        _smoothedMyPos = target;
      }
      _notifyUserLocationVisual();
      return;
    }

    if (_userMarkerAnimationListener != null) {
      _userMarkerAnimationController.removeListener(
        _userMarkerAnimationListener!,
      );
      _userMarkerAnimationListener = null;
    }
    _userMarkerAnimation = null;

    final curved = CurvedAnimation(
      parent: _userMarkerAnimationController,
      curve: Curves.easeOutCubic,
    );
    _userMarkerAnimation = _LatLngTween(
      begin: current,
      end: target,
    ).animate(curved);

    final listener = () {
      if (!mounted || _userMarkerAnimation == null) return;
      _smoothedMyPos = _userMarkerAnimation!.value;
      _notifyUserLocationVisual();
    };

    _userMarkerAnimationListener = listener;

    _userMarkerAnimationController
      ..reset()
      ..addListener(listener);

    _userMarkerAnimationController.forward().whenComplete(() {
      if (_userMarkerAnimationListener == listener) {
        _userMarkerAnimationController.removeListener(listener);
        _userMarkerAnimationListener = null;
        _userMarkerAnimation = null;
        if (mounted) {
          _smoothedMyPos = target;
          _notifyUserLocationVisual();
        }
        if (_pendingUserMarkerFlushAfterAnimation) {
          _pendingUserMarkerFlushAfterAnimation = false;
          _consumePendingUserMarkerTarget();
        }
      }
    });
  }

  void _triggerRouteRecalculation(String commandeId, {bool force = false}) {
    if (_cameraAnimationActive) {
      final bool sameDeferred = _deferredRouteRefreshCommandeId == commandeId;
      _deferredRouteRefreshCommandeId = commandeId;
      _deferredRouteRefreshForce =
          force || (sameDeferred && _deferredRouteRefreshForce);
      return;
    }
    _executeRouteRecalculation(commandeId, force: force);
  }

  void _executeRouteRecalculation(String commandeId, {bool force = false}) {
    if (_pendingRouteCommandeId != null) return;
    final now = DateTime.now();
    if (!force &&
        _lastRouteRefreshAt != null &&
        now.difference(_lastRouteRefreshAt!) < _routeRefreshInterval) {
      return;
    }
    _lastRouteRefreshAt = now;
    unawaited(_fetchRouteForSelection(commandeId, adjustCamera: false));
  }

  void _updateCachedRouteWithPosition(
    HomeController homeCtrl, {
    required String commandeId,
    required LatLng currentPos,
    _RouteProjection? projection,
  }) {
    final route = _cachedRoutePoints;
    if (route == null || route.length < 2) return;

    final match = projection ?? _projectPositionOnRoute(currentPos, route);
    if (match == null) return;

    final deviation = match.distanceMeters;
    final accuracy = _accuracyMeters ?? 0;

    if (deviation > _hardOffRouteMeters) {
      _triggerRouteRecalculation(commandeId, force: true);
      return;
    }

    final strictNavigation = _navigationModeActive && homeCtrl.isNavigationMode;
    final minorThreshold = _resolveDeviationTolerance(
      accuracy,
      strictNavigation: strictNavigation,
    );
    final deviationDecision = _assessRouteDeviation(
      deviationMeters: deviation,
      toleranceMeters: minorThreshold,
    );
    if (deviationDecision.shouldRecalculate) {
      _triggerRouteRecalculation(commandeId, force: deviationDecision.force);
      return;
    }
    if (deviation > minorThreshold) {
      return;
    }

    final updatedPolyline = _buildProgressedPolyline(
      currentPos: currentPos,
      route: route,
      projection: match,
    );
    final targetEnd = homeCtrl.selectedEnd ?? route.last;
    final endOrigin =
        homeCtrl.selectedEndOrigin ?? RoutePointOrigin.destination;

    homeCtrl.setRouteData(
      start: currentPos,
      end: targetEnd,
      startOrigin: RoutePointOrigin.courier,
      endOrigin: endOrigin,
      polyline: updatedPolyline,
    );
    _cachedRoutePoints = List<LatLng>.from(updatedPolyline);
  }

  List<LatLng> _buildProgressedPolyline({
    required LatLng currentPos,
    required List<LatLng> route,
    required _RouteProjection projection,
  }) {
    final updated = <LatLng>[currentPos];
    final projectedPoint = projection.projectedPoint;
    if (!_latLngAlmostEquals(currentPos, projectedPoint)) {
      updated.add(projectedPoint);
    }
    final nextIndex = projection.segmentIndex + 1;
    if (nextIndex < route.length) {
      updated.addAll(route.sublist(nextIndex));
    }
    return updated;
  }

  void _resetOffRouteTracking() {
    _offRouteSince = null;
    _offRouteSampleCount = 0;
  }

  _RouteDeviationDecision _assessRouteDeviation({
    required double deviationMeters,
    required double toleranceMeters,
  }) {
    if (deviationMeters <= toleranceMeters) {
      _resetOffRouteTracking();
      return const _RouteDeviationDecision.none();
    }
    final now = DateTime.now();
    _offRouteSince ??= now;
    _offRouteSampleCount += 1;

    if (deviationMeters >= _hardOffRouteMeters) {
      return const _RouteDeviationDecision.recalculate(force: true);
    }

    final bool persistent =
        _offRouteSampleCount >= _offRouteSamplesBeforeRecalc ||
        now.difference(_offRouteSince!) >= _offRoutePersistence;
    if (!persistent) {
      return const _RouteDeviationDecision.none();
    }
    return _RouteDeviationDecision.recalculate(
      force: deviationMeters >= _maxDeviationMeters,
    );
  }

  _NavigationCameraPlan? _buildNavigationCameraPlan({
    required LatLng currentPos,
    required List<LatLng>? route,
    _RouteProjection? projection,
  }) {
    if (!_useAdvancedNavigationCamera || route == null || route.length < 2) {
      return null;
    }
    final effectiveProjection =
        projection ?? _projectPositionOnRoute(currentPos, route);
    if (effectiveProjection == null) {
      return null;
    }
    final upcomingTurn = _findUpcomingTurn(route, effectiveProjection);
    final double? distanceToTurnMeters = upcomingTurn?.distanceMeters;
    final double? onRouteBearing = _resolveRouteHeadingAtProjection(
      route,
      effectiveProjection,
    );
    final double predictiveLookAheadMeters =
        _resolveNavigationLookAheadDistance(
          speedKmh: _lastSpeedKmh,
          distanceToTurnMeters: distanceToTurnMeters,
        );
    final LatLng localBearingPoint = _pointAlongRouteFromProjection(
      route,
      effectiveProjection,
      _navigationLocalBearingAheadMeters,
    );
    final LatLng predictivePoint = _pointAlongRouteFromProjection(
      route,
      effectiveProjection,
      predictiveLookAheadMeters,
    );
    final double? localRouteBearing =
        _bearingBetween(
          effectiveProjection.projectedPoint,
          localBearingPoint,
        ) ??
        onRouteBearing;
    final double? predictiveRouteBearing =
        _bearingBetween(effectiveProjection.projectedPoint, predictivePoint) ??
        onRouteBearing;
    final double? resolvedHeading = _resolveNavigationHeading(
      localRouteBearing: localRouteBearing,
      predictiveRouteBearing: predictiveRouteBearing,
      distanceToTurnMeters: distanceToTurnMeters,
    );
    final double rotation =
        resolvedHeading != null
            ? _cameraRotationFromHeading(resolvedHeading)
            : _cameraRotation;
    final double snapBlend =
        effectiveProjection.distanceMeters <= _navigationRouteSnapMaxMeters
            ? _navigationRouteSnapBlend
            : 0.0;
    final LatLng focusPosition =
        snapBlend > 0
            ? _interpolateLatLng(
              currentPos,
              effectiveProjection.projectedPoint,
              snapBlend,
            )
            : currentPos;
    final double zoom = _resolveNavigationZoomForContext(
      speedKmh: _lastSpeedKmh,
      distanceToTurnMeters: distanceToTurnMeters,
    );
    final double pitch = _resolveNavigationPitchForContext(
      speedKmh: _lastSpeedKmh,
      distanceToTurnMeters: distanceToTurnMeters,
    );
    final mbx.MbxEdgeInsets padding = _resolvedCameraPadding(
      distanceToTurnMeters: distanceToTurnMeters,
    );
    return _NavigationCameraPlan(
      center: focusPosition,
      zoom: zoom,
      rotation: rotation,
      pitch: pitch,
      padding: padding,
      distanceToTurnMeters: distanceToTurnMeters,
      focusPosition: focusPosition,
      localRouteBearing: localRouteBearing,
      predictiveRouteBearing: predictiveRouteBearing,
    );
  }

  _TurnAheadInfo? _findUpcomingTurn(
    List<LatLng> route,
    _RouteProjection projection,
  ) {
    if (route.length < 3) {
      return null;
    }
    final int currentSegmentIndex = projection.segmentIndex;
    if (currentSegmentIndex >= route.length - 1) {
      return null;
    }

    double cumulativeDistance = _distance.as(
      LengthUnit.Meter,
      projection.projectedPoint,
      route[currentSegmentIndex + 1],
    );
    final initialBearing = _bearingBetween(
      projection.projectedPoint,
      route[currentSegmentIndex + 1],
    );
    if (initialBearing == null) {
      return null;
    }
    double previousBearing = initialBearing;

    for (int i = currentSegmentIndex + 1; i < route.length - 1; i++) {
      final LatLng start = route[i];
      final LatLng end = route[i + 1];
      final double? nextBearing = _bearingBetween(start, end);
      if (nextBearing == null) {
        cumulativeDistance += _distance.as(LengthUnit.Meter, start, end);
        continue;
      }
      final double delta = _angleDelta(previousBearing, nextBearing);
      if (delta >= _navigationTurnDetectionAngleDegrees) {
        return _TurnAheadInfo(
          distanceMeters: cumulativeDistance,
          angleDeltaDegrees: delta,
        );
      }
      cumulativeDistance += _distance.as(LengthUnit.Meter, start, end);
      if (cumulativeDistance > _navigationLookAheadMaxMeters * 2.5) {
        break;
      }
      previousBearing = nextBearing;
    }
    return null;
  }

  double? _resolveRouteHeadingAtProjection(
    List<LatLng> route,
    _RouteProjection projection,
  ) {
    final int index = projection.segmentIndex;
    if (index < route.length - 1) {
      final forwardBearing = _bearingBetween(
        projection.projectedPoint,
        route[index + 1],
      );
      if (forwardBearing != null) {
        return forwardBearing;
      }
    }
    if (index > 0) {
      return _bearingBetween(route[index - 1], projection.projectedPoint);
    }
    return null;
  }

  LatLng _pointAlongRouteFromProjection(
    List<LatLng> route,
    _RouteProjection projection,
    double distanceAheadMeters,
  ) {
    if (route.length < 2) {
      return projection.projectedPoint;
    }
    double remaining = math.max(0, distanceAheadMeters);
    LatLng segmentStart = projection.projectedPoint;
    for (int i = projection.segmentIndex; i < route.length - 1; i++) {
      final LatLng segmentEnd = route[i + 1];
      final double segmentDistance = _distance.as(
        LengthUnit.Meter,
        segmentStart,
        segmentEnd,
      );
      if (remaining <= segmentDistance) {
        if (segmentDistance <= 0) {
          return segmentEnd;
        }
        return _interpolateLatLng(
          segmentStart,
          segmentEnd,
          remaining / segmentDistance,
        );
      }
      remaining -= segmentDistance;
      segmentStart = segmentEnd;
    }
    return route.last;
  }

  LatLng _interpolateLatLng(LatLng from, LatLng to, double t) {
    final double clamped = t.clamp(0.0, 1.0).toDouble();
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * clamped,
      from.longitude + (to.longitude - from.longitude) * clamped,
    );
  }

  _RouteProjection? _projectPositionOnRoute(
    LatLng position,
    List<LatLng> route,
  ) {
    if (route.length < 2) return null;
    _RouteProjection? bestMatch;
    double bestDistance = double.infinity;
    double traversedDistance = 0;

    for (var i = 0; i < route.length - 1; i++) {
      final start = route[i];
      final end = route[i + 1];
      final segmentDistance = _distance.as(LengthUnit.Meter, start, end);
      final projected = _projectPointOnSegment(start, end, position);
      final distanceMeters = _distance.as(
        LengthUnit.Meter,
        position,
        projected.projectedPoint,
      );
      if (distanceMeters < bestDistance) {
        bestDistance = distanceMeters;
        bestMatch = _RouteProjection(
          projectedPoint: projected.projectedPoint,
          segmentIndex: i,
          segmentFraction: projected.fraction,
          distanceAlongRouteMeters:
              traversedDistance + segmentDistance * projected.fraction,
          distanceMeters: distanceMeters,
        );
      }
      traversedDistance += segmentDistance;
    }
    return bestMatch;
  }

  _SegmentProjection _projectPointOnSegment(
    LatLng start,
    LatLng end,
    LatLng point,
  ) {
    final ax = start.longitude;
    final ay = start.latitude;
    final bx = end.longitude;
    final by = end.latitude;
    final px = point.longitude;
    final py = point.latitude;

    final dx = bx - ax;
    final dy = by - ay;
    final segLen2 = dx * dx + dy * dy;
    double t = segLen2 == 0 ? 0 : ((px - ax) * dx + (py - ay) * dy) / segLen2;
    t = t.clamp(0.0, 1.0);

    return _SegmentProjection(
      projectedPoint: LatLng(ay + dy * t, ax + dx * t),
      fraction: t.toDouble(),
    );
  }

  bool _latLngAlmostEquals(LatLng a, LatLng b) {
    return _distance.as(LengthUnit.Meter, a, b) < 0.5;
  }

  bool _latLngListEquals(List<LatLng>? a, List<LatLng>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == null && b == null;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_latLngAlmostEquals(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  bool _latLngNullableEquals(LatLng? a, LatLng? b) {
    if (a == null || b == null) {
      return a == null && b == null;
    }
    return _latLngAlmostEquals(a, b);
  }

  int _computeCommandesSignature(List<Commande> commandes) {
    if (commandes.isEmpty) return 0;
    final mapped = commandes.map(
      (c) => Object.hash(
        c.id,
        c.latitudeDepart,
        c.longitudeDepart,
        c.latitudeDestination,
        c.longitudeDestination,
        c.qrCodeDepartScanne,
        c.qrCodeReceptionScanne,
      ),
    );
    return Object.hashAll(mapped);
  }

  double _angleDelta(double a, double b) {
    final delta = (a - b).abs() % 360;
    return delta > 180 ? 360 - delta : delta;
  }

  bool _shouldRecenterFollowCamera(LatLng target) {
    if (!_enableFollowCameraThrottle) {
      return true;
    }
    final double distanceThreshold =
        _useAdvancedNavigationCamera
            ? _navigationFollowCameraDistanceThresholdMeters
            : _followCameraDistanceThresholdMeters;
    final Duration minInterval =
        _useAdvancedNavigationCamera
            ? _navigationFollowCameraMinInterval
            : _followCameraMinInterval;
    final lastCenter = _lastCameraUpdateCenter;
    if (lastCenter == null) {
      return true;
    }
    final movedMeters = _distance.as(LengthUnit.Meter, target, lastCenter);
    if (movedMeters < distanceThreshold) {
      return false;
    }
    final lastCenterUpdateAt = _lastCenterUpdateAt ?? _lastCameraUpdateAt;
    if (lastCenterUpdateAt == null) {
      return true;
    }
    final elapsed = DateTime.now().difference(lastCenterUpdateAt);
    return elapsed >= minInterval;
  }

  bool _shouldUpdateRotation(double desiredRotation) {
    final double headingThreshold =
        _useAdvancedNavigationCamera
            ? _navigationFollowCameraHeadingThresholdDegrees
            : _followCameraHeadingThresholdDegrees;
    final Duration minInterval =
        _useAdvancedNavigationCamera
            ? _navigationCameraRotationMinInterval
            : _cameraRotationMinInterval;
    final lastRotationAt = _lastRotationUpdateAt;
    if (lastRotationAt == null) {
      return true;
    }
    final baselineRotation = _lastCameraUpdateRotation ?? _cameraRotation;
    final delta = _angleDelta(desiredRotation, baselineRotation);
    if (delta >= headingThreshold) {
      return true;
    }
    final elapsed = DateTime.now().difference(lastRotationAt);
    return elapsed >= minInterval;
  }

  void _registerCameraUpdate(LatLng center, double rotation) {
    final previousCenter = _lastCameraUpdateCenter;
    _lastCameraUpdateCenter = center;
    _lastCameraUpdateRotation = rotation;
    final now = DateTime.now();
    _lastCameraUpdateAt = now;
    _lastRotationUpdateAt = now;
    final centerChanged =
        previousCenter == null || !_latLngAlmostEquals(previousCenter, center);
    if (centerChanged) {
      _lastCenterUpdateAt = now;
    }
    _updateRotationNotifier(rotation);
  }

  void _updateRotationNotifier(double rotation) {
    if (!rotation.isFinite) return;
    double normalized = rotation % 360;
    if (normalized < 0) normalized += 360;
    if ((_mapRotationNotifier.value - normalized).abs() < 0.1) {
      return;
    }
    _mapRotationNotifier.value = normalized;
  }

  bool _updateFollowing(bool value, {bool notify = true}) {
    final nextMode =
        value
            ? (_manualFollowMode == _MapFollowMode.heading
                ? _MapFollowMode.heading
                : _MapFollowMode.centered)
            : _MapFollowMode.free;
    return _setManualFollowMode(nextMode, notify: notify);
  }

  bool _setManualFollowMode(_MapFollowMode mode, {bool notify = true}) {
    if (_manualFollowMode == mode) {
      return false;
    }
    _manualFollowMode = mode;
    unawaited(_syncNativeLocationComponent());
    if (notify) {
      _notifyUserLocationVisual();
    }
    return true;
  }

  Future<void> handleCenterButtonTap({double zoom = 16}) async {
    final nextMode =
        !_following
            ? _MapFollowMode.centered
            : (_manualFollowMode == _MapFollowMode.centered
                ? _MapFollowMode.heading
                : _manualFollowMode);
    await centerOnMe(
      zoom: zoom,
      enableHeadingFollow: nextMode == _MapFollowMode.heading,
    );
  }

  void _notifyUserLocationVisual() {
    final currentPos = _smoothedMyPos ?? _myPos;
    if (currentPos == null) {
      if (_userLocationNotifier.value != null) {
        _userLocationNotifier.value = null;
      }
      return;
    }
    final nextVisual = _UserLocationVisual(
      position: currentPos,
      accuracyMeters: _accuracyMeters,
      headingDegrees: _headingDegrees,
      isFollowing: _following,
    );
    if (!_enableUserNotifierDebounce) {
      _userLocationNotifier.value = nextVisual;
      return;
    }
    final previous = _userLocationNotifier.value;
    final bool positionChanged =
        previous == null
            ? true
            : _distance.as(
                  LengthUnit.Meter,
                  previous.position,
                  nextVisual.position,
                ) >=
                _userNotifierDistanceThresholdMeters;
    final bool headingChanged = () {
      if (previous == null) return true;
      final prevHeading = previous.headingDegrees;
      final currentHeading = nextVisual.headingDegrees;
      if (prevHeading == null && currentHeading == null) {
        return false;
      }
      if (prevHeading == null || currentHeading == null) {
        return true;
      }
      return _angleDelta(prevHeading, currentHeading) >=
          _userNotifierHeadingThresholdDegrees;
    }();
    final bool accuracyChanged = () {
      if (previous == null) return true;
      final prevAcc = previous.accuracyMeters;
      final currentAcc = nextVisual.accuracyMeters;
      if (prevAcc == null && currentAcc == null) return false;
      if (prevAcc == null || currentAcc == null) return true;
      return (prevAcc - currentAcc).abs() >= 0.5;
    }();
    final bool followChanged =
        previous == null
            ? true
            : previous.isFollowing != nextVisual.isFollowing;
    if (!positionChanged &&
        !headingChanged &&
        !accuracyChanged &&
        !followChanged) {
      return;
    }
    _userLocationNotifier.value = nextVisual;
  }

  /// MÃ©thode publique appelÃ©e depuis HomeCoursierPage via GlobalKey
  Future<void> centerOnMe({double zoom = 16, bool? enableHeadingFollow}) async {
    LatLng? target = _myPos;
    double? accuracy = _accuracyMeters;
    double? headingUpdate;

    if (target == null) {
      try {
        final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        target = LatLng(p.latitude, p.longitude);
        accuracy = p.accuracy;
        headingUpdate = _normalizeHeading(p.heading);
      } catch (_) {
        return;
      }
    }

    if (!mounted) return;

    _myPos = target;
    _accuracyMeters = accuracy;
    if (headingUpdate != null) {
      _setHeadingDirect(headingUpdate);
    }
    final resolvedFollowMode =
        enableHeadingFollow == null
            ? (_following ? _manualFollowMode : _MapFollowMode.centered)
            : (enableHeadingFollow
                ? _MapFollowMode.heading
                : _MapFollowMode.centered);
    _setManualFollowMode(resolvedFollowMode, notify: false);
    _notifyUserLocationVisual();
    _animateUserMarkerTo(target);

    final heading = _headingDegrees;
    final manualHeadingFollow =
        resolvedFollowMode == _MapFollowMode.heading && !_navigationModeActive;
    final rotateNow =
        heading != null &&
        (_useAdvancedNavigationCamera || manualHeadingFollow);
    final navigationPlan =
        _useAdvancedNavigationCamera
            ? _buildNavigationCameraPlan(
              currentPos: target,
              route: _cachedRoutePoints,
            )
            : null;
    final desiredPitch =
        navigationPlan?.pitch ??
        (manualHeadingFollow ? _resolvedCameraPitch() : 0.0);
    final distanceToTarget = _distance.as(
      LengthUnit.Meter,
      _cameraCenter,
      navigationPlan?.center ?? target,
    );
    final desiredRotation =
        navigationPlan?.rotation ??
        (rotateNow ? _cameraRotationFromHeading(heading) : _cameraRotation);
    final shouldAnimate =
        distanceToTarget > _manualCenterSnapDistanceMeters ||
        (_cameraZoom - (navigationPlan?.zoom ?? zoom)).abs() >
            _manualCenterZoomDeltaThreshold ||
        (_cameraPitch - desiredPitch).abs() > 3 ||
        _angleDelta(_cameraRotation, desiredRotation) >
            _manualCenterRotationThresholdDegrees;
    await _applyCameraUpdate(
      center: navigationPlan?.center ?? target,
      zoom: navigationPlan?.zoom ?? zoom,
      rotation: rotateNow ? desiredRotation : null,
      pitch: desiredPitch,
      padding: navigationPlan?.padding,
      animated: shouldAnimate,
    );
  }

  Future<void> stopNavigation() async {
    if (!mounted) return;
    context.read<HomeController>().setNavigationMode(false);
    unawaited(_setNavigationWakeLock(false));
    _updateFollowing(false, notify: false);
    _notifyUserLocationVisual();
    _cachedRoutePoints = null;
    _resetOffRouteTracking();
  }

  /// Active/dÃ©sactive le suivi camÃ©ra -> utilisateur (optionnel)
  void enableFollow(bool value) {
    _updateFollowing(value, notify: false);
    _notifyUserLocationVisual();
    if (value && _myPos != null) {
      final navigationPlan =
          _useAdvancedNavigationCamera
              ? _buildNavigationCameraPlan(
                currentPos: _myPos!,
                route: _cachedRoutePoints,
              )
              : null;
      final bool rotate = _headingDegrees != null && _isFollowRotationEnabled;
      final rotation =
          navigationPlan?.rotation ??
          (rotate ? _cameraRotationFromHeading(_headingDegrees!) : null);
      unawaited(
        _applyCameraUpdate(
          center: navigationPlan?.center ?? _myPos!,
          zoom: navigationPlan?.zoom ?? _cameraZoom,
          rotation: rotation,
          pitch: navigationPlan?.pitch,
          padding: navigationPlan?.padding,
        ),
      );
    }
  }

  List<Marker> _buildCommandeMarkers(
    List<Commande> commandes, {
    String? selectedCommandeId,
    required Map<String, Commande> mesCommandesById,
    required Map<String, CommandeTransporteurPrincipalResponse>
    secoursCommandesById,
    required Map<String, bool> minTransporteursById,
    required bool isCurrentTransporteurIndisponible,
    required String? currentTransporteurId,
  }) {
    Iterable<Commande> visibles = commandes;
    if (selectedCommandeId != null) {
      final selectedOnly =
          commandes.where((c) => c.id == selectedCommandeId).toList();
      if (selectedOnly.isNotEmpty) {
        visibles = selectedOnly;
      }
    }

    const Color attentionColor = Color(0xFFF4C20D);
    bool isAttentionStatut(String? raw) {
      final s = raw?.trim().toLowerCase();
      return s == 'en_appelle' ||
          s == 'appelle_client_1' ||
          s == 'appelle_client_2' ||
          s == 'non_repondre_client_1' ||
          s == 'non_repondre_client_2';
    }

    final markers = <Marker>[];
    for (final commande in visibles) {
      final mine = mesCommandesById[commande.id];
      final secoursEntry = secoursCommandesById[commande.id];
      final Commande source = mine ?? secoursEntry?.commande ?? commande;
      final bool treatAsMine =
          mine != null ||
          secoursEntry != null ||
          (isCurrentTransporteurIndisponible &&
              currentTransporteurId != null &&
              source.transporteurId == currentTransporteurId);
      if (treatAsMine && source.qrCodeReceptionScanne == true) {
        continue; // commande dÃ©jÃ  finalisÃ©e â†’ pas de point
      }

      LatLng? point;
      bool? isArrivalPoint;
      String? markerLabel;
      if (treatAsMine) {
        final bool departScanne = source.qrCodeDepartScanne == true;
        final bool relaisEffectue = source.relaisTransporteurEffectue == true;
        final double? departLat =
            commande.latitudeDepart ?? source.latitudeDepart;
        final double? departLng =
            commande.longitudeDepart ?? source.longitudeDepart;
        final double? destLat =
            commande.latitudeDestination ?? source.latitudeDestination;
        final double? destLng =
            commande.longitudeDestination ?? source.longitudeDestination;
        final double? transporteurLat = secoursEntry?.transporteur.latitude;
        final double? transporteurLng = secoursEntry?.transporteur.longitude;

        if (secoursEntry != null &&
            departScanne &&
            !relaisEffectue &&
            transporteurLat != null &&
            transporteurLng != null) {
          point = LatLng(transporteurLat, transporteurLng);
          isArrivalPoint = false;
          markerLabel = 'Transporteur principal';
        } else if (departScanne && destLat != null && destLng != null) {
          point = LatLng(destLat, destLng);
          isArrivalPoint = true;
          markerLabel =
              commande.destination ?? source.destination ?? 'Point d\'arrivee';
        } else if (!departScanne && departLat != null && departLng != null) {
          point = LatLng(departLat, departLng);
          isArrivalPoint = false;
          markerLabel =
              commande.localisationDepart ??
              source.localisationDepart ??
              'Point de depart';
        } else if (departLat != null && departLng != null) {
          point = LatLng(departLat, departLng);
          isArrivalPoint = false;
          markerLabel =
              commande.localisationDepart ??
              source.localisationDepart ??
              'Point de depart';
        } else if (destLat != null && destLng != null) {
          point = LatLng(destLat, destLng);
          isArrivalPoint = true;
          markerLabel =
              commande.destination ?? source.destination ?? 'Point d\'arrivee';
        }
      } else if (commande.latitudeDepart != null &&
          commande.longitudeDepart != null) {
        point = LatLng(commande.latitudeDepart!, commande.longitudeDepart!);
      }

      if (point == null) continue;

      Color? markerColor =
          (isArrivalPoint == null)
              ? null
              : (isArrivalPoint ? _markerArrivalColor : _markerDepartColor);
      if (isAttentionStatut(source.statut)) {
        markerColor = attentionColor;
      }
      final bool highlightMinTransporteur =
          mine == null && (minTransporteursById[commande.id] == true);
      if (highlightMinTransporteur &&
          (markerColor == null || markerColor == _markerDepartColor)) {
        markerColor = Colors.red;
      }

      markers.add(
        Marker(
          point: point,
          width: 80,
          height: 80,
          child: _CommandeMarker(
            commande: commande,
            onTap: () => _handleCommandeTap(commande),
            pointColor: markerColor,
            iconData:
                secoursEntry != null ? Icons.volunteer_activism_rounded : null,
            labelOverride: markerLabel,
            showLabel: false,
            rotationListenable: _mapRotationNotifier,
          ),
        ),
      );
    }

    return markers;
  }

  Future<void> _handleCommandeTap(Commande commande) async {
    if (!mounted) return;
    debugPrint(
      'MapView tap commande ${commande.id} statut: ${commande.statut ?? 'null'}',
    );
    final homeCtrl = context.read<HomeController>();
    final secoursInfo = homeCtrl.buildSecoursContactInfoForCommande(
      commande.id,
    );
    homeCtrl.setSelectedContactInfo(secoursInfo, notify: false);
    final statut = commande.statut?.trim().toLowerCase();
    if (statut == 'en_appelle' ||
        statut == 'appelle_client_1' ||
        statut == 'appelle_client_2') {
      homeCtrl.selectCommande(commande, openPanel: false);
      await _showCommandeDetails(commande);
      if (!mounted) return;
      homeCtrl.clearSelection();
      homeCtrl.setCommandTab(CommandTab.mes);
      return;
    }

    if (statut == 'non_repondre_client_1' ||
        statut == 'non_repondre_client_2') {
      homeCtrl.selectCommande(commande, openPanel: false);
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Verification en cours'),
              content: const Text(
                'Cette commande est en attente de verification par l\'administration.'
                ' Merci de patienter avant de continuer.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Terminer'),
                ),
              ],
            ),
      );
      if (!mounted) return;
      homeCtrl.clearSelection();
      homeCtrl.setCommandTab(CommandTab.mes);
      return;
    }

    homeCtrl.selectCommande(commande);
    await _fetchRouteForSelection(commande.id);
  }

  Future<void> _fetchRouteForSelection(
    String commandeId, {
    bool adjustCamera = true,
  }) async {
    final homeCtrl = context.read<HomeController>();
    final commande = homeCtrl.selectedCommande;
    if (commande == null || commande.id != commandeId) {
      if (_pendingRouteCommandeId == commandeId) {
        _pendingRouteCommandeId = null;
      }
      return;
    }

    final bool isMine = homeCtrl.isCommandeMine(commande.id);
    final bool preferCurrentPositionToArrivalWhenDepartScanned =
        homeCtrl
            .selectedContactInfo
            ?.preferCurrentPositionToArrivalWhenDepartScanned ==
        true;
    final LatLng? routeStartOverride =
        homeCtrl.selectedContactInfo?.routeStartLatitude != null &&
                homeCtrl.selectedContactInfo?.routeStartLongitude != null
            ? LatLng(
              homeCtrl.selectedContactInfo!.routeStartLatitude!,
              homeCtrl.selectedContactInfo!.routeStartLongitude!,
            )
            : null;
    final LatLng? routeTargetOverride =
        homeCtrl.selectedContactInfo?.routeTargetLatitude != null &&
                homeCtrl.selectedContactInfo?.routeTargetLongitude != null
            ? LatLng(
              homeCtrl.selectedContactInfo!.routeTargetLatitude!,
              homeCtrl.selectedContactInfo!.routeTargetLongitude!,
            )
            : null;
    final request = _deriveRouteRequest(
      commande,
      isMine: isMine,
      currentPos: _myPos,
      preferCurrentPositionToArrivalWhenDepartScanned:
          preferCurrentPositionToArrivalWhenDepartScanned,
      routeStartOverride: routeStartOverride,
      routeTargetOverride: routeTargetOverride,
    );

    if (request == null) {
      if (_pendingRouteCommandeId == commandeId) {
        _pendingRouteCommandeId = null;
      }
      _cachedRoutePoints = null;
      _resetOffRouteTracking();
      homeCtrl.clearRouteOnly();
      return;
    }

    _pendingRouteCommandeId = commandeId;

    try {
      final route = await _routeService.fetchRoute(
        start: request.start,
        end: request.end,
      );
      if (_pendingRouteCommandeId == commandeId) {
        _pendingRouteCommandeId = null;
      }
      if (!mounted) return;
      if (homeCtrl.selectedCommandeId != commandeId) return;
      final points = route.points;
      homeCtrl.setRouteData(
        start: request.start,
        end: request.end,
        startOrigin: request.startOrigin,
        endOrigin: request.endOrigin,
        polyline: points,
        distanceMeters: route.distanceMeters,
        duration: route.duration,
      );
      _cachedRoutePoints = List<LatLng>.from(points);
      _clearRouteFailure(commandeId);
      _resetOffRouteTracking();
      if (adjustCamera) {
        if (_following) {
          _fitRouteBoundsQuickly(points);
        } else {
          _fitCameraToBounds(LatLngBounds.fromPoints(points));
        }
      }
    } catch (e) {
      if (_pendingRouteCommandeId == commandeId) {
        _pendingRouteCommandeId = null;
      }
      if (!mounted) return;
      if (homeCtrl.selectedCommandeId != commandeId) return;
      debugPrint('Route fetch error: $e');
      _markRouteFailure(commandeId);
      homeCtrl.clearRouteOnly();
      _cachedRoutePoints = null;
      _resetOffRouteTracking();
    }
  }

  double? _normalizeHeading(double heading) {
    if (heading.isNaN || heading.isInfinite || heading < 0) {
      return null;
    }
    final normalized = heading % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double? _bearingBetween(LatLng? from, LatLng to) {
    if (from == null) return null;
    final sameLat = (from.latitude - to.latitude).abs() < 1e-7;
    final sameLng = (from.longitude - to.longitude).abs() < 1e-7;
    if (sameLat && sameLng) return null;

    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final deltaLng = _degToRad(to.longitude - from.longitude);

    final y = math.sin(deltaLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);
    final bearingRad = math.atan2(y, x);
    final bearingDeg = (bearingRad * 180 / math.pi + 360) % 360;
    if (bearingDeg.isNaN || bearingDeg.isInfinite) {
      return null;
    }
    return bearingDeg;
  }

  double _degToRad(double degree) => degree * math.pi / 180.0;

  bool _maybeUpdateHeading({
    required LatLng current,
    LatLng? previous,
    required double moveMeters,
    required double speedKmh,
    double? gpsHeading,
    double? compassHeading,
  }) {
    final double? normalizedGps = gpsHeading;
    final double? normalizedCompass = compassHeading;
    final bool hasReliableAccuracy =
        _accuracyMeters != null &&
        _accuracyMeters!.isFinite &&
        _accuracyMeters! <= _headingMaxAccuracyMeters;
    final bool movedEnoughForAnyHeading =
        previous != null && moveMeters >= _headingMinMovementMeters;
    if (!movedEnoughForAnyHeading && speedKmh < _headingReliableSpeedKmh) {
      return false;
    }
    if (!hasReliableAccuracy &&
        speedKmh < _headingReliableSpeedKmh &&
        moveMeters < _headingBearingDistanceMeters) {
      return false;
    }

    final bool fastEnough = speedKmh >= _headingReliableSpeedKmh;
    final bool veryFast = speedKmh >= _headingVeryReliableSpeedKmh;
    double? nextHeading;
    final bool movedEnough =
        previous != null &&
        moveMeters >=
            (veryFast
                ? _headingFastBearingDistanceMeters
                : _headingBearingDistanceMeters);
    final double? movementBearing =
        movedEnough ? _bearingBetween(previous, current) : null;

    if (veryFast && movementBearing != null) {
      nextHeading = movementBearing;
    }
    if (nextHeading == null &&
        fastEnough &&
        normalizedGps != null &&
        hasReliableAccuracy) {
      nextHeading = normalizedGps;
    }
    if (nextHeading == null && movementBearing != null) {
      nextHeading = movementBearing;
    }
    // At low speed (or stopped), prefer filtered compass.
    if (nextHeading == null && !fastEnough && normalizedCompass != null) {
      nextHeading = normalizedCompass;
    }
    if (nextHeading == null && normalizedCompass != null) {
      nextHeading = normalizedCompass;
    }
    if (nextHeading == null) {
      return false;
    }
    final double resolvedHeading;
    if (_headingDegrees == null) {
      resolvedHeading = nextHeading;
    } else {
      final double delta = _angleDelta(_headingDegrees!, nextHeading);
      final bool suspiciousJump =
          delta >= _headingJumpRejectDegrees &&
          moveMeters < _headingJumpRejectMoveMeters &&
          speedKmh < _fastSpeedThresholdKmh;
      if (suspiciousJump) {
        return false;
      }
      if (delta >= 45) {
        resolvedHeading = nextHeading;
      } else {
        final double smoothing =
            fastEnough
                ? _headingFastSmoothingFactor
                : _headingSlowSmoothingFactor;
        resolvedHeading = _lerpHeading(
          _headingDegrees!,
          nextHeading,
          smoothing,
        );
      }
    }
    _headingDegrees = resolvedHeading;
    return true;
  }

  void _setHeadingDirect(double heading) {
    double normalized = heading % 360;
    if (normalized < 0) {
      normalized += 360;
    }
    _headingDegrees = normalized;
  }

  double _lerpHeading(double from, double to, double t) {
    double delta = (to - from + 540) % 360 - 180;
    final value = from + delta * t;
    if (value >= 360) {
      return value - 360;
    }
    if (value < 0) {
      return value + 360;
    }
    return value;
  }

  Future<void> startNavigationFor(Commande commande) async {
    if (!mounted) return;
    final homeCtrl = context.read<HomeController>();
    final bool isMine = homeCtrl.isCommandeMine(commande.id);
    if (!isMine) {
      _showSnack('Commande non assignÃ©e.');
      return;
    }

    if (homeCtrl.selectedCommandeId != commande.id) {
      homeCtrl.selectCommande(commande);
    }

    final needsRoute =
        homeCtrl.currentPolyline == null ||
        homeCtrl.currentPolyline!.length < 2;

    if (needsRoute) {
      await _fetchRouteForSelection(commande.id);
    }

    if (!mounted) return;

    final routePoints = homeCtrl.currentPolyline;
    if (routePoints == null || routePoints.length < 2) {
      _showSnack('Trajet indisponible pour le moment.');
      return;
    }

    final bounds = LatLngBounds.fromPoints(routePoints);
    await _fitMapboxCameraToBounds(
      bounds,
      padding: const EdgeInsets.fromLTRB(48, 64, 48, 96),
    );

    _updateFollowing(true, notify: false);
    _notifyUserLocationVisual();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_following) return;
      final pos = _displayedMyPos ?? _myPos ?? routePoints.first;
      final navigationPlan = _buildNavigationCameraPlan(
        currentPos: pos,
        route: routePoints,
      );
      unawaited(
        _applyCameraUpdate(
          center: navigationPlan?.center ?? pos,
          zoom: navigationPlan?.zoom ?? _cameraZoom,
          rotation: navigationPlan?.rotation,
          pitch: navigationPlan?.pitch,
          padding: navigationPlan?.padding,
        ),
      );
    });

    homeCtrl.setNavigationMode(true);
    unawaited(_setNavigationWakeLock(true));
  }

  Future<void> previewRouteFor(
    Commande commande, {
    bool preferCurrentPositionToArrivalWhenDepartScanned = false,
    LatLng? routeStartOverride,
    LatLng? routeTargetOverride,
  }) async {
    if (!mounted) return;
    final homeCtrl = context.read<HomeController>();
    final request = _deriveRouteRequest(
      commande,
      isMine: false,
      currentPos: _myPos,
      preferCurrentPositionToArrivalWhenDepartScanned:
          preferCurrentPositionToArrivalWhenDepartScanned,
      routeStartOverride: routeStartOverride,
      routeTargetOverride: routeTargetOverride,
    );
    if (request == null) {
      _showSnack('Trajet indisponible pour le moment.');
      return;
    }

    try {
      final route = await _routeService.fetchRoute(
        start: request.start,
        end: request.end,
      );
      if (!mounted) return;
      final points = route.points;
      homeCtrl.setRouteData(
        start: request.start,
        end: request.end,
        startOrigin: request.startOrigin,
        endOrigin: request.endOrigin,
        polyline: points,
        distanceMeters: route.distanceMeters,
        duration: route.duration,
      );
      _clearRouteFailure(commande.id);
      _fitCameraToBounds(LatLngBounds.fromPoints(points));
    } catch (e) {
      if (!mounted) return;
      homeCtrl.clearRouteOnly();
      _cachedRoutePoints = null;
      _resetOffRouteTracking();
      _markRouteFailure(commande.id);
      _showSnack('Aucun itineraire routier disponible pour le moment.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  _RouteRequest? _deriveRouteRequest(
    Commande commande, {
    required bool isMine,
    LatLng? currentPos,
    bool preferCurrentPositionToArrivalWhenDepartScanned = false,
    LatLng? routeStartOverride,
    LatLng? routeTargetOverride,
  }) {
    if (isMine && commande.qrCodeReceptionScanne == true) {
      return null;
    }

    LatLng? start;
    LatLng? end;
    RoutePointOrigin startOrigin = RoutePointOrigin.depart;
    RoutePointOrigin endOrigin = RoutePointOrigin.destination;

    final LatLng? effectiveCurrentPos = routeStartOverride ?? currentPos;
    if (effectiveCurrentPos != null && routeTargetOverride != null) {
      start = effectiveCurrentPos;
      end = routeTargetOverride;
      startOrigin = RoutePointOrigin.courier;
      endOrigin = RoutePointOrigin.contact;
    }
    if ((isMine || preferCurrentPositionToArrivalWhenDepartScanned) &&
        end == null &&
        effectiveCurrentPos != null) {
      final bool goToArrival = commande.qrCodeDepartScanne == true;
      final double? destinationLat = commande.latitudeDestination;
      final double? destinationLng = commande.longitudeDestination;
      final double? departLat = commande.latitudeDepart;
      final double? departLng = commande.longitudeDepart;

      double? targetLat;
      double? targetLng;
      if (preferCurrentPositionToArrivalWhenDepartScanned && !isMine) {
        targetLat = goToArrival ? destinationLat : null;
        targetLng = goToArrival ? destinationLng : null;
      } else {
        targetLat = goToArrival ? destinationLat : departLat;
        targetLng = goToArrival ? destinationLng : departLng;
      }
      if (targetLat == null || targetLng == null) {
        targetLat ??= departLat;
        targetLng ??= departLng;
      }

      if (targetLat != null && targetLng != null) {
        start = effectiveCurrentPos;
        end = LatLng(targetLat, targetLng);
        startOrigin = RoutePointOrigin.courier;
        endOrigin =
            goToArrival
                ? RoutePointOrigin.destination
                : RoutePointOrigin.depart;
      }
    }

    final bool hasDepart =
        commande.latitudeDepart != null && commande.longitudeDepart != null;
    final bool hasDestination =
        commande.latitudeDestination != null &&
        commande.longitudeDestination != null;

    if (start == null && hasDepart && hasDestination) {
      start = LatLng(commande.latitudeDepart!, commande.longitudeDepart!);
      startOrigin = RoutePointOrigin.depart;
      end = LatLng(
        commande.latitudeDestination!,
        commande.longitudeDestination!,
      );
      endOrigin = RoutePointOrigin.destination;
    }

    if (start == null || end == null) {
      return null;
    }

    return _RouteRequest(
      start: start,
      end: end,
      startOrigin: startOrigin,
      endOrigin: endOrigin,
    );
  }

  Future<void> _fitMapboxCameraToBounds(
    LatLngBounds bounds, {
    required EdgeInsets padding,
  }) async {
    if (kIsWeb) {
      if (!mounted) return;
      _webMapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: padding),
      );
      final camera = _webMapController.camera;
      _cameraCenter = camera.center;
      _cameraZoom = camera.zoom;
      _cameraRotation = camera.rotation;
      _updateRotationNotifier(camera.rotation);
      return;
    }

    final mapboxMap = _mapboxMap;
    if (!mounted || mapboxMap == null) return;

    final camera = await mapboxMap.cameraForCoordinateBounds(
      mbx.CoordinateBounds(
        southwest: _toMapboxPoint(LatLng(bounds.south, bounds.west)),
        northeast: _toMapboxPoint(LatLng(bounds.north, bounds.east)),
        infiniteBounds: false,
      ),
      mbx.MbxEdgeInsets(
        top: padding.top,
        left: padding.left,
        bottom: padding.bottom,
        right: padding.right,
      ),
      _cameraRotation,
      _resolvedCameraPitch(),
      null,
      null,
    );

    await mapboxMap.easeTo(
      camera,
      mbx.MapAnimationOptions(
        duration: _cameraAnimationDuration.inMilliseconds,
        startDelay: 0,
      ),
    );

    if (camera.center != null) {
      _cameraCenter = _fromMapboxPoint(camera.center!);
    }
    if (camera.zoom != null) {
      _cameraZoom = camera.zoom!;
    }
    if (camera.bearing != null) {
      _cameraRotation = camera.bearing!;
    }
    if (camera.pitch != null) {
      _cameraPitch = camera.pitch!;
    }
    _cacheCameraPadding(
      mbx.MbxEdgeInsets(
        top: padding.top,
        left: padding.left,
        bottom: padding.bottom,
        right: padding.right,
      ),
    );
  }

  void _fitCameraToBounds(LatLngBounds bounds) {
    if (!mounted) return;
    _updateFollowing(false, notify: false);
    _notifyUserLocationVisual();
    unawaited(
      _fitMapboxCameraToBounds(
        bounds,
        padding: const EdgeInsets.fromLTRB(48, 48, 48, 220),
      ),
    );
  }

  Future<void> _showCommandeDetails(Commande commande) async {
    if (!mounted) return;
    final homeCtrl = context.read<HomeController>();
    final bool isMine = homeCtrl.isCommandeMine(commande.id);
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder:
          (_) => ChangeNotifierProvider<HomeController>.value(
            value: homeCtrl,
            child: CommandeDetailsSheet(commande: commande, isMine: isMine),
          ),
    );
  }

  Future<void> openCommandeDetails(Commande commande) {
    return _showCommandeDetails(commande);
  }

  Future<void> _handleTransporteurPanneTap(
    TransporteurPanneCommandesResponse entry,
  ) async {
    if (!mounted) return;
    final dynamic selection = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransporteurPanneDetailsPage(data: entry),
      ),
    );
    if (!mounted || selection == null) return;
    final homeController = context.read<HomeController>();
    final Commande? commande;
    if (selection is Commande) {
      commande = selection;
      homeController.setSelectedContactInfo(null, notify: false);
    } else {
      final dynamic rawCommande = selection.commande;
      final dynamic rawTransporteur = selection.transporteur;
      if (rawCommande is! Commande) return;
      commande = rawCommande;
      final String displayName =
          '${rawTransporteur?.prenom ?? ''} ${rawTransporteur?.nom ?? ''}'
              .trim();
      homeController.setSelectedContactInfo(
        SelectedContactInfo(
          displayName:
              displayName.isEmpty ? 'Transporteur en panne' : displayName,
          imageUrl: rawTransporteur?.image as String?,
          phoneDepart: commande.telDepart,
          phoneArrivee: commande.telArrivee,
          preferCurrentPositionToArrivalWhenDepartScanned: true,
        ),
        notify: false,
      );
    }
    homeController.selectCommande(commande);
    await previewRouteFor(
      commande,
      preferCurrentPositionToArrivalWhenDepartScanned: true,
    );
  }

  Future<void> _handleTransporteurSecoursTap(
    TransporteurSecoursCommandesResponse entry,
  ) async {
    if (!mounted) return;
    final transporteurEnPanneId =
        context.read<HomeController>().currentTransporteurId;
    if (transporteurEnPanneId == null || transporteurEnPanneId.isEmpty) return;
    final dynamic selection = await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => TransporteurSecoursDetailsPage(
              transporteurEnPanneId: transporteurEnPanneId,
              data: entry,
            ),
      ),
    );
    if (!mounted || selection == null) return;
    final homeController = context.read<HomeController>();
    final dynamic rawCommande = selection.commande;
    final dynamic rawTransporteur = selection.transporteur;
    if (rawCommande is! Commande) return;
    final commande = rawCommande;
    final double? routeLatitude =
        rawTransporteur?.latitude is num
            ? (rawTransporteur.latitude as num).toDouble()
            : null;
    final double? routeLongitude =
        rawTransporteur?.longitude is num
            ? (rawTransporteur.longitude as num).toDouble()
            : null;
    final String displayName =
        '${rawTransporteur?.prenom ?? ''} ${rawTransporteur?.nom ?? ''}'.trim();
    homeController.setSelectedContactInfo(
      SelectedContactInfo(
        displayName: displayName.isEmpty ? 'Transporteur secours' : displayName,
        imageUrl: rawTransporteur?.image as String?,
        phoneDepart: commande.telDepart,
        phoneArrivee: commande.telArrivee,
        preferCurrentPositionToArrivalWhenDepartScanned: true,
        routeStartLatitude: routeLatitude,
        routeStartLongitude: routeLongitude,
      ),
      notify: false,
    );
    homeController.selectCommande(commande);
    await previewRouteFor(
      commande,
      preferCurrentPositionToArrivalWhenDepartScanned: true,
      routeStartOverride:
          routeLatitude != null && routeLongitude != null
              ? LatLng(routeLatitude, routeLongitude)
              : null,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: kIsWeb ? _buildWebMap() : _buildNativeMap(),
    );
  }

  Widget _buildNativeMap() {
    return mbx.MapWidget(
      key: const ValueKey('coursier-mapbox-map'),
      styleUri: mbx.MapboxStyles.MAPBOX_STREETS,
      cameraOptions: mbx.CameraOptions(
        center: _toMapboxPoint(_defaultInitialCenter),
        zoom: 12,
        bearing: 0,
        pitch: 0,
      ),
      onMapCreated: _onMapboxCreated,
      onMapLoadedListener: _onMapboxLoaded,
      onCameraChangeListener: _onMapboxCameraChanged,
      onScrollListener: _onMapboxScroll,
      onZoomListener: _onMapboxZoom,
    );
  }

  Widget _buildWebMap() {
    return FlutterMap(
      mapController: _webMapController,
      options: _webMapOptions,
      children: [
        TileLayer(
          urlTemplate:
              _mapboxAccessToken.trim().isNotEmpty
                  ? _webMapboxTileUrlTemplate
                  : _fallbackTileUrlTemplate,
          subdomains:
              _mapboxAccessToken.trim().isNotEmpty
                  ? const <String>[]
                  : const ['a', 'b', 'c', 'd'],
          maxNativeZoom: 20,
          maxZoom: 20,
          keepBuffer: 5,
          panBuffer: 2,
          tileDisplay: const TileDisplay.fadeIn(
            duration: Duration(milliseconds: 220),
          ),
        ),
        _buildWebRoutePolylineLayer(),
        _buildWebCommandeMarkersLayer(),
        _buildWebRouteArrivalMarkerLayer(),
        _buildWebUserLocationLayer(),
      ],
    );
  }

  Widget _buildWebRoutePolylineLayer() {
    return ValueListenableBuilder<List<LatLng>?>(
      valueListenable: _polylineNotifier,
      builder: (_, points, __) {
        if (points == null || points.length < 2) {
          return const SizedBox.shrink();
        }
        final route = Polyline(
          points: points,
          strokeWidth: 7,
          color: Colors.deepPurpleAccent.withValues(alpha: 0.95),
          borderColor: Colors.white.withValues(alpha: 0.9),
          borderStrokeWidth: 3,
        );
        return RepaintBoundary(child: PolylineLayer(polylines: [route]));
      },
    );
  }

  Widget _buildWebCommandeMarkersLayer() {
    return ValueListenableBuilder<List<Marker>>(
      valueListenable: _commandeMarkersNotifier,
      builder: (_, markers, __) {
        if (markers.isEmpty) {
          return const SizedBox.shrink();
        }
        return RepaintBoundary(
          child: MarkerLayer(rotate: false, markers: markers),
        );
      },
    );
  }

  Widget _buildWebRouteArrivalMarkerLayer() {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: _routeArrivalNotifier,
      builder: (_, arrivalPoint, __) {
        if (arrivalPoint == null) {
          return const SizedBox.shrink();
        }
        return RepaintBoundary(
          child: MarkerLayer(
            markers: [
              Marker(
                point: arrivalPoint,
                width: 54,
                height: 54,
                child: const _RouteEndpointMarker(isStart: false),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebUserLocationLayer() {
    return ValueListenableBuilder<_UserLocationVisual?>(
      valueListenable: _userLocationNotifier,
      builder: (_, visual, __) {
        if (visual == null) {
          return const SizedBox.shrink();
        }
        return MarkerLayer(
          markers: [
            Marker(
              point: visual.position,
              width: 20,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onMapboxCreated(mbx.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  void _onMapboxLoaded(mbx.MapLoadedEventData _) {
    _mapboxStyleReady = true;
    unawaited(_initializeMapboxMap());
  }

  void _onMapboxScroll(mbx.MapContentGestureContext _) {
    if (_following) {
      _updateFollowing(false);
    }
  }

  void _onMapboxZoom(mbx.MapContentGestureContext _) {
    if (_following) {
      _updateFollowing(false);
    }
  }

  void _onMapboxCameraChanged(mbx.CameraChangedEventData eventData) {
    final state = eventData.cameraState;
    _cameraCenter = _fromMapboxPoint(state.center);
    _cameraZoom = state.zoom;
    _cameraRotation = state.bearing;
    _cameraPitch = state.pitch;
    _updateRotationNotifier(state.bearing);
    _maybeResetFollowFromNativeGesture();
  }

  void _maybeResetFollowFromNativeGesture() {
    if (!_following ||
        _cameraAnimationActive ||
        _nativeGestureFollowResetCheckInFlight) {
      return;
    }
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }
    _nativeGestureFollowResetCheckInFlight = true;
    unawaited(() async {
      try {
        final gestureInProgress = await mapboxMap.isGestureInProgress();
        if (!mounted ||
            !gestureInProgress ||
            _cameraAnimationActive ||
            !_following) {
          return;
        }
        _updateFollowing(false);
      } catch (_) {
        // Ignore transient platform errors while checking gesture state.
      } finally {
        _nativeGestureFollowResetCheckInFlight = false;
      }
    }());
  }

  Future<void> _initializeMapboxMap() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;

    if (!_mapboxManagersReady) {
      _markerAnnotationManager ??=
          await mapboxMap.annotations.createCircleAnnotationManager();
      _polylineAnnotationManager ??=
          await mapboxMap.annotations.createPolylineAnnotationManager();
      _markerAnnotationManager!.tapEvents(
        onTap: (annotation) {
          final onTap = _annotationTapHandlers[annotation.id];
          if (onTap != null) {
            onTap();
          }
        },
      );
      _mapboxManagersReady = true;
    }
    await mapboxMap.scaleBar.updateSettings(
      mbx.ScaleBarSettings(enabled: false),
    );
    await mapboxMap.compass.updateSettings(
      mbx.CompassSettings(enabled: false, visibility: false, clickable: false),
    );
    await _syncNativeLocationComponent();
    _mapboxStyleReady = true;
    _scheduleMapboxOverlaySync();
  }

  void _scheduleMapboxOverlaySync() {
    if (_mapboxMap == null || !_mapboxStyleReady) return;
    if (_mapboxOverlaySyncRunning) {
      _mapboxOverlaySyncQueued = true;
      return;
    }
    unawaited(_syncMapboxOverlays());
  }

  Future<void> _syncMapboxOverlays() async {
    final markerManager = _markerAnnotationManager;
    final polylineManager = _polylineAnnotationManager;
    if (markerManager == null || polylineManager == null) return;

    _mapboxOverlaySyncRunning = true;
    try {
      await markerManager.deleteAll();
      await polylineManager.deleteAll();
      _annotationTapHandlers.clear();

      final markers = <Marker>[
        ..._commandeMarkersNotifier.value,
        if (_routeArrivalNotifier.value != null)
          Marker(
            point: _routeArrivalNotifier.value!,
            width: 54,
            height: 54,
            child: const _RouteEndpointMarker(isStart: false),
          ),
      ];

      for (final marker in markers) {
        final options = _toCircleAnnotationOptions(marker);
        if (options == null) continue;
        final annotation = await markerManager.create(options);
        final callback = _resolveMarkerTap(marker);
        if (callback != null) {
          _annotationTapHandlers[annotation.id] = callback;
        }
      }

      final routePoints = _polylineNotifier.value;
      if (routePoints != null && routePoints.length >= 2) {
        await polylineManager.create(
          mbx.PolylineAnnotationOptions(
            geometry: mbx.LineString(
              coordinates: routePoints
                  .map((point) => mbx.Position(point.longitude, point.latitude))
                  .toList(growable: false),
            ),
            lineWidth: 7,
            lineColor: _colorToArgb(
              Colors.deepPurpleAccent.withValues(alpha: 0.95),
            ),
            lineBorderColor: _colorToArgb(Colors.white.withValues(alpha: 0.9)),
            lineBorderWidth: 3,
            lineJoin: mbx.LineJoin.ROUND,
          ),
        );
      }
    } finally {
      _mapboxOverlaySyncRunning = false;
      if (_mapboxOverlaySyncQueued) {
        _mapboxOverlaySyncQueued = false;
        _scheduleMapboxOverlaySync();
      }
    }
  }

  mbx.CircleAnnotationOptions? _toCircleAnnotationOptions(Marker marker) {
    final child = marker.child;
    Color fillColor = _markerDepartColor;
    double radius = 12;
    double strokeWidth = 3;

    if (child is _CommandeMarker) {
      fillColor = child.pointColor ?? const Color(0xFF2575FC);
      radius = child.iconData == null ? 12 : 13;
    } else if (child is _PanneMarker) {
      fillColor =
          child.isAccident ? const Color(0xFFB3261E) : const Color(0xFFD93025);
      radius = 14;
    } else if (child is _SecoursMarker) {
      fillColor = const Color(0xFF188038);
      radius = 14;
    } else if (child is _RouteEndpointMarker) {
      fillColor =
          child.isStart ? const Color(0xFF34D058) : const Color(0xFFEA4335);
      radius = 15;
      strokeWidth = 4;
    } else {
      return null;
    }

    return mbx.CircleAnnotationOptions(
      geometry: _toMapboxPoint(marker.point),
      circleColor: _colorToArgb(fillColor),
      circleOpacity: 0.95,
      circleRadius: radius,
      circleStrokeColor: _colorToArgb(Colors.white.withValues(alpha: 0.95)),
      circleStrokeWidth: strokeWidth,
      customData: <String, Object>{'markerType': child.runtimeType.toString()},
    );
  }

  VoidCallback? _resolveMarkerTap(Marker marker) {
    final child = marker.child;
    if (child is _CommandeMarker) return child.onTap;
    if (child is _PanneMarker) return child.onTap;
    if (child is _SecoursMarker) return child.onTap;
    return null;
  }

  void _handleRoutePrefetchState({
    required Commande? selectedCommande,
    required bool isPanelOpen,
    required List<LatLng>? currentPolyline,
    required _RouteRequest? requestPreview,
  }) {
    if (!mounted) return;
    final String? selectedId = selectedCommande?.id;
    final bool shouldRequestRoute =
        selectedId != null &&
        isPanelOpen &&
        currentPolyline == null &&
        requestPreview != null &&
        !_isRouteFailureCoolingDown(selectedId) &&
        _pendingRouteCommandeId != selectedId;
    if (shouldRequestRoute) {
      _pendingRouteCommandeId = selectedId;
      _fetchRouteForSelection(selectedId);
    } else if ((selectedId == null || !isPanelOpen) &&
        _pendingRouteCommandeId != null) {
      _pendingRouteCommandeId = null;
    }
  }

  bool _isRouteFailureCoolingDown(String commandeId) {
    if (_failedRouteCommandeId != commandeId || _lastRouteFailureAt == null) {
      return false;
    }
    return DateTime.now().difference(_lastRouteFailureAt!) <
        _routeFailureRetryDelay;
  }

  void _markRouteFailure(String commandeId) {
    _failedRouteCommandeId = commandeId;
    _lastRouteFailureAt = DateTime.now();
  }

  void _clearRouteFailure(String commandeId) {
    if (_failedRouteCommandeId != commandeId) return;
    _failedRouteCommandeId = null;
    _lastRouteFailureAt = null;
  }

  void _fitRouteBoundsQuickly(List<LatLng> routePoints) {
    if (!mounted || routePoints.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bounds = LatLngBounds.fromPoints(routePoints);
      unawaited(
        _fitMapboxCameraToBounds(
          bounds,
          padding: const EdgeInsets.fromLTRB(48, 48, 48, 220),
        ),
      );
    });
  }
}

class _RouteEndpointMarker extends StatelessWidget {
  final bool isStart;
  const _RouteEndpointMarker({required this.isStart});

  @override
  Widget build(BuildContext context) {
    final Color fillColor =
        isStart ? const Color(0xFF34D058) : const Color(0xFFEA4335);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: fillColor, shape: BoxShape.circle),
          child: Center(
            child: Icon(
              isStart ? Icons.flag : Icons.location_on,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteRequest {
  const _RouteRequest({
    required this.start,
    required this.end,
    required this.startOrigin,
    required this.endOrigin,
  });

  final LatLng start;
  final LatLng end;
  final RoutePointOrigin startOrigin;
  final RoutePointOrigin endOrigin;
}

class _RouteProjection {
  const _RouteProjection({
    required this.projectedPoint,
    required this.segmentIndex,
    required this.segmentFraction,
    required this.distanceAlongRouteMeters,
    required this.distanceMeters,
  });

  final LatLng projectedPoint;
  final int segmentIndex;
  final double segmentFraction;
  final double distanceAlongRouteMeters;
  final double distanceMeters;
}

class _SegmentProjection {
  const _SegmentProjection({
    required this.projectedPoint,
    required this.fraction,
  });

  final LatLng projectedPoint;
  final double fraction;
}

class _NavigationCameraPlan {
  const _NavigationCameraPlan({
    required this.center,
    required this.zoom,
    required this.rotation,
    required this.pitch,
    required this.padding,
    required this.distanceToTurnMeters,
    required this.focusPosition,
    required this.localRouteBearing,
    required this.predictiveRouteBearing,
  });

  final LatLng center;
  final double zoom;
  final double rotation;
  final double pitch;
  final mbx.MbxEdgeInsets padding;
  final double? distanceToTurnMeters;
  final LatLng focusPosition;
  final double? localRouteBearing;
  final double? predictiveRouteBearing;
}

class _TurnAheadInfo {
  const _TurnAheadInfo({
    required this.distanceMeters,
    required this.angleDeltaDegrees,
  });

  final double distanceMeters;
  final double angleDeltaDegrees;
}

class _RouteDeviationDecision {
  const _RouteDeviationDecision.none()
    : shouldRecalculate = false,
      force = false;

  const _RouteDeviationDecision.recalculate({required this.force})
    : shouldRecalculate = true;

  final bool shouldRecalculate;
  final bool force;
}

class _CommandeMarker extends StatelessWidget {
  final Commande commande;
  final VoidCallback onTap;
  final Color? pointColor;
  final IconData? iconData;
  final String? labelOverride;
  final bool showLabel;
  final ValueListenable<double> rotationListenable;

  const _CommandeMarker({
    required this.commande,
    required this.onTap,
    this.pointColor,
    this.iconData,
    this.labelOverride,
    this.showLabel = false,
    required this.rotationListenable,
  });

  @override
  Widget build(BuildContext context) {
    final String? label =
        showLabel
            ? (labelOverride ?? commande.localisationDepart ?? 'Point pickup')
            : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            ValueListenableBuilder<double>(
              valueListenable: rotationListenable,
              child: Container(
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
              builder: (_, rotationDegrees, child) {
                final radians = -rotationDegrees * math.pi / 180;
                return Transform.rotate(
                  angle: radians,
                  alignment: Alignment.center,
                  child: child,
                );
              },
            ),
          if (label != null) const SizedBox(height: 4),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient:
                      pointColor == null
                          ? const LinearGradient(
                            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : null,
                  color: pointColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child:
                    iconData == null
                        ? null
                        : Icon(iconData, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanneMarker extends StatelessWidget {
  const _PanneMarker({required this.isAccident, required this.onTap});

  final bool isAccident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color:
                      isAccident
                          ? const Color(0xFFB3261E)
                          : const Color(0xFFD93025),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Icon(
                  isAccident
                      ? Icons.car_crash_rounded
                      : Icons.warning_amber_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecoursMarker extends StatelessWidget {
  const _SecoursMarker({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: const Color(0xFF188038),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Icon(
                  Icons.support_agent,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserLocationVisual {
  const _UserLocationVisual({
    required this.position,
    this.accuracyMeters,
    this.headingDegrees,
    required this.isFollowing,
  });

  final LatLng position;
  final double? accuracyMeters;
  final double? headingDegrees;
  final bool isFollowing;
}

class _LatLngTween extends Tween<LatLng> {
  _LatLngTween({required LatLng begin, required LatLng end})
    : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    final startLat = begin!.latitude;
    final startLng = begin!.longitude;
    final endLat = end!.latitude;
    final endLng = end!.longitude;
    return LatLng(
      startLat + (endLat - startLat) * t,
      startLng + (endLng - startLng) * t,
    );
  }
}

// Table des zones (bornes simples rectangulaires)
const List<Map<String, Object>> kZones = [
  // ===================== NORD / GRAND TUNIS =====================
  {
    "name": "TUNIS",
    "zone": "GRAND_TUNIS",
    "latMin": 36.70,
    "latMax": 36.95,
    "lngMin": 10.00,
    "lngMax": 10.45,
  },
  {
    "name": "ARIANA",
    "zone": "GRAND_TUNIS",
    "latMin": 36.75,
    "latMax": 37.10,
    "lngMin": 10.00,
    "lngMax": 10.45,
  },
  {
    "name": "BEN_AROUS",
    "zone": "GRAND_TUNIS",
    "latMin": 36.55,
    "latMax": 36.85,
    "lngMin": 10.05,
    "lngMax": 10.45,
  },
  {
    "name": "MANOUBA",
    "zone": "GRAND_TUNIS",
    "latMin": 36.60,
    "latMax": 36.98,
    "lngMin": 9.85,
    "lngMax": 10.25,
  },

  // ===================== NORD EST / CAP BON & BIZERTE =====================
  {
    "name": "BIZERTE",
    "zone": "NORD_EST",
    "latMin": 37.00,
    "latMax": 37.55,
    "lngMin": 9.30,
    "lngMax": 10.35,
  },
  {
    "name": "NABEUL",
    "zone": "NORD_EST",
    "latMin": 36.15,
    "latMax": 36.95,
    "lngMin": 10.25,
    "lngMax": 11.20,
  },

  // ===================== NORD OUEST =====================
  {
    "name": "BEJA",
    "zone": "NORD_OUEST",
    "latMin": 36.50,
    "latMax": 37.20,
    "lngMin": 8.60,
    "lngMax": 9.60,
  },
  {
    "name": "JENDOUBA",
    "zone": "NORD_OUEST",
    "latMin": 36.50,
    "latMax": 37.10,
    "lngMin": 8.30,
    "lngMax": 9.20,
  },
  {
    "name": "KEF",
    "zone": "NORD_OUEST",
    "latMin": 35.90,
    "latMax": 36.80,
    "lngMin": 8.20,
    "lngMax": 9.10,
  },
  {
    "name": "SILIANA",
    "zone": "NORD_OUEST",
    "latMin": 35.70,
    "latMax": 36.40,
    "lngMin": 8.70,
    "lngMax": 9.80,
  },

  // ===================== CENTRE =====================
  {
    "name": "ZAGHOUAN",
    "zone": "CENTRE",
    "latMin": 36.10,
    "latMax": 36.60,
    "lngMin": 9.90,
    "lngMax": 10.60,
  },
  {
    "name": "KAIROUAN",
    "zone": "CENTRE",
    "latMin": 35.20,
    "latMax": 36.10,
    "lngMin": 9.50,
    "lngMax": 10.50,
  },
  {
    "name": "KASSERINE",
    "zone": "CENTRE_OUEST",
    "latMin": 34.80,
    "latMax": 35.70,
    "lngMin": 8.20,
    "lngMax": 9.50,
  },
  {
    "name": "SIDI_BOUZID",
    "zone": "CENTRE_OUEST",
    "latMin": 34.60,
    "latMax": 35.30,
    "lngMin": 8.90,
    "lngMax": 10.20,
  },

  // ===================== SAHEL / CENTRE EST =====================
  {
    "name": "SOUSSE",
    "zone": "SAHEL",
    "latMin": 35.60,
    "latMax": 36.20,
    "lngMin": 10.20,
    "lngMax": 10.90,
  },
  {
    "name": "MONASTIR",
    "zone": "SAHEL",
    "latMin": 35.40,
    "latMax": 36.00,
    "lngMin": 10.50,
    "lngMax": 11.10,
  },
  {
    "name": "MAHDIA",
    "zone": "SAHEL",
    "latMin": 35.00,
    "latMax": 35.65,
    "lngMin": 10.60,
    "lngMax": 11.30,
  },

  // ===================== SFAX =====================
  {
    "name": "SFAX",
    "zone": "SFAX",
    "latMin": 34.35,
    "latMax": 35.20,
    "lngMin": 10.10,
    "lngMax": 11.10,
  },

  // ===================== SUD EST =====================
  {
    "name": "GABES",
    "zone": "SUD_EST",
    "latMin": 33.40,
    "latMax": 34.20,
    "lngMin": 9.70,
    "lngMax": 10.80,
  },
  {
    "name": "MEDENINE",
    "zone": "SUD_EST",
    "latMin": 32.50,
    "latMax": 33.80,
    "lngMin": 10.00,
    "lngMax": 11.20,
  },
  {
    "name": "TATAOUINE",
    "zone": "SUD_EST",
    "latMin": 31.80,
    "latMax": 33.20,
    "lngMin": 9.60,
    "lngMax": 10.80,
  },

  // ===================== SUD OUEST =====================
  {
    "name": "GAFSA",
    "zone": "SUD_OUEST",
    "latMin": 34.00,
    "latMax": 34.90,
    "lngMin": 7.80,
    "lngMax": 9.30,
  },
  {
    "name": "TOZEUR",
    "zone": "SUD_OUEST",
    "latMin": 33.60,
    "latMax": 34.30,
    "lngMin": 7.50,
    "lngMax": 8.60,
  },
  {
    "name": "KEBILI",
    "zone": "SUD_OUEST",
    "latMin": 32.80,
    "latMax": 33.90,
    "lngMin": 7.30,
    "lngMax": 9.30,
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
