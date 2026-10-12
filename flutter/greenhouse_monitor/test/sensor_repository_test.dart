import 'package:flutter_test/flutter_test.dart';
import 'package:greenhouse_monitor/src/sensor_repository.dart';

import 'test_support.dart';

void main() {
  test('sync loads sensors and the full retention window', () async {
    final repository = SensorRepository(api: makeApi());

    await repository.sync();

    expect(repository.sensors.map((s) => s.id), ['s-1', 's-2', 's-3']);
    expect(repository.readingsFor('s-1'), hasLength(readingsPerSensor));
    expect(repository.lastError, isNull);
  });

  test('concurrent syncs share one in-flight request', () async {
    final repository = SensorRepository(api: makeApi(latency: const Duration(milliseconds: 10)));

    await Future.wait([repository.sync(), repository.sync()]);

    final ids = repository.readingsFor('s-1').map((r) => r.id).toList();
    expect(ids, hasLength(readingsPerSensor));
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('readings are returned newest first', () async {
    final repository = SensorRepository(api: makeApi());

    await repository.sync();

    final readings = repository.readingsFor('s-2');
    expect(readings.first.timestamp.isAfter(readings.last.timestamp), isTrue);
    expect(repository.latestFor('s-2')?.id, readings.first.id);
  });
}
