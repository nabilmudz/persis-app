import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentMethodRemoteDataSource {
  final String baseUrl;
  PaymentMethodRemoteDataSource(this.baseUrl);

  Future<List<dynamic>> getAllMethods() async {
    final response = await http.get(Uri.parse('$baseUrl/payment-method'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Mengembalikan list mentah jika model belum dibuat
    }
    throw Exception('Gagal mengambil metode pembayaran');
  }
}