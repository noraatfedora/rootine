import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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

    if (lastUpdated != null &&
        (lastUpdated.day != SafeDateTime.now().day ||
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

              plant.health -= (1 / ((daysMissed / 3) + 1));
              print(
                'Plant ${plant.name} missed watering for $daysMissed days.',
              );
            }
            if (plant.weekdaySelection != null &&
              plant.weekdaySelection![Weekday.values[SafeDateTime.now().weekday - 1]] ==
                true) {
              plant.wateredToday = false;
            }
          }
        } else if (plant.timingOption == TimingOption.numTimesPerDuration) {
          if (lastUpdated != null) {
            final duration = plant.duration;
            if (duration != null) {
              DateTime currentDurationStart =
                  plant.startDate ?? SafeDateTime.now();
              while (currentDurationStart.isBefore(lastUpdated)) {
                currentDurationStart = currentDurationStart.add(
                  duration.toDuration(),
                );
              }

              int missedIntervals = 0;
              DateTime currentCheck = currentDurationStart;
              while (currentCheck.isBefore(SafeDateTime.now())) {
                missedIntervals++;
                currentCheck = currentCheck.add(duration.toDuration());
              }

              double pointsLost = missedIntervals.toDouble();
              if (plant.numTimes != 0 &&
                  plant.numCompletedPerDuration != null) {
                pointsLost +=
                    (plant.numCompletedPerDuration! - plant.numTimes!) /
                    plant.numCompletedPerDuration!;
                plant.numTimes = 0;
              }

              print(
                'Plant ${plant.name} lost $pointsLost points due to missed intervals.',
              );
              plant.health -= (1 / ((pointsLost / 3) + 1));
            }
            plant.numTimes = 0;
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
          'health': value.health,
          'rewardType': value.rewardType.toString(),
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
                    children: Provider.of<PlantProvider>(context).plants.entries.map((
                      entry,
                    ) {
                      Widget leadingNode = SizedBox(
                        child: CircularPercentIndicator(
                          radius: 40.0,
                          lineWidth: 5.0,
                          percent: entry.value.getProgress(),
                          center: Image.asset(
                            entry.value.getPlantImagePath(),
                            width: 40.0,
                            height: 40.0,
                          ),
                          progressColor: fromHealth(entry.value.health),
                        ),
                        width: 80.0,
                        height: 80.0
                      );
                      String wateredMsg = "";
                      bool needsWater = entry.value.needsWater();
                      if ((entry.value.timingOption ==
                                  TimingOption.daysOfTheWeek ||
                              entry.value.numCompletedPerDuration == 1) &&
                          needsWater) {
                        wateredMsg = "Needs to be watered today";
                      } else {
                        if (needsWater) {
                          wateredMsg =
                              "Water status: ${entry.value.numTimes}/${entry.value.numCompletedPerDuration} ";
                          switch (entry.value.duration) {
                            case DurationType.day:
                              wateredMsg += " today";
                              break;
                            case DurationType.week:
                              wateredMsg += " this week";
                              break;
                            case DurationType.month:
                              wateredMsg += " this month";
                              break;
                            default:
                              break;
                          }
                        }
                      }
                      if (!needsWater) {
                        wateredMsg = "Fully watered today!";
                      }
                      Widget trailingNote = Text(
                        'Harvests ${entry.value.expiration!.month}/${entry.value.expiration!.day}/${entry.value.expiration!.year}',
                      );
                      Widget timingIndicator;
                      if (entry.value.timingOption ==
                          TimingOption.daysOfTheWeek) {
                        timingIndicator = Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: Weekday.values.map((weekday) {
                            bool isSelected =
                                entry.value.weekdaySelection?[weekday] ?? false;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300],
                                child: Text(
                                  weekday.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      } else {
                        timingIndicator = Text(
                          "Needs water ${entry.value.numCompletedPerDuration} times per ${entry.value.duration?.prettyName.toLowerCase() ?? 'duration'}",
                        );
                      }
                      bool needsPrize = false;
                      if (entry.value.prizeDescription == null ||
                          entry.value.prizeDescription!.isEmpty) {
                        needsPrize = true;
                        trailingNote = Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            trailingNote,
                            TextButton.icon(
                              onPressed: () {
                                // Add your "add prize" functionality here
                                entry.value.shareLink();
                              },
                              icon: const Icon(Icons.card_giftcard, size: 16),
                              label: const Text('Send a link to hide prize'),
                            ),
                          ],
                        );
                        leadingNode = const Icon(Icons.upload_file, size: 60);
                      }
                      return  Card(
                          elevation: 4.0,
                          margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                          ),
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: InkWell(
                          onTap: () {
                            // Add your onTap functionality here
                            if (needsPrize) {
                            FilePicker.platform
                              .pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['rootine'],
                              )
                              .then((result) {
                                if (result != null &&
                                  result.files.isNotEmpty) {
                                final file = result.files.first;
                                final filePath = file.path;
                                if (filePath != null) {
                                  // Process the .rootine file
                                  print('Selected file: $filePath');

                                  entry.value.extractRootineFile(
                                  File(file.path!),
                                  );
                                  entry.value
                                    .extractRootineFile(
                                    File(file.path!),
                                    )
                                    .then((_) {
                                    setState(() {
                                      Provider.of<PlantProvider>(
                                      context,
                                      listen: false,
                                      ).updateStorage().then((_) {
                                      Provider.of<PlantProvider>(
                                        context,
                                        listen: false,
                                      ).refreshPlants();
                                      });
                                    });
                                    })
                                    .catchError((error) {
                                    print(
                                      'Error processing file: $error',
                                    );
                                    });
                                }
                                } else {
                                print('No file selected.');
                                }
                              })
                              .catchError((error) {
                                print('Error picking file: $error');
                              });
                            } else {
                            // TODO: watering
                            bool success = entry.value.waterPlant();
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                '${entry.value.name} watered!',
                                ),
                              ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                '${entry.value.name} has already been fully watered today!',
                                ),
                              ),
                              );
                            }
                            Provider.of<PlantProvider>(
                              context,
                              listen: false,
                            ).updateStorage();
                            setState(() {
                              Provider.of<PlantProvider>(
                              context,
                              listen: false,
                              ).refreshPlants();
                            });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                            children: [
                              leadingNode,
                              const SizedBox(width: 16.0),
                              Expanded(
                              child: Column(
                                crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                children: [
                                Text(
                                  entry.value.name!,
                                  style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(entry.value.desc!),
                                const SizedBox(height: 4.0),
                                Text(
                                  'Health: ${(entry.value.health * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                  color: fromHealth(entry.value.health),
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(wateredMsg),
                                const SizedBox(height: 4.0),
                                timingIndicator,
                                ],
                              ),
                              ),
                              trailingNote,
                            ],
                            ),
                          ),
                          ),
                      );
                    }).toList()
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
    spectrum: [
      Color.fromARGB(255, 178, 0, 0),
      Color.fromARGB(255, 225, 221, 0),
      Color.fromARGB(255, 0, 158, 0),
    ],
    rangeStart: 0.0,
    rangeEnd: 1.0,
  );
  return rb[health];
}
