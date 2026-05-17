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
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = json.decode(response.body);
      List data = [];
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded['data'] is List) {
        data = decoded['data'];
      } else if (decoded is Map && decoded['users'] is List) {
        data = decoded['users'];
      }
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception('Gagal mengambil data user');
  }

  // Get Users With Status (GET dengan query param ?status_tag=lunas|tunggakan)
  Future<List<UserModel>> getUsersWithStatus(String statusTag, {String? regionId}) async {
    var urlStr = '$baseUrl/users/with-status?status_tag=$statusTag';
    if (regionId != null) {
      urlStr += '&region_id=$regionId';
    }

    // ignore: avoid_print
    print('[UserRemoteDataSource] GET $urlStr');

    final response = await http
        .get(Uri.parse(urlStr))
        .timeout(const Duration(seconds: 15));

    // ignore: avoid_print
    print('[UserRemoteDataSource] with-status => HTTP ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseBody = json.decode(response.body);
      List rawData = [];
      if (responseBody is List) {
        rawData = responseBody;
      } else if (responseBody is Map && responseBody['data'] is List) {
        rawData = responseBody['data'];
      } else if (responseBody is Map && responseBody['users'] is List) {
        rawData = responseBody['users'];
      }

      // Filter berdasarkan status_tag dan regionId karena BE mengembalikan semua user
      final filtered = rawData.where((e) {
        final tag = (e['status_tag'] ?? '').toString().toLowerCase();
        final matchesTag = tag == statusTag.toLowerCase();
        
        if (!matchesTag) return false;
        if (regionId == null) return true;

        // Cek kecocokan region_id
        final userRegion = e['region_id'] ?? e['regionId'] ?? e['region'];
        String? userRegionStr;
        if (userRegion is Map) {
          userRegionStr = (userRegion['_id'] ?? userRegion['id'])?.toString();
        } else if (userRegion != null) {
          userRegionStr = userRegion.toString();
        }

        return userRegionStr == regionId;
      }).toList();

      return filtered.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception(
      'Gagal mengambil data user dengan status $statusTag '
      '(HTTP ${response.statusCode})',
    );
  }

  // Get Riwayat Iuran dari API
  Future<List<TransactionItemModel>> getRiwayatIuran(String userId, {int? year}) async {
    var urlStr = '$baseUrl/transaction-item/user/$userId';
    if (year != null) {
      urlStr += '?year=$year';
    }
    
    final url = Uri.parse(urlStr);
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
