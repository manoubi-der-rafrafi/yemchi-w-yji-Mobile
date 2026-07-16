import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:yemchi_wyji/core/network/api.dart';

class PresenceService {
  PresenceService(
    this._api, {
    Duration interval = const Duration(seconds: 25),
  }) : _interval = interval;

  final Api _api;
  final Duration _interval;

  Timer? _timer;
  String? _userId;

  bool get isRunning => _timer?.isActive ?? false;

  Future<void> start(String userId) async {
    if (userId.isEmpty) return;
    _userId = userId;
    _timer?.cancel();
    await _sendHeartbeat();
    _timer = Timer.periodic(_interval, (_) => _sendHeartbeat());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<bool> isOnline(String userId) async {
    final r = await _api.get('/presence/$userId');
    final data = json.decode(r.body);
    if (data is Map && data['online'] is bool) {
      return data['online'] as bool;
    }
    throw ApiException(r.statusCode, 'Format de réponse inattendu');
  }

  Future<void> _sendHeartbeat() async {
    if (_userId == null || _userId!.isEmpty) return;
    try {
      await _api.post('/presence/heartbeat');
    } catch (e) {
      debugPrint('Presence heartbeat failed: $e');
    }
  }
}
