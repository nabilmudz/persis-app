import 'dart:convert';
import 'package:persis_app/core/network/api_client.dart';
import '../models/transaction_model.dart';

class TransactionRemoteDataSource {
  List<DuesPeriodModel>? _cachedDuesPeriods;

  // Update transaksi yang sudah ada (untuk ACC)
  Future<bool> updateTransaction(
    String transactionId,
    TransactionModel transaction,
  ) async {
    final response = await ApiClient.patch(
      '/transaction/$transactionId',
      body: transaction.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    print("Error API Update: ${response.body}");
    return false;
  }

  // Kirim data transaksi baru
  Future<bool> createTransaction(TransactionModel transaction) async {
    final response = await ApiClient.post(
      '/transaction',
      body: transaction.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    print("Error API: ${response.body}"); // Debugging
    return false;
  }

  // Ambil history transaksi
  Future<List<TransactionModel>> getHistory() async {
    final response = await ApiClient.get('/transaction');
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => TransactionModel.fromJson(e)).toList();
    }
    throw Exception('Gagal mengambil riwayat transaksi');
  }

  // Ambil semua dues periods (dengan cache)
  Future<List<DuesPeriodModel>> getDuesPeriods() async {
    if (_cachedDuesPeriods != null) {
      return _cachedDuesPeriods!;
    }

    try {
      final response = await ApiClient.get('/dues-periods');
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        _cachedDuesPeriods = data
            .map((e) => DuesPeriodModel.fromJson(e))
            .toList();
        return _cachedDuesPeriods!;
      }
      throw Exception('Failed to fetch dues periods: ${response.statusCode}');
    } catch (e) {
      throw Exception('Gagal mengambil dues periods: $e');
    }
  }

  // Ambil dues period berdasarkan bulan dan tahun
  Future<DuesPeriodModel?> getDuesPeriodByMonthYear({
    required int month,
    required int year,
  }) async {
    try {
      final allPeriods = await getDuesPeriods();
      return allPeriods.firstWhere(
        (period) => period.month == month && period.year == year,
        orElse: () => throw Exception('Dues period not found for $month/$year'),
      );
    } catch (e) {
      print('Error getting dues period for $month/$year: $e');
      return null;
    }
  }
}
