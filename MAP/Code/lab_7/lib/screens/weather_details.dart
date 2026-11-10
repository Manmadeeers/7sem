import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../services/weather_database.dart';
import 'files_screen.dart';
import 'weather_editor.dart';

class WeatherDetails extends StatefulWidget {
  const WeatherDetails({super.key, required this.weather});

  final WeatherType weather;

  @override
  State<WeatherDetails> createState() => _WeatherDetailsState();
}

class _WeatherDetailsState extends State<WeatherDetails> {
  late WeatherType _weather;

  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _weather = widget.weather;
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<WeatherType>(
      MaterialPageRoute(
        builder: (_) => WeatherEditor(weather: _weather),
      ),
    );

    if (mounted && updated != null) {
      setState(() => _weather = updated);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text(_weather.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      await WeatherDatabase.instance.delete(_weather.id!);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => _deleting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather Information')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(
            _weather is Sunny ? Icons.wb_sunny : Icons.water_drop,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          SelectableText(
            _weather.details,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _deleting ? null : _edit,
            icon: const Icon(Icons.edit),
            label: const Text('Change'),
          ),
          OutlinedButton.icon(
            onPressed: _deleting
                ? null
                : () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => FilesScreen(weather: _weather),
                      ),
                    );
                  },
            icon: const Icon(Icons.folder_open),
            label: const Text('Files and Isolates'),
          ),
          TextButton.icon(
            onPressed: _deleting ? null : _delete,
            icon: const Icon(Icons.delete),
            label: Text(_deleting ? 'Deleting...' : 'Delete'),
          ),
        ],
      ),
    );
  }
}