import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/core/helpers/auth_helper.dart';
import 'package:persis_app/features/bendahara_pj/data/models/transaction_model.dart';

class AnggotaTransactionRemoteDataSource {
  Future<String?> _getToken() async => AuthHelper.getAccessToken();
  Future<List<TransactionModel>> getNonTunaiTransactions(
    String userId, {
    int? year,
  }) async {
    try {
      final token = await _getToken();
      var url = '/transaction?creator_id=$userId';
      if (year != null) url += '&year=$year';

      final response = await ApiClient.get(url, token: token);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        List? rawList;
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          rawList = decoded['data'] as List;
        }
        if (rawList != null) {
          final all = rawList
              .map(
                (e) => TransactionModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();

          return all.where((tx) {
            final pmId = (tx.paymentMethodId ?? '').toLowerCase().trim();
            return pmId != 'tunai' && pmId != 'cash';
          }).toList();
        }
      }
      return <TransactionModel>[];
    } catch (e, stack) {
      debugPrint('Error getNonTunaiTransactions: $e');
      debugPrint('Stacktrace: $stack');
      return <TransactionModel>[];
    }
  }

  Future<Map<String, dynamic>?> getMembersPaymentStatus({
    required int year,
    String? regionId,
    int? month,
  }) async {
    try {
      final token = await _getToken();
      var url = '/transaction/members-payment-status?year=$year';
      if (regionId != null && regionId.trim().isNotEmpty) {
        url += '&region_id=${Uri.encodeQueryComponent(regionId.trim())}';
      }
      if (month != null) {
        url += '&month=$month';
      }

      final response = await ApiClient.get(url, token: token);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return Map<String, dynamic>.from(decoded as Map);
      }
      debugPrint(
        'Error Members Payment Status: ${response.statusCode} - ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('Error getMembersPaymentStatus: $e');
      return null;
    }
  }
}
