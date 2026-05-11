import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/core/network/network_status.dart';
import 'package:persis_app/core/storage/secure_storage_service.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import 'pj_verif_tunai_controller.dart';
import 'pj_transaction_item_controller.dart';

export 'pj_verif_tunai_controller.dart'
    show MemberIuranStatusModel, PjMonthStatus;

class PjController extends ChangeNotifier {
  PjController({
    UserRemoteDataSource? userDataSource,
    TransactionRemoteDataSource? transactionDataSource,
  }) : _userDataSource =
           userDataSource ?? UserRemoteDataSource(ApiClient.baseUrl),
       _transactionDataSource =
           transactionDataSource ?? TransactionRemoteDataSource() {
    _verifController = PjVerifTunaiController(transactions: _transactions);
    _verifController.addListener(_onVerifChanged);
  }

  static const String _cacheBoxName = 'pj_data_cache';

  static Future<void> initCache() async {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      await Hive.openBox(_cacheBoxName);
    }
    await PjTransactionItemController.initCache();
  }

  Box get _cacheBox => Hive.box(_cacheBoxName);

  final UserRemoteDataSource _userDataSource;
  final TransactionRemoteDataSource _transactionDataSource;

  final List<UserModel> _members = [];
  final List<TransactionModel> _transactions = [];

  bool _isLoading = false;
  String? _errorMessage;

  late final PjVerifTunaiController _verifController;

  List<UserModel> get members => List<UserModel>.unmodifiable(_members);
  List<TransactionModel> get transactions =>
      List<TransactionModel>.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadInitialData() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentYear = DateTime.now().year;
      final regionId = await resolveRegionId();

      // 1. Load dari Cache dulu agar UI responsif (Offline-first)
      await _loadFromCache(year: currentYear, regionId: regionId);

      // 2. Coba fetch data terbaru dari Network
      final isOnline = await NetworkStatus.hasInternetConnection();
      if (isOnline) {
        await loadPaymentStatusSnapshot(year: currentYear, regionId: regionId);
      } else {
        if (_members.isEmpty && _transactions.isEmpty) {
          _errorMessage = 'Mode offline: Tidak ada data cache tersedia.';
        }
      }
    } catch (e) {
      debugPrint('[PjController] Error loadInitialData: $e');
      if (_members.isEmpty) {
        _errorMessage = 'Gagal memuat data: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache({int? year, String? regionId}) async {
    try {
      final cachedUsers = _cacheBox.get('members') as List?;
      final cachedTransactions = _cacheBox.get('transactions') as List?;
      final cachedSnapshotMembers = year == null
          ? const <Map<String, dynamic>>[]
          : PjTransactionItemController.cachedMembersFromSnapshot(
              year: year,
              regionId: regionId,
            );

      if (cachedSnapshotMembers.isNotEmpty) {
        _members
          ..clear()
          ..addAll(
            cachedSnapshotMembers.map((e) => UserModel.fromJson(e)).toList(),
          );
      } else if (cachedUsers != null) {
        _members
          ..clear()
          ..addAll(
            cachedUsers
                .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
                .toList(),
          );
      }

      if (cachedTransactions != null) {
        _transactions
          ..clear()
          ..addAll(
            cachedTransactions
                .map(
                  (e) =>
                      TransactionModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(),
          );
        await PjTransactionItemController.cachePeriodsFromTransactions(
          _transactions,
        );
      }

      _verifController.updateData(transactions: _transactions);
    } catch (e) {
      debugPrint('[PjController] Gagal load dari cache: $e');
    }
  }

  Future<void> _fetchAndCacheData() async {
    try {
      final users = await _userDataSource.getAllUsers();
      final transactions = await _transactionDataSource.getHistory();

      final filteredUsers = users
          .where((u) => u.id != null && u.id!.trim().isNotEmpty)
          .toList();

      // Update State
      _members
        ..clear()
        ..addAll(filteredUsers);
      _transactions
        ..clear()
        ..addAll(transactions);
      _verifController.updateData(transactions: _transactions);

      // Save ke Cache
      await _cacheBox.put(
        'members',
        filteredUsers.map((e) => e.toJson()).toList(),
      );
      await _cacheBox.put(
        'transactions',
        transactions.map((e) => e.toJson()).toList(),
      );
      await PjTransactionItemController.cachePeriodsFromTransactions(
        transactions,
      );

      debugPrint('[PjController] Data berhasil di-cache untuk offline.');
    } catch (e) {
      debugPrint('[PjController] Gagal fetch data network: $e');
      // Tetap gunakan data cache jika network gagal
    }
  }

  Future<void> loadPaymentStatusSnapshot({
    required int year,
    String? regionId,
  }) async {
    try {
      final resolvedRegionId = regionId ?? await resolveRegionId();
      final snapshot = await _transactionDataSource.getMembersPaymentStatus(
        year: year,
        regionId: resolvedRegionId,
      );

      if (snapshot == null) {
        await _fetchAndCacheData();
        return;
      }

      await PjTransactionItemController.cacheMembersPaymentStatusSnapshot(
        snapshot,
      );

      final snapshotMembers =
          PjTransactionItemController.cachedMembersFromSnapshot(
        year: year,
        regionId: resolvedRegionId,
      );
      if (snapshotMembers.isNotEmpty) {
        _members
          ..clear()
          ..addAll(snapshotMembers.map((e) => UserModel.fromJson(e)).toList());
        await _cacheBox.put(
          'members',
          _members.map((member) => member.toJson()).toList(),
        );
      }

      _transactions
        ..clear()
        ..addAll(_transactionsFromPaymentSnapshot(snapshot));
      await _cacheBox.put(
        'transactions',
        _transactions.map((e) => e.toJson()).toList(),
      );

      _verifController.updateData(transactions: _transactions);
      debugPrint('[PjController] Snapshot status pembayaran berhasil di-cache.');
    } catch (e) {
      debugPrint('[PjController] Gagal load snapshot status pembayaran: $e');
      await _fetchAndCacheData();
    }
  }

  Future<String?> resolveRegionId() async {
    final token = await SecureStorageService.read(
      SecureStorageService.accessTokenKey,
    );

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      final payload = _decodeJwtPayload(parts[1]);
      return _extractRegionId(payload);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String payloadPart) {
    final normalized = base64Url.normalize(payloadPart);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payload = jsonDecode(decoded);

    if (payload is Map<String, dynamic>) {
      return payload;
    }

    return <String, dynamic>{};
  }

  String? _extractRegionId(Map<String, dynamic> json) {
    final directCandidates = <dynamic>[
      json['region_id'],
      json['regionId'],
      json['region'],
    ];

    for (final candidate in directCandidates) {
      final resolved = _extractIdValue(candidate);
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    }

    for (final value in json.values) {
      if (value is Map<String, dynamic>) {
        final nested = _extractRegionId(value);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return null;
  }

  String? _extractIdValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (value is Map<String, dynamic>) {
      final nestedCandidates = <dynamic>[
        value['_id'],
        value['id'],
        value['region_id'],
        value['regionId'],
      ];

      for (final nested in nestedCandidates) {
        final resolved = _extractIdValue(nested);
        if (resolved != null && resolved.isNotEmpty) {
          return resolved;
        }
      }
    }

    return null;
  }

  List<TransactionModel> _transactionsFromPaymentSnapshot(
    Map<String, dynamic> snapshot,
  ) {
    final transactions = <TransactionModel>[];
    final members = snapshot['members'];
    if (members is! List) {
      return transactions;
    }

    for (final rawMember in members) {
      if (rawMember is! Map) continue;
      final member = Map<String, dynamic>.from(rawMember);
      final memberId = (member['_id'] ?? member['id'])?.toString();
      if (memberId == null || memberId.isEmpty) continue;

      final payments = member['payments'];
      if (payments is! List) continue;

      for (final rawPayment in payments) {
        if (rawPayment is! Map) continue;
        final payment = Map<String, dynamic>.from(rawPayment);
        final month = (payment['month'] as num?)?.toInt();
        final year = (payment['year'] as num?)?.toInt();
        if (month == null || year == null) continue;

        final status = payment['status']?.toString() ?? 'pending';
        final amount = (payment['amount'] as num?)?.toInt() ?? 20000;
        final periodKey = PjTransactionItemController.localPeriodKey(
          month,
          year,
        );

        transactions.add(
          TransactionModel(
            id:
                payment['transaction_id']?.toString() ??
                'snapshot-$memberId-$periodKey',
            type: 'tunai',
            creatorId: memberId,
            totalAmount: amount,
            status: status == 'paid' ? 'completed' : status,
            memberName: member['fullname']?.toString(),
            npa: member['npa']?.toString(),
            items: [
              TransactionItemModel(
                anggotaId: memberId,
                transactionId: payment['transaction_id']?.toString(),
                periodId: periodKey,
                duesPeriodId: payment['period_id']?.toString(),
                status: status,
                amount: amount,
                description: 'Iuran $periodKey',
              ),
            ],
          ),
        );
      }
    }

    return transactions;
  }

  void _onVerifChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _verifController.removeListener(_onVerifChanged);
    _verifController.dispose();
    super.dispose();
  }

  String memberDisplayName(UserModel member) {
    final name = member.fullname?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final code = member.npa?.trim();
    if (code != null && code.isNotEmpty) {
      return code;
    }

    final email = member.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Unknown Member';
  }

  String memberDisplayCode(UserModel member) {
    return (member.code ?? '').trim();
  }

  List<UserModel> filterMembers(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return members;
    }

    return _members.where((member) {
      final name = (member.name ?? '').toLowerCase();
      final code = (member.code ?? '').toLowerCase();
      final email = (member.email ?? '').toLowerCase();
      return name.contains(trimmed) ||
          code.contains(trimmed) ||
          email.contains(trimmed);
    }).toList();
  }

  int tunggakanCountByMember(String anggotaId) {
    return _verifController.tunggakanCountByMember(anggotaId);
  }

  double tunggakanNominalByMember(String anggotaId) {
    return _verifController.tunggakanNominalByMember(anggotaId);
  }

  List<MemberIuranStatusModel> memberIuranStatusItems(
    String anggotaId, {
    int limit = 4,
  }) {
    return _verifController.memberPeriodStatusItems(anggotaId, limit: limit);
  }

  List<String> memberIuranStatusLabels(String anggotaId, {int limit = 4}) {
    return _verifController.memberPeriodStatusLabels(anggotaId, limit: limit);
  }

  PjMonthStatus memberCardStatus(String anggotaId) {
    return _verifController.memberCardStatus(anggotaId);
  }

  double getNominalForMemberMonth({
    required String anggotaId,
    required int month,
    required int year,
  }) {
    return _verifController.getNominalForMemberMonth(
      anggotaId: anggotaId,
      month: month,
      year: year,
    );
  }

  PjMonthStatus getMonthStatus({
    required String anggotaId,
    required int month,
    int? year,
  }) {
    return _verifController.getMonthStatus(
      anggotaId: anggotaId,
      month: month,
      year: year,
    );
  }
}
