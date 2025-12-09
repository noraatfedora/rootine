class SafeDateTime {
  static final bool DEBUG = false;
  static DateTime now() {
    if (DEBUG) {
      return DateTime.now();
    } else {
      return DateTime.now().add(Duration(days:10));
    }
  }
}