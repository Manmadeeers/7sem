abstract class WeatherType {
  const WeatherType({
    this.id,
    required this.title,
    required this.humidity,
    required this.pressure,
  });

  final int? id;
  final String title;
  final double humidity;
  final double pressure;

  String get kind;

  double? get uvIndex => null;
  double? get precipitation => null;

  String get typeLabel => kind == 'sunny' ? 'Солнечно' : 'Дождь';

  String getForecast();

  String get details {
    final specific = kind == 'sunny'
        ? 'UV-индекс: $uvIndex'
        : 'Осадки: $precipitation мм';

    return 'ID: ${id ?? "нет — файловая копия"}\n'
        'Название: $title\n'
        'Тип: $typeLabel\n'
        'Влажность: $humidity %\n'
        'Давление: $pressure гПа\n'
        '$specific\n'
        'Прогноз: ${getForecast()}';
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'kind': kind,
        'title': title,
        'humidity': humidity,
        'pressure': pressure,
        'uv_index': uvIndex,
        'precipitation': precipitation,
      };

  factory WeatherType.fromMap(Map<String, Object?> map) {
    final id = map['id'] as int?;
    final title = map['title'] as String;
    final humidity = (map['humidity'] as num).toDouble();
    final pressure = (map['pressure'] as num).toDouble();

    switch (map['kind']) {
      case 'sunny':
        return Sunny(
          id: id,
          title: title,
          humidity: humidity,
          pressure: pressure,
          uvIndex: (map['uv_index'] as num).toDouble(),
        );

      case 'rainy':
        return Rainy(
          id: id,
          title: title,
          humidity: humidity,
          pressure: pressure,
          precipitation: (map['precipitation'] as num).toDouble(),
        );

      default:
        throw FormatException('Неизвестный тип погоды: ${map["kind"]}');
    }
  }
}

class Sunny extends WeatherType {
  const Sunny({
    super.id,
    required super.title,
    required super.humidity,
    required super.pressure,
    required this.uvIndex,
  });

  @override
  final double uvIndex;

  @override
  String get kind => 'sunny';

  @override
  String getForecast() => 'Ожидается солнечный день';
}

class Rainy extends WeatherType {
  const Rainy({
    super.id,
    required super.title,
    required super.humidity,
    required super.pressure,
    required this.precipitation,
  });

  @override
  final double precipitation;

  @override
  String get kind => 'rainy';

  @override
  String getForecast() => 'Ожидается дождь';
}