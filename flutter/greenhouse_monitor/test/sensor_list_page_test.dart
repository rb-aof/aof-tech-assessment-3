import 'package:flutter_test/flutter_test.dart';
import 'package:greenhouse_monitor/src/app.dart';
import 'package:greenhouse_monitor/src/sensor_repository.dart';

import 'test_support.dart';

void main() {
  testWidgets('shows sensors grouped by zone and opens the detail page', (tester) async {
    await tester.pumpWidget(GreenhouseApp(repository: SensorRepository(api: makeApi())));
    await tester.pumpAndSettle();

    expect(find.text('NORTH'), findsOneWidget);
    expect(find.text('SOUTH'), findsOneWidget);
    expect(find.text('Bench 1'), findsOneWidget);

    await tester.tap(find.text('Pot 1'));
    await tester.pumpAndSettle();

    expect(find.text('Soil moisture'), findsOneWidget);
    expect(find.text('History ($readingsPerSensor)'), findsOneWidget);
  });
}
