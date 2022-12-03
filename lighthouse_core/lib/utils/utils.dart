library core.utils;

import 'dart:math';

class ObjectId {
  static const String _chars = 'abcdefghijklmnopqrstuvwxyz1234567890';
  static final Random _rnd = Random();

  static String generateAlphaNumString() =>
      String.fromCharCodes(Iterable.generate(
          8, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  static String generate(String objectPrefix, String userKey) =>
      '$objectPrefix-' + ObjectId.generateAlphaNumString() + '-$userKey'; // wb-nr8ybar4-voefiyg7
}

void main() {
  print(ObjectId.generate('wb', '8a7bzqhn'));
}