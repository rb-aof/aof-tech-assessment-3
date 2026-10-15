import 'dart:convert';

import 'package:greenhouse_monitor/src/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoistureThresholdHandler {
  final SharedPreferencesAsync _preferences;

  static const String _storageKey = 'moistureThreshold_';

  MoistureThresholdHandler({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  String _keyFor(String sensorId) {
    return '$_storageKey$sensorId';
  }

  Future<MoistureThreshold?> load(String sensorId) async {
    final savedString = await _preferences.getString(_keyFor(sensorId));

    if (savedString == null) {
      return null;
    }

    try {
      final json = jsonDecode(savedString) as Map<String, dynamic>;
      return MoistureThreshold.fromJson(json);
    } catch (error) {
      print('Failed to decode moisture threshold: $error');
      return null;
    }
  }

  Future<void> save(MoistureThreshold threshold) async {
    if (!threshold.isValid()) {
      return;
    }

    final savedString = jsonEncode(threshold.toJson());

    await _preferences.setString(_keyFor(threshold.sensorId), savedString);
  }

  Future<void> clear(MoistureThreshold threshold) async {
    await _preferences.remove(_keyFor(threshold.sensorId));
  }
}
