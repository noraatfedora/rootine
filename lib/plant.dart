class Plant {
  String name;
  DateTime expiration;
  PlantKind kind;

  Plant(this.name, this.expiration, this.kind);
  
}

enum PlantKind {
  lettuce,
  appleTree,
  garlic 
}