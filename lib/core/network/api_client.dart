import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient._();

  static String get baseUrl {
    final rawBaseUrl = dotenv.env['BASE_URL']?.trim();

    assert(
      rawBaseUrl != null && rawBaseUrl.isNotEmpty,
      'BASE_URL is not defined in .env file',
    );

    if (rawBaseUrl == null || rawBaseUrl.isEmpty) {
      throw Exception('BASE_URL is not defined in .env file');
    }

    return rawBaseUrl.endsWith('/api')
        ? rawBaseUrl
        : '${rawBaseUrl.replaceAll(RegExp(r'/?$'), '')}/api';
  }

  static Future<Map<String, String>> _defaultHeaders({String? token}) async {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint, {String? token}) async {
    final headers = await _defaultHeaders(token: token);
    final uri = Uri.parse('$baseUrl$endpoint');

    return http.get(uri, headers: headers);
  }

  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final headers = await _defaultHeaders(token: token);
    final uri = Uri.parse('$baseUrl$endpoint');

    return http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final headers = await _defaultHeaders(token: token);
    final uri = Uri.parse('$baseUrl$endpoint');

    return http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  static Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final headers = await _defaultHeaders(token: token);
    final uri = Uri.parse('$baseUrl$endpoint');

    return http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  static Future<http.Response> delete(String endpoint, {String? token}) async {
    final headers = await _defaultHeaders(token: token);
    final uri = Uri.parse('$baseUrl$endpoint');

    return http.delete(uri, headers: headers);
  }
}
