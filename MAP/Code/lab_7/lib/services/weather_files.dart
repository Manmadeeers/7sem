import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/weather.dart';

enum DirectoryKind {
  temporary('Temporary'),
  support('Application Support'),
  library('Application Library'),
  documents('Application Documents'),
  cache('Application Cache'),
  externalStorage('External Storage'),
  externalCaches('External Cache Directories'),
  externalStorages('External Storage Directories'),
  downloads('Downloads');

  const DirectoryKind(this.label);

  final String label;
}

const _platformNames = {
  'android': 'Android',
  'ios': 'iOS',
  'linux': 'Linux',
  'macos': 'macOS',
  'windows': 'Windows',
};

Set<String> _supportedPlatforms(DirectoryKind kind) {
  return switch (kind) {
    DirectoryKind.library => {'ios', 'macos'},
    DirectoryKind.externalStorage ||
    DirectoryKind.externalCaches ||
    DirectoryKind.externalStorages =>
      {'android'},
    _ => _platformNames.keys.toSet(),
  };
}

String get currentPlatform {
  return _platformNames[Platform.operatingSystem] ??
      Platform.operatingSystem;
}

class StoredFile {
  const StoredFile({
    required this.path,
    this.bytes = 0,
    this.content,
    this.error,
  });

  final String path;
  final int bytes;
  final String? content;
  final String? error;
}

class DirectoryReport {
  const DirectoryReport({
    required this.name,
    this.root,
    this.folder,
    this.worker,
    this.files = const [],
    this.error,
  });

  final String name;
  final String? root;
  final String? folder;
  final String? worker;
  final List<StoredFile> files;
  final String? error;
}

class _WorkerResult {
  const _WorkerResult({
    required this.worker,
    required this.files,
  });

  final String worker;
  final List<StoredFile> files;
}

Future<List<Directory>> _single(Future<Directory?> future) async {
  final directory = await future;
  return directory == null ? [] : [directory];
}

Future<List<Directory>> _getRoots(DirectoryKind kind) async {
  final supported = _supportedPlatforms(kind);

  if (!supported.contains(Platform.operatingSystem)) {
    final unsupported = _platformNames.entries
        .where((entry) => !supported.contains(entry.key))
        .map((entry) => entry.value)
        .join(', ');

    throw UnsupportedError(
      '${kind.label} is not supported on platforms: $unsupported. '
      'Current platform: $currentPlatform.',
    );
  }

  final List<Directory> directories = switch (kind) {
    DirectoryKind.temporary => await _single(getTemporaryDirectory()),
    DirectoryKind.support =>
      await _single(getApplicationSupportDirectory()),
    DirectoryKind.library => await _single(getLibraryDirectory()),
    DirectoryKind.documents =>
      await _single(getApplicationDocumentsDirectory()),
    DirectoryKind.cache => await _single(getApplicationCacheDirectory()),
    DirectoryKind.externalStorage =>
      await _single(getExternalStorageDirectory()),
    DirectoryKind.externalCaches =>
      await getExternalCacheDirectories() ?? <Directory>[],
    DirectoryKind.externalStorages =>
      await getExternalStorageDirectories(
            type: StorageDirectory.documents,
          ) ??
          <Directory>[],
    DirectoryKind.downloads => await _single(getDownloadsDirectory()),
  };

  if (directories.isEmpty) {
    throw FileSystemException(
      '${kind.label}: at $currentPlatform path is missing '
      'or the storage is currently unavailable.',
    );
  }

  return directories;
}

Future<_WorkerResult> _runFileJob(
  String folder,
  Map<String, Object?>? entity,
) {
  return Isolate.run(
    () => _fileJob(folder, entity),
    debugName: 'weather-file-worker',
  );
}

_WorkerResult _fileJob(
  String folder,
  Map<String, Object?>? entity,
) {
  final directory = Directory(folder);

  if (entity != null) {
    directory.createSync(recursive: true);

    final file = File(p.join(folder, 'weather.json'));

    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(entity),
      flush: true,
    );
  }

  final results = <StoredFile>[];

  if (directory.existsSync()) {
    final files = directory
        .listSync(followLinks: false)
        .whereType<File>()
        .where((file) => p.extension(file.path) == '.json')
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      try {
        final content = file.readAsStringSync();
        final bytes = file.lengthSync();

        results.add(
          StoredFile(
            path: file.path,
            bytes: bytes,
            content: content,
          ),
        );
      } catch (error) {
        results.add(
          StoredFile(
            path: file.path,
            error: 'Read error $currentPlatform: $error',
          ),
        );
      }
    }
  }

  return _WorkerResult(
    worker: '${Isolate.current.debugName ?? "worker"} '
        '#${Isolate.current.hashCode}',
    files: results,
  );
}

class WeatherFiles {
  static String _errorText(DirectoryKind kind, Object error) {
    return '${kind.label}. Platform: $currentPlatform.\n$error';
  }

  static Future<List<DirectoryReport>> inspectAll({
    required WeatherType source,
    required bool write,
  }) async {
    final reports = <DirectoryReport>[];

    for (final kind in DirectoryKind.values) {
      final List<Directory> roots;

      try {

        roots = await _getRoots(kind);
      } catch (error) {
        reports.add(
          DirectoryReport(
            name: kind.label,
            error: _errorText(kind, error),
          ),
        );
        continue;
      }

      for (var index = 0; index < roots.length; index++) {
        final root = roots[index].path;

        final folder = p.join(
          root,
          'lab7',
          kind.name,
          'volume_$index',
        );

        final name = roots.length == 1
            ? kind.label
            : '${kind.label} — storage ${index + 1}';

        try {
          Map<String, Object?>? entity;

          if (write) {
            entity = {
              ...source.toMap(),
              'id': null,
              'title': '${source.title} — ${kind.label} #${index + 1}',
              'humidity': (
                source.humidity + kind.index + index + 1
              ) % 101,
            };
          }

          final result = await _runFileJob(folder, entity);

          reports.add(
            DirectoryReport(
              name: name,
              root: root,
              folder: folder,
              worker: result.worker,
              files: result.files,
            ),
          );
        } catch (error) {
          reports.add(
            DirectoryReport(
              name: name,
              root: root,
              folder: folder,
              error: _errorText(kind, error),
            ),
          );
        }
      }
    }

    return reports;
  }
}