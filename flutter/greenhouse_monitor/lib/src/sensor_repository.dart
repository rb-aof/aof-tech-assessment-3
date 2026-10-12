import 'package:flutter/foundation.dart';

import 'mock_greenhouse_api.dart';
import 'models.dart';

/// In-memory cache of sensors and readings, kept in sync with [GreenhouseApi].
class SensorRepository extends ChangeNotifier {
  SensorRepository({required GreenhouseApi api}) : _api = api;

  final GreenhouseApi _api;
  final Map<String, List<Reading>> _readings = {};
  List<Sensor> _sensors = const [];
  Future<void>? _inFlightSync;
  Object? _lastError;

  List<Sensor> get sensors => _sensors;
  bool get isSyncing => _inFlightSync != null;
  Object? get lastError => _lastError;

  /// Newest first.
  List<Reading> readingsFor(String sensorId) =>
      (_readings[sensorId] ?? const <Reading>[]).reversed.toList(growable: false);

  Reading? latestFor(String sensorId) => _readings[sensorId]?.lastOrNull;

  /// Fetches sensors and any new readings. Concurrent callers share the same
  /// in-flight sync.
  Future<void> sync() {
    return _inFlightSync ??= _performSync().whenComplete(() {
      _inFlightSync = null;
      notifyListeners();
    });
  }

  Future<void> _performSync() async {
    notifyListeners();
    try {
      _sensors = await _api.fetchSensors();
      notifyListeners();
      for (final sensor in _sensors) {
        final existing = _readings[sensor.id] ?? <Reading>[];
        final fresh = await _api.fetchReadings(sensor.id, since: existing.lastOrNull?.timestamp);
        _readings[sensor.id] = [...existing, ...fresh];
        notifyListeners();
      }
      _lastError = null;
    } catch (error) {
      _lastError = error;
    }
  }
}
