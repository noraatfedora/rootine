class Plant {
  String? name;
  String? desc;
  DateTime? expiration;
  PlantKind? kind;
  String? prizeDescription;

  Map<Weekday, bool>? weekdaySelection;
  
  int? numTimes;
  DurationType? duration;

  TimingOption? timingOption; 

  Plant();
  
}

enum PlantKind {
  lettuce (prettyName: "Lettuce", numSketches: 3),
  appleTree (prettyName: "Apple tree", numSketches: 3),
  garlic (prettyName: "Garlic", numSketches: 3);

  final String prettyName;
  final int numSketches;

  const PlantKind( {
    required this.prettyName,
    required this.numSketches
  });

  static PlantKind plantFromPrettyName(String prettyName) {
    for (PlantKind k in PlantKind.values) {
      if (prettyName == k.prettyName) {
        return k;
      }
    }
    return PlantKind.values.first;
  }
}

enum Weekday {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday
}

enum DurationType {
  day (prettyName: "Day"),
  week (prettyName: "Week"),
  month (prettyName: "Month");

  final String prettyName;
  const DurationType({required this.prettyName});
}

enum TimingOption {
  daysOfTheWeek,
  numTimesPerDuration
}