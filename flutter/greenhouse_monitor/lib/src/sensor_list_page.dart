import 'package:flutter/material.dart';

import 'formatting.dart';
import 'models.dart';
import 'sensor_detail_page.dart';
import 'sensor_repository.dart';

class SensorListPage extends StatefulWidget {
  const SensorListPage({super.key, required this.repository});

  final SensorRepository repository;

  @override
  State<SensorListPage> createState() => _SensorListPageState();
}

class _SensorListPageState extends State<SensorListPage> {
  @override
  void initState() {
    super.initState();
    widget.repository.sync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Greenhouse')),
      body: ListenableBuilder(
        listenable: widget.repository,
        builder: (context, _) {
          final repository = widget.repository;
          if (repository.sensors.isEmpty) {
            return Center(
              child: repository.isSyncing
                  ? const CircularProgressIndicator()
                  : const Text('No sensors'),
            );
          }

          final zones = <String, List<Sensor>>{};
          for (final sensor in repository.sensors) {
            zones.putIfAbsent(sensor.zone, () => []).add(sensor);
          }
          final sortedZones = zones.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: repository.sync,
            child: ListView(
              children: [
                if (repository.lastError != null)
                  ListTile(
                    leading: const Icon(Icons.warning_amber, color: Colors.orange),
                    title: Text('Sync failed: ${repository.lastError}'),
                  ),
                for (final zone in sortedZones) ...[
                  _ZoneHeader(zone),
                  for (final sensor in zones[zone]!..sort((a, b) => a.name.compareTo(b.name)))
                    _SensorTile(sensor: sensor, repository: repository),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ZoneHeader extends StatelessWidget {
  const _ZoneHeader(this.zone);

  final String zone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(zone.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _SensorTile extends StatelessWidget {
  const _SensorTile({required this.sensor, required this.repository});

  final Sensor sensor;
  final SensorRepository repository;

  @override
  Widget build(BuildContext context) {
    final latest = repository.latestFor(sensor.id);
    return ListTile(
      title: Text(sensor.name),
      subtitle: Text(
        latest == null
            ? '${sensor.plant} · No readings yet'
            : '${sensor.plant} · ${formatPercent(latest.soilMoisture)} · ${formatCelsius(latest.temperature)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SensorDetailPage(sensor: sensor, repository: repository),
        ),
      ),
    );
  }
}
