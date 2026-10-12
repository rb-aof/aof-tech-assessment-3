import 'package:flutter/material.dart';

import 'sensor_list_page.dart';
import 'sensor_repository.dart';

class GreenhouseApp extends StatelessWidget {
  const GreenhouseApp({super.key, required this.repository});

  final SensorRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Greenhouse',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF339E61), useMaterial3: true),
      home: SensorListPage(repository: repository),
    );
  }
}
