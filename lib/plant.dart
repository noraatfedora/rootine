class Plant {
  String name;
  DateTime expiration;
  PlantKind kind;

  Plant(this.name, this.expiration, this.kind);
  
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
}