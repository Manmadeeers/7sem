import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/weather.dart';

class WeatherDatabase {
  WeatherDatabase._();

  static final instance = WeatherDatabase._();

  Future<Database>? _opening;

  Future<Database> get _database => _opening ??= _open();

  Future<Database> _open() async {
    final directory = await getDatabasesPath();

    return openDatabase(
      p.join(directory, 'weather_lab7.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE weather (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kind TEXT NOT NULL CHECK(kind IN ('sunny', 'rainy')),
            title TEXT NOT NULL,
            humidity REAL NOT NULL CHECK(humidity BETWEEN 0 AND 100),
            pressure REAL NOT NULL CHECK(pressure > 0),
            uv_index REAL,
            precipitation REAL,
            CHECK(
              (kind = 'sunny'
                AND uv_index IS NOT NULL
                AND precipitation IS NULL)
              OR
              (kind = 'rainy'
                AND precipitation IS NOT NULL
                AND uv_index IS NULL)
            )
          )
        ''');

        const initial = <WeatherType>[
          Sunny(
            title: 'Солнечное утро',
            humidity: 35,
            pressure: 1013,
            uvIndex: 3,
          ),
          Rainy(
            title: 'Осенний дождь',
            humidity: 90,
            pressure: 995,
            precipitation: 12,
          ),
          Sunny(
            title: 'Жаркий полдень',
            humidity: 20,
            pressure: 1018,
            uvIndex: 9,
          ),
        ];

        for (final weather in initial) {
          final values = weather.toMap()..remove('id');
          await db.insert('weather', values);
        }
      },
    );
  }

  Future<List<WeatherType>> getAll() async {
    final db = await _database;
    final rows = await db.query('weather', orderBy: 'id ASC');

    return rows.map(WeatherType.fromMap).toList();
  }

  Future<WeatherType> save(WeatherType weather) async {
    final db = await _database;
    final values = weather.toMap()..remove('id');

    if (weather.id == null) {
      final id = await db.insert('weather', values);

      return WeatherType.fromMap({
        ...values,
        'id': id,
      });
    }

    final count = await db.update(
      'weather',
      values,
      where: 'id = ?',
      whereArgs: [weather.id],
    );

    if (count != 1) {
      throw StateError('Запись ${weather.id} не найдена');
    }

    return weather;
  }

  Future<void> delete(int id) async {
    final db = await _database;

    final count = await db.delete(
      'weather',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count != 1) {
      throw StateError('Запись $id не найдена');
    }
  }
}