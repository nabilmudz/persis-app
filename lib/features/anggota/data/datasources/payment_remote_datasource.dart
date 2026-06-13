import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PaymentRemoteDataSource {
  final String baseUrl;
  PaymentRemoteDataSource(this.baseUrl);
  Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> payload, {
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/transaction');
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .post(url, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal membuat transaksi');
      }
    } on TimeoutException {
      throw Exception('Server tidak merespon, periksa koneksi internet.');
    }
  }

  Future<String> uploadBukti(File imageFile, {String? token}) async {
    final url = Uri.parse('$baseUrl/transaction-item/upload-bukti');
    try {
      final request = http.MultipartRequest('POST', url);

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['bukti_url'] as String? ?? '';
      } else {
        throw Exception('Gagal upload bukti transfer');
      }
    } on TimeoutException {
      throw Exception('Upload timeout, periksa koneksi internet.');
    }
  }
}
