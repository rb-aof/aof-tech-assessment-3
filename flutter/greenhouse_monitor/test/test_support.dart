import 'package:greenhouse_monitor/src/mock_greenhouse_api.dart';
import 'package:greenhouse_monitor/src/models.dart';

final fixedNow = DateTime.utc(2026, 1, 15, 12);

const testSensors = [
  Sensor(id: 's-1', name: 'Bench 1', zone: 'North', plant: 'Basil'),
  Sensor(id: 's-2', name: 'Bench 2', zone: 'North', plant: 'Mint'),
  Sensor(id: 's-3', name: 'Pot 1', zone: 'South', plant: 'Aloe'),
];

final readingsPerSensor =
    MockGreenhouseApi.retentionWindow.inMinutes ~/ MockGreenhouseApi.readingInterval.inMinutes;

MockGreenhouseApi makeApi({Duration latency = Duration.zero, DateTime? now}) {
  return MockGreenhouseApi(
    loadSensors: () async => testSensors,
    latency: latency,
    now: () => now ?? fixedNow,
  );
}
