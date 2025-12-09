import 'safedatetime.dart';

class Plant {
  String? name;
  String? desc;
  DateTime? expiration;
  DateTime? startDate;
  PlantKind? kind;
  String? prizeDescription;

  Map<Weekday, bool>? weekdaySelection;
  bool? wateredToday;

  int? numTimes;
  DurationType? duration;
  int? numCompletedPerDuration;

  TimingOption? timingOption;

  // scale of 1 to 0
  double health = 1;

  Plant();

  //static Map<String, Plant> allPlants = Map();
  factory Plant.fromMap(Map<String, dynamic> plantData) {
    return Plant()
      ..name = plantData['name'] as String?
      ..desc = plantData['desc'] as String?
      ..expiration = plantData['expiration'] != null
          ? DateTime.parse(plantData['expiration'] as String)
          : null
      ..kind = plantData['kind'] != null
          ? PlantKind.plantFromPrettyName(plantData['kind'] as String)
          : null
      ..prizeDescription = plantData['prizeDescription'] as String?
      ..weekdaySelection = plantData['weekdaySelection'] != null
          ? (plantData['weekdaySelection'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                Weekday.values.firstWhere((e) => e.name == key),
                value as bool,
              ),
            )
          : null
      ..numTimes = plantData['numTimes'] as int?
      ..duration = plantData['duration'] != null
          ? DurationType.values.firstWhere(
              (e) => e.prettyName == plantData['duration'],
              orElse: () => DurationType.day,
            )
          : null
      ..timingOption = plantData['timingOption'] != null
          ? TimingOption.values.firstWhere(
              (e) => e.name == plantData['timingOption'],
              orElse: () => TimingOption.daysOfTheWeek,
            )
          : null
      ..startDate = plantData['startDate'] != null
          ? DateTime.parse(plantData['startDate'] as String)
          : null
      ..wateredToday = plantData['wateredToday'] as bool?
      ..numCompletedPerDuration = plantData['numCompletedPerDuration'] as int?
      ..health = plantData['health'] != null
          ? (plantData['health'] as num).toDouble()
          : 1;
  }

  double getProgress() {
    if (startDate == null || expiration == null) {
      return 0.0;
    }

    final now = SafeDateTime.now();
    if (now.isBefore(startDate!) || now.isAfter(expiration!)) {
      return 0.0;
    }

    final totalDuration = expiration!.difference(startDate!).inMilliseconds;
    final elapsedDuration = now.difference(startDate!).inMilliseconds;

    return (elapsedDuration / totalDuration).clamp(0.0, 1.0);
  }
}

enum PlantKind {
  lettuce(prettyName: "Lettuce", numSketches: 3),
  appleTree(prettyName: "Apple tree", numSketches: 3),
  garlic(prettyName: "Garlic", numSketches: 3);

  final String prettyName;
  final int numSketches;

  const PlantKind({required this.prettyName, required this.numSketches});

  static PlantKind plantFromPrettyName(String prettyName) {
    for (PlantKind k in PlantKind.values) {
      if (prettyName == k.prettyName) {
        return k;
      }
    }
    return PlantKind.values.first;
  }
}

enum Weekday { sunday, monday, tuesday, wednesday, thursday, friday, saturday }

enum DurationType {
  day(prettyName: "Day", numDays: 1),
  week(prettyName: "Week", numDays: 7),
  month(prettyName: "Month", numDays: 31);

  final String prettyName;
  final int numDays;

  Duration toDuration() {
    return Duration(days: numDays);
  }

  const DurationType({required this.prettyName, required this.numDays});
}

enum TimingOption { daysOfTheWeek, numTimesPerDuration }
