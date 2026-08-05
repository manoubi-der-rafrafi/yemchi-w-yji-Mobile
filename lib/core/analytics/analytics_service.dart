import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yemchi_wyji/core/env.dart';
import 'package:yemchi_wyji/core/storage/token_storage.dart';

class AnalyticsService {
  static const _installationKey = 'analytics_installation_id';
  static final String _sessionId = _newId('session');

  static Future<void> track(
    String eventName, {
    Map<String, Object?> metadata = const {},
    String? page,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var installationId = prefs.getString(_installationKey);
      if (installationId == null || installationId.isEmpty) {
        installationId = _newId('installation');
        await prefs.setString(_installationKey, installationId);
      }

      final token = await TokenStorage.access();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      await http.post(
        Uri.parse('${Env.baseUrl}/analytics/events'),
        headers: headers,
        body: jsonEncode({
          'installationId': installationId,
          'sessionId': _sessionId,
          'eventName': eventName,
          'platform': 'mobile_driver',
          'page': page,
          'deviceType': defaultTargetPlatform.name,
          'appVersion': '1.0.0',
          'metadata': metadata,
        }),
      );
    } catch (error) {
      if (kDebugMode) debugPrint('[Analytics] event ignored: $error');
    }
  }

  static String _newId(String prefix) {
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$random';
  }
}
