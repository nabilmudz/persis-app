import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:persis_app/core/helpers/auth_helper.dart';
import '../models/bank_account_model.dart';

class BankAccountRemoteDataSource {
  final String baseUrl;
  BankAccountRemoteDataSource(this.baseUrl);

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthHelper.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<BankAccountModel>> getAll() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/bank-account'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List rawList;
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          rawList = decoded['data'] as List;
        } else {
          return <BankAccountModel>[];
        }
        return rawList
            .map((e) => BankAccountModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }
      throw Exception(
        'Gagal mengambil rekening bank: Status ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<BankAccountModel> getOne(String id) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/bank-account/$id'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final map = decoded is Map<String, dynamic>
          ? decoded
          : (decoded['data'] is Map ? Map<String, dynamic>.from(decoded['data']) : <String, dynamic>{});
      return BankAccountModel.fromJson(map);
    }
    throw Exception('Gagal mengambil rekening bank');
  }

  Future<void> create(BankAccountModel bankAccount) async {
    final token = await AuthHelper.getAccessToken();

    if (bankAccount.paymentMethodId == null ||
        bankAccount.paymentMethodId!.trim().isEmpty) {
      throw Exception('payment_method_id tidak boleh kosong');
    }

    final qrisImageBytes = bankAccount.qrisImageBytes;
    if (qrisImageBytes != null && qrisImageBytes.isNotEmpty) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/bank-account'),
      );

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['payment_method_id'] = bankAccount.paymentMethodId ?? '';
      request.fields['bank_name'] = bankAccount.bankName ?? '';
      request.fields['account_number'] = bankAccount.accountNumber ?? '';
      if (bankAccount.isActive != null) {
        request.fields['is_active'] = bankAccount.isActive.toString();
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'qris_image_url',
          qrisImageBytes,
          filename: bankAccount.qrisImageName ?? 'qris.png',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Gagal membuat rekening bank: Status ${response.statusCode}',
        );
      }
      return;
    }

    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/bank-account'),
      headers: headers,
      body: jsonEncode(bankAccount.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Gagal membuat rekening bank: Status ${response.statusCode}',
      );
    }
  }

  Future<void> update(String id, BankAccountModel bankAccount) async {
    final token = await AuthHelper.getAccessToken();

    if (bankAccount.paymentMethodId == null ||
        bankAccount.paymentMethodId!.trim().isEmpty) {
      throw Exception('payment_method_id tidak boleh kosong');
    }

    final qrisImageBytes = bankAccount.qrisImageBytes;
    if (qrisImageBytes != null && qrisImageBytes.isNotEmpty) {
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/bank-account/$id'),
      );

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['payment_method_id'] = bankAccount.paymentMethodId ?? '';
      request.fields['bank_name'] = bankAccount.bankName ?? '';
      request.fields['account_number'] = bankAccount.accountNumber ?? '';
      if (bankAccount.isActive != null) {
        request.fields['is_active'] = bankAccount.isActive.toString();
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'qris_image_url',
          qrisImageBytes,
          filename: bankAccount.qrisImageName ?? 'qris.png',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengupdate rekening bank: Status ${response.statusCode}',
        );
      }
      return;
    }

    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/bank-account/$id'),
      headers: headers,
      body: jsonEncode(bankAccount.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate rekening bank');
    }
  }

  Future<void> delete(String id) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/bank-account/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus rekening bank');
    }
  }
}
