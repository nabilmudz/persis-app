import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:persis_app/core/network/api_client.dart';
import '../models/transaction_item_detail_model.dart';
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
    debugPrint("Error API Update: ${response.body}");
    return false;
  }

  // Kirim data transaksi baru
  Future<bool> createTransaction(TransactionModel transaction) async {
    try {
      final response = await ApiClient.post(
        '/transaction',
        body: transaction.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      debugPrint('Error API Create Transaction: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error API Create Transaction: $e');
      return false;
    }
  }

  // Ambil history transaksi
  Future<List<TransactionModel>> getHistory() async {
    try {
      final response = await ApiClient.get('/transaction');
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((e) => TransactionModel.fromJson(e)).toList();
      }
      return <TransactionModel>[];
    } catch (_) {
      return <TransactionModel>[];
    }
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
      return <DuesPeriodModel>[];
    } catch (e) {
      return <DuesPeriodModel>[];
    }
  }

  // Ambil dues period berdasarkan bulan dan tahun
  Future<DuesPeriodModel?> getDuesPeriodByMonthYear({
    required int month,
    required int year,
  }) async {
    final allPeriods = await getDuesPeriods();
    for (final period in allPeriods) {
      if (period.month == month && period.year == year) {
        return period;
      }
    }
    return null;
  }

  /// Ambil semua transaction-item milik anggota tertentu.
  /// Endpoint: GET /transaction-item/user/{userId}
  Future<List<TransactionItemDetailModel>> getTransactionItemsByUser(
    String userId,
  ) async {
    try {
      final response = await ApiClient.get('/transaction-item/user/$userId');
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data
            .map(
              (e) =>
                  TransactionItemDetailModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }
      return <TransactionItemDetailModel>[];
    } catch (e) {
      return <TransactionItemDetailModel>[];
    }
  }
}
