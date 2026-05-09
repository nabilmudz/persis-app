import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/transaction_item_model.dart';

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

  // Get One User
  Future<UserModel> getOneUsers(String id) async {
    final response = await http
        .get(Uri.parse('$baseUrl/users/$id'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserModel.fromJson(data);
    }
    throw Exception('Gagal mengambil data user');
  }

  // Get All Users
  Future<List<UserModel>> getAllUsers({String? regionId}) async {
    final url = regionId != null
        ? '$baseUrl/users/region/$regionId'
        : '$baseUrl/users';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      List data = json.decode(response.body);
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception('Gagal mengambil data user');
  }

  // Get Riwayat Iuran dari API
  Future<List<TransactionItemModel>> getRiwayatIuran(String userId) async {
    final url = Uri.parse('$baseUrl/transaction-item/user/$userId');
    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      List data = json.decode(response.body);
      return data.map((e) => TransactionItemModel.fromJson(e)).toList();
    }
    throw Exception('Gagal mengambil data riwayat iuran');
  }

  Future<Map<String, dynamic>> checkNpa(String npa) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/users/check-npa/$npa'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 8));

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    }

    throw Exception(body['message'] ?? 'NPA tidak ditemukan');
  }
}
