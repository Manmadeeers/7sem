import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:weather_lab/services/weather_files.dart';

import '../models/weather.dart';
import '../services/weather_files.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key, required this.weather});

  final WeatherType weather;

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<DirectoryReport> _reports = [];

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run(false);
  }

  Future<void> _run(bool write) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final reports = await WeatherFiles.inspectAll(
        source: widget.weather,
        write: write,
      );

      if (!mounted) return;

      setState(() => _reports = reports);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = 'Error on $currentPlatform: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _fileText(StoredFile file) {
    if (file.error != null) {
      return 'File: ${file.path}\n${file.error}';
    }

    String entityText;

    try {
      final decoded = jsonDecode(file.content!);
      final map = Map<String, Object?>.from(decoded as Map);
      final weather = WeatherType.fromMap(map);

      entityText = weather.details;
    } catch (error) {
      entityText = 'Format error of the entity: $error';
    }

    return 'Existing file:\n${file.path}\n\n'
        'Size: ${file.bytes} bytes\n\n'
        'Read entity:\n$entityText\n\n'
        'Read JSON:\n${file.content}';
  }

  Widget _reportCard(DirectoryReport report) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        key: ValueKey(report.name),
        initiallyExpanded: report.error != null,
        leading: Icon(
          report.error == null ? Icons.folder : Icons.error_outline,
        ),
        title: Text(report.name),
        subtitle: Text(
          report.error != null
              ? 'Not available / error'
              : 'Files found: ${report.files.length}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (report.root != null)
                  SelectableText(
                    'Directory path_provider:\n${report.root}\n',
                  ),
                if (report.folder != null)
                  SelectableText(
                    'Subfolder of the laboratory:\n${report.folder}\n',
                  ),
                if (report.worker != null)
                  SelectableText(
                    'Files operations performed by isolate:\n'
                    '${report.worker}\n',
                  ),
                if (report.error != null)
                  SelectableText(
                    report.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (report.error == null && report.files.isEmpty)
                  const Text(
                    'No existing JSON files found. '
                    'Press "Write copies".',
                  ),
                for (final file in report.files) ...[
                  const Divider(),
                  SelectableText(_fileText(file)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainIsolate = Isolate.current.debugName ?? 'main';

    return Scaffold(
      appBar: AppBar(title: const Text('Files and isolates')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Platform: $currentPlatform'),
                Text(
                  'Interface isolate: $mainIsolate '
                  '#${Isolate.current.hashCode}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Source: ${widget.weather.title}\n'
                  'When writing, a copy with a different name and humidity is created '
                  'for each directory.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _run(true),
                      icon: const Icon(Icons.save),
                      label: const Text('Write copies'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _run(false),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Read / update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(_error!),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                return _reportCard(_reports[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}