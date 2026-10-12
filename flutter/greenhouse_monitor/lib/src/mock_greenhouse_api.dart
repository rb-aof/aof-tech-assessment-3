import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'models.dart';

/// Remote API for the greenhouse backend.
abstract interface class GreenhouseApi {
  Future<List<Sensor>> fetchSensors();

  /// Readings for [sensorId] strictly newer than [since], oldest first.
  Future<List<Reading>> fetchReadings(String sensorId, {DateTime? since});
}

/// In-process fake of the greenhouse backend. Readings are generated
/// deterministically from the sensor id and time slot (one per minute, two
/// hours of retention), so repeated calls return the same data.
class MockGreenhouseApi implements GreenhouseApi {
  MockGreenhouseApi({
    required Future<List<Sensor>> Function() loadSensors,
    this.latency = const Duration(milliseconds: 500),
    DateTime Function()? now,
  })  : _loadSensors = loadSensors,
        _now = now ?? DateTime.now;

  factory MockGreenhouseApi.fromAssets({Duration latency = const Duration(milliseconds: 500)}) {
    return MockGreenhouseApi(
      latency: latency,
      loadSensors: () async {
        final json = await rootBundle.loadString('assets/sensors.json');
        return (jsonDecode(json) as List<dynamic>)
            .map((e) => Sensor.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  static const readingInterval = Duration(minutes: 1);
  static const retentionWindow = Duration(hours: 2);

  final Duration latency;
  final Future<List<Sensor>> Function() _loadSensors;
  final DateTime Function() _now;
  List<Sensor>? _sensors;

  @override
  Future<List<Sensor>> fetchSensors() async {
    await Future<void>.delayed(latency);
    return _sensors ??= await _loadSensors();
  }

  @override
  Future<List<Reading>> fetchReadings(String sensorId, {DateTime? since}) async {
    await Future<void>.delayed(latency);
    final sensors = _sensors ??= await _loadSensors();
    if (!sensors.any((s) => s.id == sensorId)) {
      throw ArgumentError.value(sensorId, 'sensorId', 'Unknown sensor');
    }

    final intervalMs = readingInterval.inMilliseconds;
    final lastSlot = _now().millisecondsSinceEpoch ~/ intervalMs;
    final slotCount = retentionWindow.inMilliseconds ~/ intervalMs;

    return [
      for (var slot = lastSlot - slotCount + 1; slot <= lastSlot; slot++) _reading(sensorId, slot),
    ].where((r) => since == null || r.timestamp.isAfter(since)).toList();
  }

  static Reading _reading(String sensorId, int slot) {
    final sensorHash = _stableHash(sensorId);
    final random = Random(sensorHash ^ slot);
    final baseline = 20 + (sensorHash % 55);
    final phase = slot / 15;

    double jitter(double amount) => (random.nextDouble() * 2 - 1) * amount;

    return Reading(
      id: '$sensorId-$slot',
      sensorId: sensorId,
      timestamp: DateTime.fromMillisecondsSinceEpoch(slot * readingInterval.inMilliseconds),
      soilMoisture: (baseline + 6 * sin(phase) + jitter(1.5)).clamp(0, 100).toDouble(),
      temperature: 21 + 3 * sin(phase / 4) + jitter(0.4),
      humidity: (60 + 10 * cos(phase / 3) + jitter(2)).clamp(0, 100).toDouble(),
    );
  }

  /// Small FNV-style hash kept within 31 bits so it is stable on every platform.
  static int _stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }
}
