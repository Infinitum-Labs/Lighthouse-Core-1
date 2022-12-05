part of markhor;

class SharedLogs {
  static final List<String> logs = [];

  static void log(dynamic msg) => logs.add(msg.toString());

  static String dump() => logs.join('\n');
}
