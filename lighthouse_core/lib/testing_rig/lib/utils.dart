part of markhor;

class Utils {
  static const String _chars = 'abcdefghijklmnopqrstuvwxyz1234567890';
  static final Random _rnd = Random();

  static String get randomAlphaNum => String.fromCharCodes(Iterable.generate(
      8, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
}
