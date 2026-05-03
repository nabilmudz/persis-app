import 'dart:math';

class ObjectIdHelper {
  ObjectIdHelper._();

  static final Random _random = Random();

  static String generateLocalId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = _random.nextInt(999999).toString().padLeft(6, '0');
    return 'local_${timestamp}_$randomPart';
  }

  static String generateMongoObjectId() {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toRadixString(16)
        .padLeft(8, '0');
    final randomPart = List.generate(
      16,
      (index) => _random.nextInt(16).toRadixString(16),
    ).join();
    return '$timestamp$randomPart';
  }
}
