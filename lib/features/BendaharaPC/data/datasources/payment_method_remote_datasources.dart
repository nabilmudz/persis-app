import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_method_model.dart';

class PaymentMethodRemoteDataSource {
  final String baseUrl;
  PaymentMethodRemoteDataSource(this.baseUrl);

  Future<List<PaymentMethodModel>> getAllPaymentMethods() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/payment-method'));
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
    final response = await http.get(Uri.parse('$baseUrl/payment-method/$id'));
    if (response.statusCode == 200) {
      return PaymentMethodModel.fromJson(json.decode(response.body));
    }
    throw Exception('Gagal mengambil metode pembayaran');
  }

  Future<void> create(PaymentMethodModel paymentMethod) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payment-method'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(paymentMethod.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Gagal membuat metode pembayaran');
    }
  }

  Future<void> update(String id, PaymentMethodModel paymentMethod) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/payment-method/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(paymentMethod.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate metode pembayaran');
    }
  }

  Future<void> delete(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/payment-method/$id'),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus metode pembayaran');
    }
  }
}
