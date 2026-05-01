import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserRemoteDataSource {
  final String baseUrl;
  UserRemoteDataSource(this.baseUrl);

  // Login User
  Future<Map<String, dynamic>> login(String emailOrNpa, String password) async {
    final identifier = emailOrNpa.trim();
    final credentialKey = identifier.contains('@') ? 'email' : 'npa';
    final url = Uri.parse('$baseUrl/users/login');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({credentialKey: identifier, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      // debug prints (safe for dev) - remove or guard in production
      // ignore: avoid_print
      print('LOGIN URL: $url');
      // ignore: avoid_print
      print('STATUS: ${response.statusCode}');
      // ignore: avoid_print
      print('BODY: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Gagal Login');
        } catch (_) {
          throw Exception('Gagal Login: ${response.statusCode}');
        }
      }
    } on TimeoutException {
      throw Exception(
        'Server tidak merespon, periksa koneksi internet atau server mati.',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Aktivasi Akun
  Future<bool> activate(String id) async {
    final response = await http
        .patch(Uri.parse('$baseUrl/users/$id/activate'))
        .timeout(const Duration(seconds: 10));
    return response.statusCode == 200;
  }

  // Get All Users
  Future<List<UserModel>> getAllUsers() async {
    final response = await http
        .get(Uri.parse('$baseUrl/users'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      List data = json.decode(response.body);
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception('Gagal mengambil data user');
  }
}
