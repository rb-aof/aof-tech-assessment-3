import 'package:flutter/material.dart';

import 'formatting.dart';
import 'models.dart';
import 'sensor_repository.dart';

class SensorDetailPage extends StatelessWidget {
  const SensorDetailPage({super.key, required this.sensor, required this.repository});

  final Sensor sensor;
  final SensorRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(sensor.name)),
      body: ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          final readings = repository.readingsFor(sensor.id);
          final latest = readings.firstOrNull;
          return RefreshIndicator(
            onRefresh: repository.sync,
            child: ListView(
              children: [
                if (latest == null)
                  const ListTile(title: Text('No readings yet'))
                else ...[
                  ListTile(title: const Text('Soil moisture'), trailing: Text(formatPercent(latest.soilMoisture))),
                  ListTile(title: const Text('Temperature'), trailing: Text(formatCelsius(latest.temperature))),
                  ListTile(title: const Text('Humidity'), trailing: Text(formatPercent(latest.humidity))),
                ],
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('History (${readings.length})', style: Theme.of(context).textTheme.titleSmall),
                ),
                for (final reading in readings)
                  ListTile(
                    dense: true,
                    leading: Text(formatTime(reading.timestamp)),
                    title: Text('${formatPercent(reading.soilMoisture)} · ${formatCelsius(reading.temperature)}'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
