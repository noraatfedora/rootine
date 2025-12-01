class SafeDateTime {
  static final bool DEBUG = true;
  static DateTime now() {
    if (!DEBUG) {
      return DateTime.now();
    } else {
      return DateTime.now().add(Duration(days:3));
    }
  }
}