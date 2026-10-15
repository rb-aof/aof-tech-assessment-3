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

class MoistureThreshold {
  const MoistureThreshold({
    this.minMoisture = 0,
    this.maxMoisture = 0,
    required this.sensorId,
  });

  final int minMoisture;
  final int maxMoisture;
  final String sensorId;

  bool isValid() =>
      minMoisture >= 0 && maxMoisture <= 100 && minMoisture <= maxMoisture;

  bool isEmpty() => minMoisture == 0 && maxMoisture == 0;

  factory MoistureThreshold.fromJson(Map<String, dynamic> json) =>
      MoistureThreshold(
        minMoisture: json['min_moisture'] as int,
        maxMoisture: json['max_moisture'] as int,
        sensorId: json['sensor_id'] as String,
      );

  Map<String, dynamic> toJson() => {
    'min_moisture': minMoisture,
    'max_moisture': maxMoisture,
    'sensor_id': sensorId,
  };
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
