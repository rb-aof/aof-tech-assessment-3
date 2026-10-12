import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/mock_greenhouse_api.dart';
import 'src/sensor_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = SensorRepository(api: MockGreenhouseApi.fromAssets());
  runApp(GreenhouseApp(repository: repository));
}
