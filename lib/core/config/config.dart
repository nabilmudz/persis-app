import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static final String baseUrl =
      dotenv.env['BASE_URL'] ?? (throw Exception('BASE_URL not set'));
}
