import 'package:flutter/material.dart';

import 'models/weather.dart';
import 'screens/weather_details.dart';
import 'screens/weather_editor.dart';
import 'services/weather_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WeatherListScreen(),
    );
  }
}

enum SortField {
  title('Name'),
  kind('Weather Type'),
  humidity('Humidity'),
  pressure('Pressure');

  const SortField(this.label);

  final String label;
}

class WeatherListScreen extends StatefulWidget {
  const WeatherListScreen({super.key});

  @override
  State<WeatherListScreen> createState() => _WeatherListScreenState();
}

class _WeatherListScreenState extends State<WeatherListScreen> {
  Future<List<WeatherType>> _future = WeatherDatabase.instance.getAll();

  String _query = '';

  final _fields = [SortField.title, SortField.humidity];
  final _ascending = [true, true];

  void _reload() {
    setState(() {
      _future = WeatherDatabase.instance.getAll();
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => screen),
    );

    if (mounted) {
      _reload();
    }
  }

  int _compare(WeatherType a, WeatherType b, SortField field) {
    return switch (field) {
      SortField.title =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      SortField.kind => a.typeLabel.compareTo(b.typeLabel),
      SortField.humidity => a.humidity.compareTo(b.humidity),
      SortField.pressure => a.pressure.compareTo(b.pressure),
    };
  }

  List<WeatherType> _visible(List<WeatherType> source) {
    final query = _query.trim().toLowerCase();

    final result = source.where((weather) {
      final text = [
        weather.title,
        weather.typeLabel,
        weather.kind,
        weather.getForecast(),
      ].join(' ').toLowerCase();

      return text.contains(query);
    }).toList();

    result.sort((a, b) {
      for (var i = 0; i < _fields.length; i++) {
        final comparison = _compare(a, b, _fields[i]);

        if (comparison != 0) {
          return _ascending[i] ? comparison : -comparison;
        }
      }

      return (a.id ?? 0).compareTo(b.id ?? 0);
    });

    return result;
  }

  Widget _sortRow(int index) {
    return Row(
      children: [
        Text('Field ${index + 1}: '),
        Expanded(
          child: DropdownButton<SortField>(
            isExpanded: true,
            value: _fields[index],
            items: SortField.values.map((field) {
              return DropdownMenuItem(
                value: field,
                child: Text(field.label),
              );
            }).toList(),
            onChanged: (field) {
              if (field == null) return;

              setState(() {
                _fields[index] = field;

                final other = 1 - index;

                if (_fields[other] == field) {
                  _fields[other] = SortField.values.firstWhere(
                    (candidate) => candidate != field,
                  );
                }
              });
            },
          ),
        ),
        IconButton(
          tooltip: _ascending[index] ? 'Ascending' : 'Descending',
          icon: Icon(
            _ascending[index] ? Icons.arrow_upward : Icons.arrow_downward,
          ),
          onPressed: () {
            setState(() {
              _ascending[index] = !_ascending[index];
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _open(const WeatherEditor()),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Name, type or forecast',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _query = value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _sortRow(0),
                _sortRow(1),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<WeatherType>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SelectableText('Databse error:\n${snapshot.error}'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _reload,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final items = _visible(snapshot.data ?? []);

                if (items.isEmpty) {
                  return const Center(
                    child: Text('Theres nothing here'),
                  );
                }

                return ListView.builder(
                  itemExtent: 96,
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final weather = items[index];

                    return ListTile(
                      leading: Icon(
                        weather is Sunny ? Icons.wb_sunny : Icons.water_drop,
                      ),
                      title: Text(
                        weather.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${weather.typeLabel} · '
                        'Влажность: ${weather.humidity}%\n'
                        'Давление: ${weather.pressure} гПа',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(
                        WeatherDetails(weather: weather),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}