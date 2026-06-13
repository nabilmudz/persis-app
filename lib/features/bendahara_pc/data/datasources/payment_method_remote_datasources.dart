import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:persis_app/core/helpers/auth_helper.dart';
import '../models/payment_method_model.dart';

class PaymentMethodRemoteDataSource {
  final String baseUrl;
  PaymentMethodRemoteDataSource(this.baseUrl);

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthHelper.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<PaymentMethodModel>> getAllPaymentMethods() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/payment-method'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((e) => PaymentMethodModel.fromJson(e)).toList();
      }
      return <PaymentMethodModel>[];
    } catch (e) {
      return <PaymentMethodModel>[];
    }
  }

  Future<PaymentMethodModel> getOne(String id) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/payment-method/$id'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return PaymentMethodModel.fromJson(json.decode(response.body));
    }
    throw Exception('Gagal mengambil metode pembayaran');
  }

  Future<void> create(PaymentMethodModel paymentMethod) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/payment-method'),
      headers: headers,
      body: jsonEncode(paymentMethod.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Gagal membuat metode pembayaran');
    }
  }

  Future<void> update(String id, PaymentMethodModel paymentMethod) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/payment-method/$id'),
      headers: headers,
      body: jsonEncode(paymentMethod.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate metode pembayaran');
    }
  }

  Future<void> delete(String id) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/payment-method/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus metode pembayaran');
    }
  }
}
