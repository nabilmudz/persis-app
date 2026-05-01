import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserRemoteDataSource {
  final String baseUrl;
  UserRemoteDataSource(this.baseUrl);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/users/login');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal Login');
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
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception('Gagal mengambil data user');
  }
}
