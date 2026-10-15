import 'package:flutter/material.dart';

import 'formatting.dart';
import 'models.dart';
import 'sensor_repository.dart';
import 'moisture_threshold_page.dart';

class SensorDetailPage extends StatelessWidget {
  const SensorDetailPage({
    super.key,
    required this.sensor,
    required this.repository,
  });

  final Sensor sensor;
  final SensorRepository repository;

  Widget rangeColumn({required num value, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toInt().toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget moistureThresholdHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Moisture thresholds(%)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MoistureThresholdPage(
                    initialMin: 10,
                    initialMax: 90,
                    onSave: (value) {},
                  ),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

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
                moistureThresholdHeader(context),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      rangeColumn(value: 10, label: 'Min'),
                      Text('-', style: Theme.of(context).textTheme.titleSmall),
                      rangeColumn(value: 90, label: 'Max'),
                    ],
                  ),
                ),

                if (latest == null)
                  const ListTile(title: Text('No readings yet'))
                else ...[
                  ListTile(
                    title: const Text('Soil moisture'),
                    trailing: Text(formatPercent(latest.soilMoisture)),
                  ),
                  ListTile(
                    title: const Text('Temperature'),
                    trailing: Text(formatCelsius(latest.temperature)),
                  ),
                  ListTile(
                    title: const Text('Humidity'),
                    trailing: Text(formatPercent(latest.humidity)),
                  ),
                ],
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'History (${readings.length})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                for (final reading in readings)
                  ListTile(
                    dense: true,
                    leading: Text(formatTime(reading.timestamp)),
                    title: Text(
                      '${formatPercent(reading.soilMoisture)} · ${formatCelsius(reading.temperature)}',
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
