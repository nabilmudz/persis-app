import 'dart:math';

class ObjectIdHelper {
  ObjectIdHelper._();

  static final Random _random = Random();

  static String generateLocalId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = _random.nextInt(999999).toString().padLeft(6, '0');
    return 'local_${timestamp}_$randomPart';
  }
}
