import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/payment_model.dart';

class PaymentRemoteDataSource {
  final String baseUrl;
  PaymentRemoteDataSource(this.baseUrl);

  Future<Map<String, dynamic>> submitPayment(PaymentModel payment) async {
    final url = Uri.parse('$baseUrl/payments');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payment.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal submit pembayaran');
      }
    } on TimeoutException {
      throw Exception('Server tidak merespon, periksa koneksi internet.');
    }
  }

  Future<String> uploadBukti(File imageFile) async {
    final url = Uri.parse('$baseUrl/payments/upload-bukti');
    try {
      final request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath('bukti', imageFile.path),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['url'] ?? '';
      } else {
        throw Exception('Gagal upload bukti transfer');
      }
    } on TimeoutException {
      throw Exception('Upload timeout, periksa koneksi internet.');
    }
  }

  Future<Map<String, dynamic>> getQrisDetail() async {
    final url = Uri.parse('$baseUrl/payments/qris');
    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      throw Exception('Gagal memuat data QRIS');
    } on TimeoutException {
      throw Exception('Server tidak merespon.');
    }
  }
}
