import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/transaction_item_model.dart';

class UserRemoteDataSource {
  final String baseUrl;
  UserRemoteDataSource(this.baseUrl);

  // ─── LOGIN USER ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String emailOrNpa, String password) async {
    final identifier = emailOrNpa.trim();
    final credentialKey = identifier.contains('@') ? 'email' : 'npa';
    final url = Uri.parse('$baseUrl/users/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({credentialKey: identifier, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal Login');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ─── UPDATE USER (Profil) ──────────────────────────────────────────────────
  Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/users/$id');
    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final userData = body is Map && body.containsKey('data') ? body['data'] : body;
        return UserModel.fromJson(userData);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal memperbarui profil');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ─── SET PASSWORD (RESET LUPA PASSWORD) ────────────────────────────────────
  Future<void> setPassword(String identifier, String newPassword) async {
    final url = Uri.parse('$baseUrl/users/set-password');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal mereset password');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ─── GET ONE USER ──────────────────────────────────────────────────────────
  Future<UserModel> getOneUsers(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$id')).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = json.decode(response.body);
      final userData = body is Map && body.containsKey('data') ? body['data'] : body;
      return UserModel.fromJson(userData);
    }
    throw Exception('Gagal mengambil data user');
  }

  // ─── GET ALL USERS (DIKEMBALIKAN) ──────────────────────────────────────────
  Future<List<UserModel>> getAllUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users')).timeout(const Duration(seconds: 10));
        
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = json.decode(response.body);
      final List data = body is Map && body.containsKey('data') ? body['data'] : body;
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception('Gagal mengambil data user');
  }

  // ─── GET RIWAYAT IURAN ─────────────────────────────────────────────────────
  Future<List<TransactionItemModel>> getRiwayatIuran(String userId) async {
    final url = Uri.parse('$baseUrl/transaction-item/user/$userId');
    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = json.decode(response.body);
      final List data = body is Map && body.containsKey('data') ? body['data'] : body;
      return data.map((e) => TransactionItemModel.fromJson(e)).toList();
    }
    throw Exception('Gagal mengambil data riwayat iuran');
  }

  // ─── AKTIVASI AKUN (DIKEMBALIKAN) ──────────────────────────────────────────
  Future<bool> activate(String id) async {
    final response = await http
        .patch(Uri.parse('$baseUrl/users/$id/activate'))
        .timeout(const Duration(seconds: 10));
    return response.statusCode == 200;
  }

  // ─── CHECK NPA (DIKEMBALIKAN) ──────────────────────────────────────────────
  Future<void> checkNpa(String npa) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/check-npa/$npa'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 8));

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }
    throw Exception(body['message'] ?? 'NPA tidak ditemukan');
  }
}