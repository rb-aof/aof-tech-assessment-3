import 'package:flutter/material.dart';
import 'package:greenhouse_monitor/src/moisture_threshold_handler.dart';

import 'formatting.dart';
import 'models.dart';
import 'sensor_repository.dart';
import 'moisture_threshold_page.dart';

class SensorDetailPage extends StatefulWidget {
  const SensorDetailPage({
    super.key,
    required this.sensor,
    required this.repository,
  });

  final Sensor sensor;
  final SensorRepository repository;

  @override
  State<SensorDetailPage> createState() => _SensorDetailPageState();
}

class _SensorDetailPageState extends State<SensorDetailPage> {
  final handler = MoistureThresholdHandler();
  late MoistureThreshold moistureThreshold;

  @override
  void initState() {
    super.initState();
    moistureThreshold = MoistureThreshold(sensorId: widget.sensor.id);
    _loadThreshold();
  }

  Future<void> _loadThreshold() async {
    final value = await handler.load(widget.sensor.id);

    if (!mounted || value == null) return;

    setState(() {
      moistureThreshold = value;
    });
  }

  bool isLatestReadingOutOfRange() {
    final latest = widget.repository.latestFor(widget.sensor.id);
    if (latest == null) return false;
    return !moistureThreshold.isEmpty() &&
        (latest.soilMoisture < moistureThreshold.minMoisture ||
            latest.soilMoisture > moistureThreshold.maxMoisture);
  }

  String remindText() {
    final latest = widget.repository.latestFor(widget.sensor.id);
    if (latest == null) return "";
    if (!moistureThreshold.isEmpty() &&
        latest.soilMoisture < moistureThreshold.minMoisture) {
      return '${widget.sensor.name}, soil moisture ${formatPercent(latest.soilMoisture)}, below minimum of ${moistureThreshold.minMoisture}';
    }
    if (!moistureThreshold.isEmpty() &&
        latest.soilMoisture > moistureThreshold.maxMoisture) {
      return '${widget.sensor.name}, soil moisture ${formatPercent(latest.soilMoisture)}, above maximum of ${moistureThreshold.maxMoisture}';
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sensor.name)),
      body: ListenableBuilder(
        listenable: widget.repository,
        builder: (context, _) {
          final readings = widget.repository.readingsFor(widget.sensor.id);
          final latest = readings.firstOrNull;
          return RefreshIndicator(
            onRefresh: widget.repository.sync,
            child: ListView(
              children: [
                isLatestReadingOutOfRange()
                    ? ListTile(
                        leading: const Icon(
                          Icons.warning_amber,
                          color: Colors.red,
                        ),
                        title: Semantics(
                          label: 'Latest reading is out of range',
                          child: Text(
                            remindText(),
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                moistureThresholdHeader(context),
                moistureThreshold.isEmpty()
                    ? const SizedBox.shrink()
                    : Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey[100],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            rangeColumn(
                              value: moistureThreshold.minMoisture,
                              label: 'Min',
                            ),
                            Text(
                              '-',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            rangeColumn(
                              value: moistureThreshold.maxMoisture,
                              label: 'Max',
                            ),
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
                    initialThreshold: moistureThreshold,
                    onSave: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        moistureThreshold = value;
                      });
                    },
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
}
