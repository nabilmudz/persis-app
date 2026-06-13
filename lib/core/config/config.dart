import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl =>
      (dotenv.env['BASE_URL'] ?? 'http://localhost:3000/api').trim();
  static String get rootUrl {
    final raw = dotenv.env['BASE_URL']?.trim() ?? 'http://localhost:3000';
    return raw.replaceAll(RegExp(r'/api/?$'), '');
  }

  static String fullUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '${rootUrl.replaceAll(RegExp(r'/$'), '')}/$clean';
  }
}
