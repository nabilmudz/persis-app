import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:persis_app/core/network/api_client.dart';
import '../models/transaction_item_detail_model.dart';
import '../models/transaction_model.dart';

class TransactionRemoteDataSource {
  Map<String, dynamic> _buildCreatePayload(TransactionModel transaction) {
    final payload = Map<String, dynamic>.from(transaction.toJson());
    
    // Pastikan status dan acc_status sesuai enum NestJS
    payload['status'] = transaction.status ?? 'completed';
    payload['acc_status'] = transaction.accStatus ?? 'acc_pj';
    
    // Tetap kirim _id agar relasi items tetap terjaga (local-first)
    // Server menggunakan String untuk _id jadi UUID atau ObjectId string tetap valid
    payload['_id'] = transaction.id;
    payload['id'] = transaction.id;
    
    // Set sync flags agar server tahu data ini sudah tersinkron dari client
    payload['is_synced'] = true;
    payload['synced_at'] = DateTime.now().toIso8601String();

    final items = (payload['items'] as List?)?.map((item) {
      final itemMap = Map<String, dynamic>.from(item as Map);
      itemMap.remove('status');
      return itemMap;
    }).toList();

    payload['items'] = items;
    return payload;
  }



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
        body: _buildCreatePayload(transaction),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      debugPrint(
        'Error API Create Transaction: ${response.statusCode} - ${response.body}',
      );
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
              (e) => TransactionItemDetailModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      return <TransactionItemDetailModel>[];
    } catch (e) {
      return <TransactionItemDetailModel>[];
    }
  }

  /// Export transaksi berdasarkan bulan dan tahun.
  /// Endpoint: GET /transaction/export?month={month}&year={year}&type={type}
  Future<Map<String, dynamic>?> exportTransactions(int month, int year, {String? type}) async {
    try {
      String url = '/transaction/export?month=$month&year=$year';
      if (type != null) url += '&type=$type';

      final response = await ApiClient.get(url);
      final decoded = json.decode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
      }
      
      if (decoded is Map && decoded.containsKey('message')) {
        return {'message': decoded['message']};
      }
      
      debugPrint("Error API Export: ${response.statusCode} - ${response.body}");
      return null;
    } catch (e) {
      debugPrint("Error API Export: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMembersPaymentStatus({
    required int year,
    String? regionId,
  }) async {
    try {
      var url = '/transaction/members-payment-status?year=$year';
      final normalizedRegionId = regionId?.trim();
      if (normalizedRegionId != null && normalizedRegionId.isNotEmpty) {
        url += '&region_id=$normalizedRegionId';
      }

      final response = await ApiClient.get(url);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        return decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded as Map);
      }

      debugPrint(
        'Error API Members Payment Status: ${response.statusCode} - ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('Error API Members Payment Status: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchSummary({
    required int year,
    int month = 0,
  }) async {
    try {
      final response = await ApiClient.get(
        '/transaction/export?month=$month&year=$year',
      );
      final decoded = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return decoded is Map<String, dynamic> ? decoded : null;
      }
      debugPrint(
        '[fetchSummary] Error: ${response.statusCode} - ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('[fetchSummary] Exception: $e');
      return null;
    }
  }
}
