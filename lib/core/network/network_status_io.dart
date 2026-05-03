import 'dart:io';

class NetworkStatusImpl {
  static Future<bool> hasInternetConnection() async {
    try {
      final host = Uri.parse('https://example.com').host;
      final result = await InternetAddress.lookup(host);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}