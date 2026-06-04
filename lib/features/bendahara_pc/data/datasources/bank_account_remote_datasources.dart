import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bank_account_model.dart';

class BankAccountRemoteDataSource {
  final String baseUrl;
  BankAccountRemoteDataSource(this.baseUrl);

  Future<List<BankAccountModel>> getAll() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/bank-account'));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((e) => BankAccountModel.fromJson(e)).toList();
      }
      throw Exception(
        'Gagal mengambil rekening bank: Status ${response.statusCode}',
      );
    } catch (e) {
      print('Bank Account API Error: $e');
      rethrow;
    }
  }

  Future<BankAccountModel> getOne(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/bank-account/$id'));
    if (response.statusCode == 200) {
      return BankAccountModel.fromJson(json.decode(response.body));
    }
    throw Exception('Gagal mengambil rekening bank');
  }

  Future<void> create(BankAccountModel bankAccount) async {
    if (bankAccount.paymentMethodId == null ||
        bankAccount.paymentMethodId!.trim().isEmpty) {
      print('❌ VALIDATION FAILED: payment_method_id adalah null atau kosong');
      throw Exception('payment_method_id tidak boleh kosong');
    }

    final qrisImageBytes = bankAccount.qrisImageBytes;
    if (qrisImageBytes != null && qrisImageBytes.isNotEmpty) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/bank-account'),
      );
      request.fields['payment_method_id'] = bankAccount.paymentMethodId ?? '';

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
          'Gagal membuat rekening bank: Status ${response.statusCode} - ${response.body}',
        );
      }
      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/bank-account'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(bankAccount.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Gagal membuat rekening bank: Status ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> update(String id, BankAccountModel bankAccount) async {
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

      request.fields['payment_method_id'] = bankAccount.paymentMethodId ?? '';

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
          'Gagal mengupdate rekening bank: Status ${response.statusCode} - ${response.body}',
        );
      }
      return;
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/bank-account/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(bankAccount.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate rekening bank');
    }
  }

  Future<void> delete(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/bank-account/$id'));
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus rekening bank');
    }
  }
}
