abstract interface class Forecastable {
  String getForecast();
}

abstract class WeatherType {
  String? title;
  final double humidity;
  WeatherType(this.title, this.humidity);
  void applyEffect();
}

class AtmosphericPressure {
  final double? pressure;
  AtmosphericPressure(this.pressure);
  void measurePressure() =>
      print("Atmospheric pressure is currently $pressure mBar");
}

class Sunny extends WeatherType implements Forecastable, AtmosphericPressure {
  final double uvIndex;

  @override
  double? get pressure => 1013.25;

  Sunny(double humidity, this.uvIndex) : super("Sunny", humidity);
  Sunny.extreme() : this(0.0, 11.0);

  @override
  String getForecast() => "A sunny day is expected";

  @override
  void measurePressure() =>
      print("Pressure is stable at the level of $pressure");

  @override
  void applyEffect() => print("Sun shines with UV Index: $uvIndex");
}

class Rainy extends WeatherType implements Forecastable, AtmosphericPressure {
  double? _precipitation;

  Rainy(double humidity, this._precipitation) : super("Rainy", humidity);
  Rainy.light() : this(0.4, 2);

  @override
  double? get pressure => 900.0;

  double? get precipitation => _precipitation;

  set precipitation(double? value) {
    if (value == null || value < 0) {
      throw Exception("Precipitation value must not be null or negative");
    }
    _precipitation = value;
  }

  @override
  String getForecast() => "A rainy day is expected";

  @override
  void measurePressure() =>
      print("Pressure on a rainy day is a little high: $pressure");

  @override
  void applyEffect() => print(
    "Raindrops fall from the skies. Current precipitation: $_precipitation mm",
  );
}

void simulateWeather(WeatherType type, {bool log = true, int duration = 1}) {
  if (log) {
    print("${type.title} weather is starting now");
  }
  for (int i = 0; i < duration; i++) {
    type.applyEffect();
  }
}

void main() {
  try {
    List<WeatherType> weatherToday = [
      Sunny(0.3, 3),
      Sunny(0.152, 2),
      Rainy(100, 40),
      Rainy.light(),
      Sunny.extreme(),
      Sunny(0.1, 8),
      Sunny(0.12, 6),
    ];

    Set<String> precipitationTypes = {"Rain", "Snow", "Blizzard"};

    Map<int, String> hourlyWeatherMap = {
      9: "Sunny",
      12: "Partially cloudy",
      14: "Showers",
      16: "Light rain",
      18: "Extreme sunlight",
    };

    print("Precipitation types: $precipitationTypes");

    print("\nHourly Forecast from Map:");
    hourlyWeatherMap.forEach((hour, status) {
      print("At $hour:00 the weather will be $status");
    });

    print("\nDay weather modelling:");
    for (var weather in weatherToday) {
      if (weather is Sunny && weather.uvIndex > 10) {
        print("ALERT: Extreme heat detected!");
        break;
      }

      if (weather.humidity < 0.2 && weather is! Sunny) {
        continue;
      }

      simulateWeather(weather, duration: 2);
    }

    print("\nTesting errors:");
    var rain = Rainy(0.8, 20);
    rain.precipitation = -5.0;
  } on Exception catch (e) {
    print("Weather data error: $e");
  } catch (e) {
    print("System wide error: $e");
  } finally {
    print("Weather station waits");
  }
}
