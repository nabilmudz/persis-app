import 'package:hive/hive.dart';

class HiveService {
  HiveService._();

  static const String authBox = 'auth_box';
  static const String anggotaBox = 'anggota_box';
  static const String pembayaranBox = 'pembayaran_box';
  static const String syncQueueBox = 'sync_queue_box';

  static Future<void> init() async {
    await Hive.openBox(authBox);
    await Hive.openBox(anggotaBox);
    await Hive.openBox(pembayaranBox);
    await Hive.openBox(syncQueueBox);
  }

  static Box<dynamic> box(String name) {
    return Hive.box(name);
  }

  static Future<void> put(String boxName, dynamic key, dynamic value) async {
    await box(boxName).put(key, value);
  }

  static T? get<T>(String boxName, dynamic key) {
    return box(boxName).get(key) as T?;
  }

  static Future<void> delete(String boxName, dynamic key) async {
    await box(boxName).delete(key);
  }

  static Future<void> clear(String boxName) async {
    await box(boxName).clear();
  }
}
