import 'network_status_io.dart'
    if (dart.library.html) 'network_status_web.dart';

class NetworkStatus {
  static Future<bool> hasInternetConnection() =>
      NetworkStatusImpl.hasInternetConnection();
}