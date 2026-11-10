import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../services/weather_database.dart';

class WeatherEditor extends StatefulWidget {
  const WeatherEditor({super.key, this.weather});

  final WeatherType? weather;

  @override
  State<WeatherEditor> createState() => _WeatherEditorState();
}

class _WeatherEditorState extends State<WeatherEditor> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _humidity;
  late final TextEditingController _pressure;
  late final TextEditingController _uv;
  late final TextEditingController _rain;

  late bool _sunny;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final weather = widget.weather;

    _sunny = weather == null || weather is Sunny;
    _title = TextEditingController(text: weather?.title ?? '');
    _humidity = TextEditingController(
      text: '${weather?.humidity ?? 50}',
    );
    _pressure = TextEditingController(
      text: '${weather?.pressure ?? 1013}',
    );
    _uv = TextEditingController(
      text: '${weather?.uvIndex ?? 3}',
    );
    _rain = TextEditingController(
      text: '${weather?.precipitation ?? 2}',
    );
  }

  @override
  void dispose() {
    for (final controller in [_title, _humidity, _pressure, _uv, _rain]) {
      controller.dispose();
    }

    super.dispose();
  }

  double? _number(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required double min,
    required double max,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (text) {
          final value = _number(text ?? '');

          if (value == null || !value.isFinite) {
            return 'Enter a valid number';
          }

          if (value < min || value > max) {
            return 'Allowed from $min to $max';
          }

          return null;
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final WeatherType weather;

      if (_sunny) {
        weather = Sunny(
          id: widget.weather?.id,
          title: _title.text.trim(),
          humidity: _number(_humidity.text)!,
          pressure: _number(_pressure.text)!,
          uvIndex: _number(_uv.text)!,
        );
      } else {
        weather = Rainy(
          id: widget.weather?.id,
          title: _title.text.trim(),
          humidity: _number(_humidity.text)!,
          pressure: _number(_pressure.text)!,
          precipitation: _number(_rain.text)!,
        );
      }

      final saved = await WeatherDatabase.instance.save(weather);

      if (!mounted) return;

      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.weather == null ? 'Adding Weather' : 'Editing Weather',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              enabled: !_saving,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (text) {
                if (text == null || text.trim().isEmpty) {
                  return 'Enter a title';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<bool>(
              initialValue: _sunny,
              decoration: const InputDecoration(
                labelText: 'Weather type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: true,
                  child: Text('Sunny'),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text('Rainy'),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _sunny = value);
                      }
                    },
            ),
            const SizedBox(height: 16),
            _numberField(
              controller: _humidity,
              label: 'Humidity, %',
              min: 0,
              max: 100,
            ),
            _numberField(
              controller: _pressure,
              label: 'Pressure, hPa',
              min: 1,
              max: 2000,
            ),
            if (_sunny)
              _numberField(
                controller: _uv,
                label: 'UV-index',
                min: 0,
                max: 20,
              )
            else
              _numberField(
                controller: _rain,
                label: 'Precipitation, mm',
                min: 0,
                max: 1000,
              ),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}