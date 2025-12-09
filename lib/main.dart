import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:rainbow_color/rainbow_color.dart';
import 'package:rootine/newplant.dart';
import 'package:rootine/safedatetime.dart';
import 'package:rootine/style.dart';
import 'package:rootine/plant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PlantProvider(),
      child: const MyApp(),
    ),
  );
}

class PlantProvider extends ChangeNotifier {
  final Map<String, Plant> _plants = {};

  Map<String, Plant> get plants => _plants;

  void addPlant(String id, Plant plant) {
    _plants[id] = plant;
    updateStorage();
    notifyListeners(); // Notify listeners about the change
  }

  void removePlant(String id) {
    _plants.remove(id);
    updateStorage();
    notifyListeners(); // Notify listeners about the change
  }

  Future<Map<String, Plant>> getPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final plantsJson = prefs.getString('plants');
    final lastUpdatedString = prefs.getString('lastUpdated');
    DateTime? lastUpdated;
    if (lastUpdatedString != null) {
      lastUpdated = DateTime.tryParse(lastUpdatedString);
    }

    if (plantsJson == null) {
      return {};
    }

    final Map<String, dynamic> plantsMap = Map<String, dynamic>.from(
      jsonDecode(plantsJson),
    );

    Map<String, Plant> extracted = plantsMap.map(
      (key, value) =>
          MapEntry(key, Plant.fromMap(Map<String, dynamic>.from(value))),
    );

    if (lastUpdated != null && (
        lastUpdated.day != SafeDateTime.now().day ||
        lastUpdated.month != SafeDateTime.now().month ||
        lastUpdated.year != SafeDateTime.now().year)) {
      for (var plant in extracted.values) {
        if (plant.timingOption == TimingOption.daysOfTheWeek) {
          if (lastUpdated != null) {
            final lastUpdatedDay =
                lastUpdated.weekday; // 1 = Monday, 7 = Sunday
            if (plant.weekdaySelection != null &&
                plant.weekdaySelection![Weekday.values[lastUpdatedDay - 1]] ==
                    true &&
                plant.wateredToday == false) {
              int daysMissed = 0;
              DateTime currentDay = lastUpdated.add(const Duration(days: 1));
              while (currentDay.isBefore(SafeDateTime.now())) {
                final currentWeekday =
                    currentDay.weekday; // 1 = Monday, 7 = Sunday
                if (plant.weekdaySelection != null &&
                    plant.weekdaySelection![Weekday.values[currentWeekday -
                            1]] ==
                        true) {
                  daysMissed++;
                }
                currentDay = currentDay.add(const Duration(days: 1));
              }

              plant.health -= (1/((daysMissed/3)+1));
              print(
                'Plant ${plant.name} missed watering for $daysMissed days.',
              );
            }
          }
        } else if (plant.timingOption == TimingOption.numTimesPerDuration) {
          if (lastUpdated != null) {
            final duration = plant.duration;
            if (duration != null) {
              DateTime currentDurationStart = plant.startDate ?? SafeDateTime.now();
              while (currentDurationStart.isBefore(lastUpdated)) {
                currentDurationStart = currentDurationStart.add(duration.toDuration());
              }

              int missedIntervals = 0;
              DateTime currentCheck = currentDurationStart;
              while (currentCheck.isBefore(SafeDateTime.now())) {
                missedIntervals++;
                currentCheck = currentCheck.add(duration.toDuration());
              }

              double pointsLost = missedIntervals.toDouble();
              if (plant.numTimes != 0 && plant.numCompletedPerDuration != null) {
                pointsLost += (plant.numCompletedPerDuration! - plant.numTimes!) /
                    plant.numCompletedPerDuration!;
                plant.numTimes = 0;
              }

              print(
                'Plant ${plant.name} lost $pointsLost points due to missed intervals.',
              );
              plant.health -= (1/((pointsLost/3)+1));
            }
          }
        }
      }
    }

    await prefs.setString('lastUpdated', SafeDateTime.now().toIso8601String());

    return extracted;
  }

  Future<void> refreshPlants() async {
    Map<String, Plant> newCopy = await getPlants();
    _plants.clear();
    _plants.addAll(newCopy);
    // getting plants can cause logic that refreshes
    // the health value
    updateStorage();
  }

  Future<void> updateStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final plantsJson = jsonEncode(
      _plants.map(
        (key, value) => MapEntry(key, {
          'name': value.name,
          'desc': value.desc,
          'expiration': value.expiration?.toIso8601String(),
          'kind': value.kind?.prettyName,
          'prizeDescription': value.prizeDescription,
          'weekdaySelection': value.weekdaySelection?.map(
            (key, value) => MapEntry(key.name, value),
          ),
          'numTimes': value.numTimes,
          'duration': value.duration?.prettyName,
          'timingOption': value.timingOption?.name,
          'startDate': value.startDate?.toIso8601String(),
          'wateredToday': value.wateredToday,
          'numCompletedPerDuration': value.numCompletedPerDuration,
          'health': value.health
        }),
      ),
    );
    await prefs.setString('plants', plantsJson);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PlantProvider _plantProvider = PlantProvider();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _plantProvider,
      child: MaterialApp(
        title: 'Rootine',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 31, 74, 22),
          ),
        ),
        home: const MyHomePage(title: 'Rootine'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: DefaultTextStyle.merge(
        style: RootineStyle.textStyle,
        child: Center(
          child: FutureBuilder(
            future: Provider.of<PlantProvider>(
              context,
              listen: false,
            ).refreshPlants(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: Provider.of<PlantProvider>(context).plants.entries
                        .map((entry) {
                            return Card(
                              elevation: 4.0,
                              margin: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16.0,
                              ),
                              shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: ListTile(
                              onTap: () {
                                // Add your onTap functionality here
                              },
                              leading: CircularPercentIndicator(
                                radius: 20.0,
                                lineWidth: 5.0,
                                percent: entry.value.getProgress(),
                                center: Text(
                                '${(entry.value.getProgress() * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 10),
                                ),
                                progressColor: fromHealth(entry.value.health),
                              ),
                              title: Text(entry.key),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                Text(entry.value.desc!),
                                Text(
                                  'Health: ${(entry.value.health * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(color: fromHealth(entry.value.health)),
                                ),
                                ],
                              ),
                              trailing: Text(
                                'Harvests ${entry.value.expiration!.day}/${entry.value.expiration!.month}/${entry.value.expiration!.year}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              ),
                            );
                        })
                        .toList(),
                  ),
                );
              }
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Container(height: 50.0),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (context) => NewPlantRoute()),
        ),
        tooltip: 'Make a new plant',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

Color fromHealth(double health) {
  var rb = Rainbow(
    spectrum: [Color(0xffff0000), Color.fromARGB(255, 225, 221, 0), Color.fromARGB(255, 0, 158, 0)],
    rangeStart: 0.0,
    rangeEnd: 1.0,
  );
  return rb[health];
}
