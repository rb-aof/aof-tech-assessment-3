import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:greenhouse_monitor/src/models.dart';
import 'package:greenhouse_monitor/src/moisture_threshold_handler.dart';

class MoistureThresholdPage extends StatefulWidget {
  final ValueChanged<MoistureThreshold?> onSave;
  final MoistureThreshold initialThreshold;

  const MoistureThresholdPage({
    super.key,
    required this.initialThreshold,
    required this.onSave,
  });

  @override
  State<MoistureThresholdPage> createState() => _MoistureThresholdPageState();
}

class _MoistureThresholdPageState extends State<MoistureThresholdPage> {
  static const green = Colors.green;

  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(
      text: widget.initialThreshold.minMoisture.toString(),
    );
    _maxController = TextEditingController(
      text: widget.initialThreshold.maxMoisture.toString(),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _clearRange() {
    setState(() {
      _minController.clear();
      _maxController.clear();
    });
  }

  void _save() {
    final min = int.tryParse(_minController.text) ?? 0;
    final max = int.tryParse(_maxController.text) ?? 0;

    MoistureThreshold threshold = MoistureThreshold(
      minMoisture: min,
      maxMoisture: max,
      sensorId: widget.initialThreshold.sensorId,
    );

    if (threshold.isValid() == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter values between 0 and 100, with minimum no greater than maximum.',
          ),
        ),
      );
      return;
    }

    MoistureThresholdHandler().save(threshold);

    widget.onSave(threshold);

    Navigator.of(context).pop();
  }

  Widget _thresholdField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 18, color: Colors.black)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 28, color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFFD6D6D6),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: green, width: 1.5),
            ),
          ),
          onChanged: (_) {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ),
        title: const Text(
          'Moisture thresholds',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 48, 8, 24),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                'Set the acceptable soil-moisture range for '
                'this sensor.',
                style: TextStyle(fontSize: 18, height: 1.4, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 14),

            // Threshold input card
            Padding(
              padding: const EdgeInsets.fromLTRB(23, 30, 23, 30),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _thresholdField(
                    label: 'Minimum (%)',
                    controller: _minController,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Divider(height: 1, color: Color(0xFFE5E5E5)),
                  ),
                  _thresholdField(
                    label: 'Maximum (%)',
                    controller: _maxController,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 54),

            // Clear range button
            SizedBox(
              height: 76,
              child: FilledButton(
                onPressed: _clearRange,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 34,
                    ),
                    SizedBox(width: 22),
                    Text(
                      'Clear range',
                      style: TextStyle(fontSize: 20, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
