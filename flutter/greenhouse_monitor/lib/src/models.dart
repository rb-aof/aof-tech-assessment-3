/// A soil/air sensor installed somewhere in the greenhouse.
class Sensor {
  const Sensor({
    required this.id,
    required this.name,
    required this.zone,
    required this.plant,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) => Sensor(
        id: json['id'] as String,
        name: json['name'] as String,
        zone: json['zone'] as String,
        plant: json['plant'] as String,
      );

  final String id;
  final String name;
  final String zone;
  final String plant;
}

/// A single measurement reported by a sensor.
class Reading {
  const Reading({
    required this.id,
    required this.sensorId,
    required this.timestamp,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
  });

  final String id;
  final String sensorId;
  final DateTime timestamp;

  /// Volumetric soil moisture, 0–100 %.
  final double soilMoisture;

  /// Air temperature in °C.
  final double temperature;

  /// Relative air humidity, 0–100 %.
  final double humidity;
}
