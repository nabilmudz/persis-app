import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/core/storage/secure_storage_service.dart';
import '../models/transaction_item_detail_model.dart';
import '../models/transaction_model.dart';

class TransactionRemoteDataSource {
  Map<String, dynamic> _buildCreatePayload(TransactionModel transaction) {
    final payload = Map<String, dynamic>.from(transaction.toJson());

    payload['status'] = transaction.status ?? 'completed';
    payload['acc_status'] = transaction.accStatus ?? 'acc_pj';
    payload['_id'] = transaction.id;
    payload['id'] = transaction.id;
    payload['is_synced'] = true;
    payload['isSynced'] = true;
    payload['synced_at'] = DateTime.now().toIso8601String();
    payload['syncedAt'] = payload['synced_at'];

    if (transaction.accBy != null) {
      payload['acc_by'] = transaction.accBy;
      payload['accBy'] = transaction.accBy;
    }
    if (transaction.accAt != null) {
      payload['acc_at'] = transaction.accAt;
      payload['accAt'] = transaction.accAt;
    }

    final items = (payload['items'] as List?)?.map((item) {
      final itemMap = Map<String, dynamic>.from(item as Map);
      itemMap.remove('status');
      return itemMap;
    }).toList();

    payload['items'] = items;
    return payload;
  }

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

  Future<String?> _resolveRegionId() async {
    final storedRegion = await SecureStorageService.read('region_id');
    if (storedRegion != null && storedRegion.trim().isNotEmpty) {
      return storedRegion.trim();
    }

    final token = await SecureStorageService.read(
      SecureStorageService.accessTokenKey,
    );
    if (token == null || token.trim().isEmpty) return null;

    final parts = token.split('.');
    if (parts.length < 2) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is Map<String, dynamic>) {
        final candidates = [
          payload['region_id'],
          payload['regionId'],
          payload['region'],
        ];
        for (final c in candidates) {
          if (c is String && c.trim().isNotEmpty) return c.trim();
          if (c is Map) {
            final id = c['_id'] ?? c['id'] ?? c['region_id'] ?? c['regionId'];
            if (id is String && id.trim().isNotEmpty) return id.trim();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> exportTransactions(
    int month,
    int year, {
    String? type,
    String? status,
  }) async {
    try {
      final regionId = await _resolveRegionId();
      String url = '/transaction/export?month=$month&year=$year';
      if (regionId != null && regionId.isNotEmpty) {
        url += '&region_id=$regionId';
      }

      debugPrint('📡 exportTransactions URL: $url');

      final response = await ApiClient.get(url);
      final decoded = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resultMap = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded as Map);

        final rawData = resultMap['data'];
        if (rawData is List) {
          final List<Map<String, dynamic>> txList = rawData
              .map((item) {
                if (item is! Map) return <String, dynamic>{};
                final tx = Map<String, dynamic>.from(item);
                final txStatus = tx['status']?.toString() ?? '';

            return <String, dynamic>{
              '_id': tx['_id']?.toString() ?? tx['transaction_id']?.toString(),
              'type': tx['type']?.toString() ?? type ?? 'tunai',
              'creator_id': tx['creator_id']?.toString(),
              'total_amount': (tx['amount'] as num?)?.toInt() ?? (tx['item_amount'] as num?)?.toInt() ?? 20000,
              'status': txStatus,
              // Pastikan acc_status terisi agar lolos filter UI
              'acc_status': tx['acc_status']?.toString() ??
                  (txStatus == 'completed' ? 'acc_pj' : ''),
              'member_name': tx['member_name']?.toString(),
              'npa': tx['npa']?.toString(),
              'created_at': tx['created_at']?.toString() ?? tx['createdAt']?.toString(),
              // Bangun items dari field period_month/period_year di response
              'items': [
                {
                  'anggota_id': tx['creator_id']?.toString(),
                  'transaction_id': tx['transaction_id']?.toString() ?? tx['_id']?.toString(),
                  'period_id':
                      '${tx['period_year'] ?? year}-${(tx['period_month'] ?? month).toString().padLeft(2, '0')}',
                  'status': tx['item_status']?.toString() ?? tx['status']?.toString(),
                  'amount': (tx['amount'] as num?)?.toInt() ?? (tx['item_amount'] as num?)?.toInt() ?? 20000,
                  'description':
                      'Iuran ${tx['period_year'] ?? year}-${(tx['period_month'] ?? month).toString().padLeft(2, '0')}',
                }
              ],
            };
          }).where((e) => e.isNotEmpty).toList();

          debugPrint(
            '📊 exportTransactions: ${txList.length} transaksi untuk bulan=$month/$year',
          );
          resultMap['data'] = txList;
        }

        return resultMap;
      }

      if (decoded is Map && decoded.containsKey('message')) {
        return {'message': decoded['message'].toString()};
      }

      debugPrint(
        "Error API exportTransactions: ${response.statusCode} - ${response.body}",
      );
      return null;
    } catch (e) {
      debugPrint("Error API exportTransactions: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMembersPaymentStatus({
    required int year,
    String? regionId,
    int? month,
  }) async {
    try {
      var url = '/transaction/members-payment-status?year=$year';
      final normalizedRegionId = regionId?.trim();
      if (normalizedRegionId != null && normalizedRegionId.isNotEmpty) {
        url += '&region_id=$normalizedRegionId';
      }
      if (month != null) {
        url += '&month=$month';
      }

      final response = await ApiClient.get(url);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        final result = decoded is Map<String, dynamic>
            ? Map<String, dynamic>.from(decoded)
            : Map<String, dynamic>.from(decoded as Map);

        if (month != null) {
          final meta = result['meta'] is Map
              ? Map<String, dynamic>.from(result['meta'] as Map)
              : <String, dynamic>{};
          meta['month'] = month;
          result['meta'] = meta;
        }

        return result;
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
    String? status,
  }) async {
    try {
      var url = '/transaction/export?month=$month&year=$year';
      final normalizedStatus = status?.trim();
      if (normalizedStatus != null && normalizedStatus.isNotEmpty) {
        url += '&status=$normalizedStatus';
      }

      final response = await ApiClient.get(url);
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
