String formatPercent(double value) => '${value.round()}%';

String formatCelsius(double value) => '${value.toStringAsFixed(1)} °C';

String formatTime(DateTime time) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
}
