import 'dart:async';

abstract interface class Forecastable {
  String getForecast();
}

mixin Wetable {
  void YoureWet() => print("Congrats! Now you're wet!");
}

abstract class WeatherType {
  String? title;
  final double humidity;
  static int _refCoutner = 0;
  WeatherType(this.title, this.humidity) {
    _refCoutner++;
  }

  static int getRefCount() {
    return _refCoutner;
  }

  void applyEffect();
}

class AtmosphericPressure {
  final double? pressure;
  AtmosphericPressure(this.pressure);
  void measurePressure() =>
      print("Atmospheric pressure is currently $pressure mBar");
}

class Sunny extends WeatherType
    implements Forecastable, AtmosphericPressure, Comparable<WeatherType> {
  final double uvIndex;
  @override
  double? get pressure => 1013.25;

  set pressure(double? value) {
    if (value == null || value < 0.0) {
      throw Exception("Pressure must contain a value and be more than zero");
    }
  }

  Sunny(double humidity, this.uvIndex) : super("Sunny", humidity);

  Sunny.extreme() : this(0.0, 11.0);

  @override
  String getForecast() => "A sunny day is expected";

  @override
  void measurePressure() =>
      print("Pressure is stable at the level of $pressure");

  @override
  void applyEffect() => print("Sun shines with UV Index: $uvIndex");
  @override
  int compareTo(WeatherType other) {
    return other.humidity.compareTo(humidity);
  }

  factory Sunny.fromJson(Map<String, dynamic> json) {
    return Sunny(
      (json["Humidity"] as num).toDouble(),
      (json["UVIndex"] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'UVIndex': uvIndex,
    'Pressure': pressure,
    'Humidity': humidity,
  };
}

class Rainy extends WeatherType
    with Wetable
    implements Forecastable, AtmosphericPressure, Comparable<WeatherType> {
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

  @override
  int compareTo(WeatherType other) {
    return other.humidity.compareTo(humidity);
  }
}

class Blizzard extends WeatherType
    with Wetable
    implements Forecastable, AtmosphericPressure, Comparable<WeatherType> {
  double? _precipitation;
  double? get precipitation => _precipitation;
  @override
  double? get pressure => 1000.0;

  Blizzard(double humidity, this._precipitation) : super("Blizzard", humidity);
  Blizzard.strong() : this(0.4, 3);

  set precipitation(double? value) {
    if (value == null || value < 0) {
      throw Exception("Precipitation value must not be null or negative");
    }
    _precipitation = value;
  }

  @override
  String getForecast() => "A blizzard is expected";

  @override
  void measurePressure() =>
      print("Pressure on a blizzard snowy is a little high: $pressure");

  @override
  void applyEffect() =>
      print("Blizzard ahead. Current precipitation: $_precipitation mm");

  @override
  int compareTo(WeatherType other) {
    return other.humidity.compareTo(humidity);
  }

  Future<void> waitForEnd() async {
    await Future.delayed(const Duration(seconds: 4));
    print("The blizzard is over");
  }
}

class WeatherIterator implements Iterator<int> {
  int _current;
  WeatherIterator(int start) : _current = start + 1;

  @override
  int get current => _current;

  @override
  bool moveNext() {
    if (_current > 0) {
      _current--;
      return true;
    }
    print("Boom! You're in Belarus and the weather has already changed!");
    return false;
  }
}

class WeatherForecast {
  final double expectedHumidity = 0.6;
  final String expectedWeather = "Rain";
  final int expectedPrecepitation = 20;

  Future<double> fetchHumidity() async {
    await Future.delayed(const Duration(seconds: 2));
    return expectedHumidity;
  }

  Future<String> fetchWeather() async {
    await Future.delayed(const Duration(seconds: 2));
    return "Forecasted weather: $expectedWeather";
  }

  Future<void> demo() async {
    await fetchHumidity()
        .then((h) => print("Fetched humidity: ${h}%"))
        .catchError((e) => print("Cought error: $e"))
        .whenComplete(() => print("Result returning chaing finished"));

    String combined = await fetchHumidity().then(
      (h) => fetchWeather().then(
        (w) => "Weather is $w, with humidity level at $h%",
      ),
    );
    print(combined);
  }
}

class WeatherCountdown implements Iterable<int> {
  final int start;
  WeatherCountdown(this.start);

  @override
  Iterator<int> get iterator => WeatherIterator(start);

  @override
  bool any(bool Function(int element) test) {
    // TODO: implement any
    throw UnimplementedError();
  }

  @override
  Iterable<R> cast<R>() {
    // TODO: implement cast
    throw UnimplementedError();
  }

  @override
  bool contains(Object? element) {
    // TODO: implement contains
    throw UnimplementedError();
  }

  @override
  int elementAt(int index) {
    // TODO: implement elementAt
    throw UnimplementedError();
  }

  @override
  bool every(bool Function(int element) test) {
    // TODO: implement every
    throw UnimplementedError();
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(int element) toElements) {
    // TODO: implement expand
    throw UnimplementedError();
  }

  @override
  // TODO: implement first
  int get first => throw UnimplementedError();

  @override
  int firstWhere(bool Function(int element) test, {int Function()? orElse}) {
    // TODO: implement firstWhere
    throw UnimplementedError();
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, int element) combine) {
    // TODO: implement fold
    throw UnimplementedError();
  }

  @override
  Iterable<int> followedBy(Iterable<int> other) {
    // TODO: implement followedBy
    throw UnimplementedError();
  }

  @override
  void forEach(void Function(int element) action) {
    // TODO: implement forEach
  }

  @override
  // TODO: implement isEmpty
  bool get isEmpty => throw UnimplementedError();

  @override
  // TODO: implement isNotEmpty
  bool get isNotEmpty => throw UnimplementedError();

  @override
  String join([String separator = ""]) {
    // TODO: implement join
    throw UnimplementedError();
  }

  @override
  // TODO: implement last
  int get last => throw UnimplementedError();

  @override
  int lastWhere(bool Function(int element) test, {int Function()? orElse}) {
    // TODO: implement lastWhere
    throw UnimplementedError();
  }

  @override
  // TODO: implement length
  int get length => throw UnimplementedError();

  @override
  Iterable<T> map<T>(T Function(int e) toElement) {
    // TODO: implement map
    throw UnimplementedError();
  }

  @override
  int reduce(int Function(int value, int element) combine) {
    // TODO: implement reduce
    throw UnimplementedError();
  }

  @override
  // TODO: implement single
  int get single => throw UnimplementedError();

  @override
  int singleWhere(bool Function(int element) test, {int Function()? orElse}) {
    // TODO: implement singleWhere
    throw UnimplementedError();
  }

  @override
  Iterable<int> skip(int count) {
    // TODO: implement skip
    throw UnimplementedError();
  }

  @override
  Iterable<int> skipWhile(bool Function(int value) test) {
    // TODO: implement skipWhile
    throw UnimplementedError();
  }

  @override
  Iterable<int> take(int count) {
    // TODO: implement take
    throw UnimplementedError();
  }

  @override
  Iterable<int> takeWhile(bool Function(int value) test) {
    // TODO: implement takeWhile
    throw UnimplementedError();
  }

  @override
  List<int> toList({bool growable = true}) {
    // TODO: implement toList
    throw UnimplementedError();
  }

  @override
  Set<int> toSet() {
    // TODO: implement toSet
    throw UnimplementedError();
  }

  @override
  Iterable<int> where(bool Function(int element) test) {
    // TODO: implement where
    throw UnimplementedError();
  }

  @override
  Iterable<T> whereType<T>() {
    // TODO: implement whereType
    throw UnimplementedError();
  }
}

Stream<String> rainStream(int count) async* {
  for (int i = 0; i < count; i++) {
    await Future.delayed(const Duration(seconds: 1));
    yield "Update #$i: ${i.isEven ? "Sunny" : "Rainy"}";
  }
}

Future<void> demoStream() async {
  Stream<String> stream = rainStream(10);

  StreamSubscription<String> sub = stream.listen(
    (event) => print("onData: $event"),
    onError: (e) => print("onError: $e"),
    onDone: () => print("onDone: stream closed"),
    cancelOnError: false,
  );

  await Future.delayed(const Duration(milliseconds: 2500));
  await sub.cancel();
  print("Subscription cancelled");
}

Future<void> demoBroadcast() async {
  final controller = StreamController<String>.broadcast();

  final subA = controller.stream.listen((e) => print("A: $e"));
  final subB = controller.stream.listen((e) => print("B: $e"));

  controller.add("Sunny");
  controller.add("Rainy");

  await Future.delayed(const Duration(milliseconds: 100));

  await subA.cancel(); 
  controller.add("Blizzard"); 

  await Future.delayed(const Duration(milliseconds: 100));
  await subB.cancel();
  await controller.close(); 
  print("Broadcast closed");
}

void main() async {
  try {
    print("\nTesting mixins");
    var rain = Rainy.light();
    var blizzard = Blizzard.strong();

    rain.YoureWet();
    blizzard.YoureWet();

    print("\nTesting comparable interface");
    List<WeatherType> weatherToday = [
      Sunny(0.3, 3),
      Sunny(0.152, 2),
      Rainy(100, 40),
      Rainy.light(),
      Sunny.extreme(),
      Blizzard.strong(),
      Sunny(0.1, 8),
      Sunny(0.12, 6),
    ];

    weatherToday.sort();
    for (var w in weatherToday) {
      print('${w.title}:${w.humidity}');
    }

    print("\nTesting Iterator and Iterable");
    for (var c in WeatherCountdown(10)) {
      print(c);
    }

    print("\nWorking with JSON");
    var sun = Sunny.extreme();
    print(sun.toJson());

    Map<String, dynamic> json = {
      "UVIndex": 5.0,
      "Pressure": 1013.25,
      "Humidity": 0.1,
    };
    var jsonSun = Sunny.fromJson(json);
    print(
      "Sunny class from JSON: ${jsonSun.uvIndex}, ${jsonSun.pressure}, ${jsonSun.humidity}",
    );

    print("\nAsync method testing:");
    var asyncBlizzard = Blizzard.strong();
    var forecast = WeatherForecast();

    print("Blizzard is starting");
    await asyncBlizzard.waitForEnd();
    await forecast.demo();
    await demoStream();
    await demoBroadcast();
    
  } on Exception catch (e) {
    print("Weather data error: $e");
  } catch (e) {
    print("System wide error: $e");
  }
}
