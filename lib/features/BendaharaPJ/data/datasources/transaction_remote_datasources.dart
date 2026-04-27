import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';

class TransactionRemoteDataSource {
  final String baseUrl;
  TransactionRemoteDataSource(this.baseUrl);

  // Kirim data transaksi baru
  Future<bool> createTransaction(TransactionModel transaction) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transaction'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(transaction.toJson()),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    print("Error API: ${response.body}"); // Debugging
    return false;
  }

  // Ambil history transaksi
  Future<List<TransactionModel>> getHistory() async {
    final response = await http.get(Uri.parse('$baseUrl/transaction'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => TransactionModel.fromJson(e)).toList();
    }
    throw Exception('Gagal mengambil riwayat transaksi');
  }
}