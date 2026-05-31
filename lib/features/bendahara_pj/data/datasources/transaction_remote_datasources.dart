import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/core/storage/secure_storage_service.dart';
import 'package:persis_app/features/bendahara_pj/data/models/transaction_item_detail_model.dart';
import 'package:persis_app/features/bendahara_pj/data/models/transaction_model.dart';

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

    payload['acc_by'] = transaction.accBy ?? transaction.creatorId;
    payload['accBy'] = transaction.accBy ?? transaction.creatorId;
    payload['acc_at'] = transaction.accAt ?? transaction.createdAt;
    payload['accAt'] = transaction.accAt ?? transaction.createdAt;
    payload['synced_at'] = DateTime.now().toIso8601String();
    payload['syncedAt'] = payload['synced_at'];

    final items = (payload['items'] as List?)?.map((item) {
      final itemMap = Map<String, dynamic>.from(item as Map);
      itemMap['status'] = 'paid';

      final duesPeriodId = itemMap['dues_period_id']?.toString().trim() ?? '';
      if (RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(duesPeriodId)) {
        itemMap['period_id'] = duesPeriodId;
      }

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
        final decoded = json.decode(response.body);
        List? rawList;
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          rawList = decoded['data'] as List;
        }
        if (rawList != null) {
          return rawList
              .map(
                (e) => TransactionModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
        }
      }
      return <TransactionModel>[];
    } catch (e, stack) {
      debugPrint('Error getHistory: $e');
      debugPrint('Stacktrace: $stack');
      return <TransactionModel>[];
    }
  }

  Future<List<TransactionModel>> getLogTransactions({
    required String creatorId,
    required int year,
    required String regionId,
    required int month,
  }) async {
    try {
      String url =
          '/transaction?creator_id=$creatorId&year=$year&region_id=$regionId&month=$month';
      debugPrint('📡 getLogTransactions URL: $url');
      final response = await ApiClient.get(url);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        List? rawList;
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          rawList = decoded['data'] as List;
        }
        if (rawList != null) {
          return rawList
              .map(
                (e) => TransactionModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
        }
      }
      return <TransactionModel>[];
    } catch (e, stack) {
      debugPrint('Error getLogTransactions: $e');
      debugPrint('Stacktrace: $stack');
      return <TransactionModel>[];
    }
  }

  Future<List<TransactionItemDetailModel>> getTransactionItemsByUser(
    String userId,
  ) async {
    try {
      final response = await ApiClient.get('/transaction-item/user/$userId');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List? rawList;
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          rawList = decoded['data'] as List;
        }
        if (rawList != null) {
          return rawList
              .map(
                (e) => TransactionItemDetailModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
        }
      }
      return <TransactionItemDetailModel>[];
    } catch (e, stack) {
      debugPrint('Error getTransactionItemsByUser: $e');
      debugPrint('Stacktrace: $stack');
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

  Future<List<TransactionModel>> fetchAllExportTransactions() async {
    try {
      final regionId = await _resolveRegionId();
      String url = '/transaction/export';
      if (regionId != null && regionId.isNotEmpty) {
        url += '?region_id=$regionId';
      }

      debugPrint('📡 fetchAllExportTransactions URL: $url');

      final response = await ApiClient.get(url);
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint(
          '⚠️ fetchAllExportTransactions: status ${response.statusCode}',
        );
        return [];
      }

      final decoded = json.decode(response.body);
      final resultMap = decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);

      final rawData = resultMap['data'];
      if (rawData is! List) return [];

      final txList = <TransactionModel>[];
      for (final item in rawData) {
        if (item is! Map) continue;
        final tx = Map<String, dynamic>.from(item);
        final txStatus = tx['status']?.toString() ?? '';
        txList.add(
          TransactionModel.fromJson({
            '_id': tx['_id']?.toString() ?? tx['transaction_id']?.toString(),
            'type': tx['type']?.toString() ?? 'tunai',
            'creator_id': tx['creator_id']?.toString(),
            'total_amount':
                (tx['total_amount'] as num?)?.toInt() ??
                (tx['amount'] as num?)?.toInt() ??
                20000,
            'status': txStatus,
            'acc_status':
                tx['acc_status']?.toString() ??
                (txStatus == 'completed' ? 'acc_pj' : ''),
            'acc_by': tx['acc_by']?.toString(),
            'member_name': tx['member_name']?.toString(),
            'npa': tx['npa']?.toString(),
            'created_at':
                tx['created_at']?.toString() ?? tx['createdAt']?.toString(),
            'items': [
              {
                'anggota_id': tx['creator_id']?.toString(),
                'transaction_id':
                    tx['transaction_id']?.toString() ?? tx['_id']?.toString(),
                'period_id':
                    '${tx['period_year']}-${(tx['period_month'] as int? ?? 1).toString().padLeft(2, '0')}',
                'status': tx['item_status']?.toString() ?? txStatus,
                'amount':
                    (tx['total_amount'] as num?)?.toInt() ??
                    (tx['amount'] as num?)?.toInt() ??
                    20000,
                'description':
                    'Iuran ${tx['period_year']}-${(tx['period_month'] as int? ?? 1).toString().padLeft(2, '0')}',
              },
            ],
          }),
        );
      }

      debugPrint(
        '[fetchAllExportTransactions] ${txList.length} transaksi dimuat',
      );
      return txList;
    } catch (e) {
      debugPrint('[fetchAllExportTransactions] Error: $e');
      return [];
    }
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
                  '_id':
                      tx['_id']?.toString() ?? tx['transaction_id']?.toString(),
                  'type': tx['type']?.toString() ?? type ?? 'tunai',
                  'creator_id': tx['creator_id']?.toString(),
                  'total_amount':
                      (tx['total_amount'] as num?)?.toInt() ??
                      (tx['amount'] as num?)?.toInt() ??
                      (tx['item_amount'] as num?)?.toInt() ??
                      20000,
                  'status': txStatus,
                  'acc_status':
                      tx['acc_status']?.toString() ??
                      (txStatus == 'completed' ? 'acc_pj' : ''),
                  'acc_by': tx['acc_by']?.toString() ?? tx['accBy']?.toString(),
                  'member_name': tx['member_name']?.toString(),
                  'npa': tx['npa']?.toString(),
                  'created_at':
                      tx['created_at']?.toString() ??
                      tx['createdAt']?.toString(),
                  'items': [
                    {
                      'anggota_id': tx['creator_id']?.toString(),
                      'transaction_id':
                          tx['transaction_id']?.toString() ??
                          tx['_id']?.toString(),
                      'period_id':
                          '${tx['period_year'] ?? year}-${(tx['period_month'] ?? month).toString().padLeft(2, '0')}',
                      'status':
                          tx['item_status']?.toString() ??
                          tx['status']?.toString(),
                      'amount':
                          (tx['amount'] as num?)?.toInt() ??
                          (tx['item_amount'] as num?)?.toInt() ??
                          20000,
                      'description':
                          'Iuran ${tx['period_year'] ?? year}-${(tx['period_month'] ?? month).toString().padLeft(2, '0')}',
                    },
                  ],
                };
              })
              .where((e) => e.isNotEmpty)
              .toList();

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
