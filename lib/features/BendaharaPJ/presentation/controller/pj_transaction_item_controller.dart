import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:persis_app/core/storage/hive_service.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_item_detail_model.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'pj_verif_tunai_controller.dart';

///   - [PjMonthStatus.paid]
///   - [PjMonthStatus.tunggakan]
///   - [PjMonthStatus.pending]
class PjTransactionItemController extends ChangeNotifier {
  PjTransactionItemController({TransactionRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? TransactionRemoteDataSource();

  final TransactionRemoteDataSource _dataSource;

  static const String _cacheBoxName = 'pj_item_cache';
  static const String _periodCacheBoxName = 'pj_dues_period_cache';
  static const String _snapshotCacheBoxName = 'pj_members_payment_status_cache';

  static Future<void> initCache() async {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      await Hive.openBox(_cacheBoxName);
    }
    if (!Hive.isBoxOpen(_periodCacheBoxName)) {
      await Hive.openBox(_periodCacheBoxName);
    }
    if (!Hive.isBoxOpen(_snapshotCacheBoxName)) {
      await Hive.openBox(_snapshotCacheBoxName);
    }
  }

  Box get _cacheBox => HiveService.box(_cacheBoxName);
  static Box get _itemCacheBox => Hive.box(_cacheBoxName);
  static Box get _periodCacheBox => Hive.box(_periodCacheBoxName);
  static Box get _snapshotCacheBox => Hive.box(_snapshotCacheBoxName);

  bool _isLoading = false;
  String? _errorMessage;

  /// Map dari key "$year-$month" → [PjMonthStatus]
  final Map<String, PjMonthStatus> _monthStatusMap = {};

  /// Map dari key "$year-$month" → nominal iuran
  final Map<String, int> _monthAmountMap = {};

  /// Map dari key "$year-$month" → periodId (Mongo ID)
  final Map<String, String?> _monthPeriodIdMap = {};

  List<TransactionItemDetailModel> _items = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TransactionItemDetailModel> get items => List.unmodifiable(_items);

  List<TransactionItemDetailModel> get completed => _items.where((item) {
    final s = (item.status ?? '').trim().toLowerCase();
    return s == 'paid' || s == 'paid';
  }).toList();

  List<TransactionItemDetailModel> get tunggakanItems => _items.where((item) {
    final s = (item.status ?? '').trim().toLowerCase();
    return s == 'tunggakan' || s == 'overdue';
  }).toList();

  List<TransactionItemDetailModel> get uncompleted => _items.where((item) {
    final s = (item.status ?? '').trim().toLowerCase();
    return s != 'paid' && s != 'paid' && s != 'tunggakan' && s != 'overdue';
  }).toList();

  Future<void> loadByUser(
    String userId, {
    bool forceRefresh = false,
    int? year,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var hasUsableCache = false;
      if (!forceRefresh) {
        final rawCache = _cacheBox.get(userId);
        if (rawCache is List) {
          final cachedItems = <TransactionItemDetailModel>[];
          for (final e in rawCache) {
            try {
              if (e is Map) {
                cachedItems.add(
                  TransactionItemDetailModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                );
              }
            } catch (_) {}
          }
          if (cachedItems.isNotEmpty) {
            _buildStatusMap(_filterItemsByYear(cachedItems, year));
            await cachePeriodsFromTransactionItems(cachedItems);
            hasUsableCache = true;
            notifyListeners();
          }
        }
      } else {
        await _cacheBox.delete(userId);
      }

      final freshItems = await _dataSource.getTransactionItemsByUser(userId);
      if (freshItems.isEmpty && hasUsableCache) {
        return;
      }

      try {
        await _cacheBox.put(userId, freshItems.map((e) => e.toJson()).toList());
        await cachePeriodsFromTransactionItems(freshItems);
      } catch (cacheError) {
        debugPrint(
          '[PjTransactionItemController] Gagal simpan cache: $cacheError',
        );
      }

      _buildStatusMap(_filterItemsByYear(freshItems, year));
    } catch (e) {
      debugPrint('[PjTransactionItemController] Error loadByUser: $e');
      if (_monthStatusMap.isEmpty) {
        _errorMessage = 'Gagal memuat data iuran: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _buildStatusMap(List<TransactionItemDetailModel> items) {
    _items = List.of(items);
    _monthStatusMap.clear();
    _monthAmountMap.clear();
    _monthPeriodIdMap.clear();

    for (final item in items) {
      final month = item.resolveMonth();
      final year = item.resolveYear();
      if (month == null || year == null) continue;

      final key = _key(month, year);
      final rawStatus = (item.status ?? '').trim().toLowerCase();

      final PjMonthStatus newStatus = switch (rawStatus) {
        'paid' || 'lunas' || 'completed' => PjMonthStatus.paid,
        'tunggakan' || 'overdue' => PjMonthStatus.tunggakan,
        _ => PjMonthStatus.pending,
      };

      // Jika entry sebelumnya sudah paid, jangan overwrite
      final existing = _monthStatusMap[key];
      if (existing == PjMonthStatus.paid) continue;

      _monthStatusMap[key] = newStatus;

      // Ambil nominal dari item, fallback ke info dues_period jika ada, default ke 20000
      final nominal = (item.amount != null && item.amount! > 0)
          ? item.amount!
          : (item.duesPeriod?.amount?.round() ?? 20000);

      if (nominal > 0) {
        _monthAmountMap[key] = nominal;
      }

      // Simpan periodId untuk digunakan saat create transaction
      final periodId =
          item.periodId ?? item.duesPeriodId ?? item.duesPeriod?.id;
      if (periodId != null) {
        _monthPeriodIdMap[key] = periodId;
      }
    }
  }

  /// Status warna kartu bulan tertentu.
  PjMonthStatus getMonthStatus(int month, int year) {
    // ✅ FIX: jika bulan tidak ada di map sama sekali → pending
    // (bukan tunggakan — bisa jadi period belum dibuat di backend)
    final cachedStatus = _monthStatusMap[_key(month, year)];
    if (cachedStatus != null) {
      return cachedStatus;
    }

    final now = DateTime.now();
    final isPastPeriod =
        year < now.year || (year == now.year && month < now.month);
    return isPastPeriod ? PjMonthStatus.tunggakan : PjMonthStatus.pending;
  }

  /// Nominal iuran bulan tertentu (0 jika tidak ada data).
  int getMonthAmount(int month, int year) {
    return _monthAmountMap[_key(month, year)] ?? 0;
  }

  /// Mendapatkan periodId (Mongo ID) untuk bulan/tahun tertentu.
  String? getMonthPeriodId(int month, int year) {
    return _monthPeriodIdMap[_key(month, year)] ??
        getCachedPeriodId(month: month, year: year);
  }

  List<TransactionItemDetailModel> _filterItemsByYear(
    List<TransactionItemDetailModel> items,
    int? year,
  ) {
    if (year == null) {
      return items;
    }

    return items.where((item) => item.resolveYear() == year).toList();
  }

  Future<void> markMonthsPaidLocally({
    required String anggotaId,
    required Iterable<int> months,
    required int year,
    required int Function(int month, int year) getNominal,
    required String Function(int month, int year) getPeriodId,
  }) async {
    final mergedItems = List<TransactionItemDetailModel>.from(_items);

    for (final month in months) {
      final key = _key(month, year);
      final periodId = getPeriodId(month, year);
      final amount = getNominal(month, year);

      _monthStatusMap[key] = PjMonthStatus.paid;
      _monthAmountMap[key] = amount;
      _monthPeriodIdMap[key] = periodId;
      await cachePeriodId(month: month, year: year, periodId: periodId);

      mergedItems.removeWhere((item) {
        return item.anggotaId == anggotaId &&
            item.resolveMonth() == month &&
            item.resolveYear() == year;
      });
      mergedItems.add(
        TransactionItemDetailModel(
          anggotaId: anggotaId,
          periodId: periodId,
          duesPeriodId: periodId,
          status: 'paid',
          amount: amount,
          description: 'Iuran ${_monthName(month)} $year',
          duesPeriod: DuesPeriodInfo(
            id: periodId,
            month: month,
            year: year,
            amount: amount.toDouble(),
          ),
        ),
      );
    }

    _items = mergedItems;
    await _cacheBox.put(anggotaId, mergedItems.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  /// Total tunggakan dalam rupiah.
  int get totalTunggakan {
    int total = 0;
    for (final entry in _monthStatusMap.entries) {
      if (entry.value == PjMonthStatus.tunggakan) {
        total += _monthAmountMap[entry.key] ?? 0;
      }
    }
    return total;
  }

  /// Jumlah bulan tunggakan.
  int get tunggakanCount =>
      _monthStatusMap.values.where((s) => s == PjMonthStatus.tunggakan).length;

  static String _key(int month, int year) =>
      '$year-${month.toString().padLeft(2, '0')}';

  static Future<void> cachePeriodId({
    required int month,
    required int year,
    required String? periodId,
  }) async {
    final normalized = periodId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }

    if (!Hive.isBoxOpen(_periodCacheBoxName)) {
      await Hive.openBox(_periodCacheBoxName);
    }

    final cacheKey = _key(month, year);
    final existing = _periodCacheBox.get(cacheKey);
    if (_looksLikeBackendId(existing?.toString() ?? '') &&
        !_looksLikeBackendId(normalized)) {
      return;
    }

    await _periodCacheBox.put(cacheKey, normalized);
  }

  static String? getCachedPeriodId({required int month, required int year}) {
    if (!Hive.isBoxOpen(_periodCacheBoxName)) {
      return null;
    }

    final value = _periodCacheBox.get(_key(month, year));
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  static Future<void> cachePeriodsFromTransactionItems(
    Iterable<TransactionItemDetailModel> items,
  ) async {
    for (final item in items) {
      final month = item.resolveMonth();
      final year = item.resolveYear();
      final periodId = item.periodId ?? item.duesPeriodId ?? item.duesPeriod?.id;
      if (month != null && year != null) {
        await cachePeriodId(month: month, year: year, periodId: periodId);
      }
    }
  }

  static Future<void> cachePeriodsFromTransactions(
    Iterable<TransactionModel> transactions,
  ) async {
    for (final transaction in transactions) {
      for (final item in transaction.items ?? const <TransactionItemModel>[]) {
        final parsed = _parseMonthYear(item.description);
        final periodId = item.periodId ?? item.duesPeriodId;
        if (parsed != null) {
          await cachePeriodId(
            month: parsed.month,
            year: parsed.year,
            periodId: periodId,
          );
        }
      }
    }
  }

  static Future<void> cacheMembersPaymentStatusSnapshot(
    Map<String, dynamic> snapshot,
  ) async {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      await Hive.openBox(_cacheBoxName);
    }
    if (!Hive.isBoxOpen(_periodCacheBoxName)) {
      await Hive.openBox(_periodCacheBoxName);
    }
    if (!Hive.isBoxOpen(_snapshotCacheBoxName)) {
      await Hive.openBox(_snapshotCacheBoxName);
    }

    final meta = snapshot['meta'] is Map
        ? Map<String, dynamic>.from(snapshot['meta'] as Map)
        : <String, dynamic>{};
    final year = (meta['year'] as num?)?.toInt();
    final regionId = meta['region_id']?.toString();
    final month = (meta['month'] as num?)?.toInt();
    if (year != null) {
      await _snapshotCacheBox.put(
        _snapshotKey(year, regionId, month),
        snapshot,
      );
      await _snapshotCacheBox.put(_snapshotKey(year, regionId, null), snapshot);
      await _snapshotCacheBox.put(_snapshotKey(year, null, month), snapshot);
      await _snapshotCacheBox.put(_snapshotKey(year, null, null), snapshot);
    }

    final duesPeriods = snapshot['dues_periods'];
    if (duesPeriods is List) {
      for (final rawPeriod in duesPeriods) {
        if (rawPeriod is! Map) continue;
        final period = Map<String, dynamic>.from(rawPeriod);
        final month = (period['month'] as num?)?.toInt();
        final periodYear = (period['year'] as num?)?.toInt();
        final periodId = period['_id'] ?? period['id'];
        if (month != null && periodYear != null) {
          await cachePeriodId(
            month: month,
            year: periodYear,
            periodId: periodId?.toString(),
          );
        }
      }
    }

    final members = snapshot['members'];
    if (members is! List) {
      return;
    }

    for (final rawMember in members) {
      if (rawMember is! Map) continue;
      final member = Map<String, dynamic>.from(rawMember);
      final memberId = (member['_id'] ?? member['id'])?.toString();
      if (memberId == null || memberId.trim().isEmpty) continue;

      final cachedItems = <TransactionItemDetailModel>[];
      final payments = member['payments'];
      if (payments is List) {
        for (final rawPayment in payments) {
          if (rawPayment is! Map) continue;
          final payment = Map<String, dynamic>.from(rawPayment);
          final month = (payment['month'] as num?)?.toInt();
          final paymentYear = (payment['year'] as num?)?.toInt();
          if (month == null || paymentYear == null) continue;

          final periodId = payment['period_id']?.toString();
          final amount = (payment['amount'] as num?)?.toInt() ?? 20000;
          await cachePeriodId(
            month: month,
            year: paymentYear,
            periodId: periodId,
          );

          cachedItems.add(
            TransactionItemDetailModel(
              anggotaId: memberId,
              transactionId: payment['transaction_id']?.toString(),
              periodId: periodId,
              duesPeriodId: periodId,
              status: payment['status']?.toString(),
              amount: amount,
              description: 'Iuran ${_monthName(month)} $paymentYear',
              duesPeriod: DuesPeriodInfo(
                id: periodId,
                month: month,
                year: paymentYear,
                amount: amount.toDouble(),
              ),
            ),
          );
        }
      }

      if (cachedItems.isNotEmpty) {
        await _itemCacheBox.put(
          memberId,
          cachedItems.map((item) => item.toJson()).toList(),
        );
      }
    }
  }

  static List<Map<String, dynamic>> cachedMembersFromSnapshot({
    required int year,
    String? regionId,
    int? month,
  }) {
    if (!Hive.isBoxOpen(_snapshotCacheBoxName)) {
      return const <Map<String, dynamic>>[];
    }

    final snapshot = _snapshotCacheBox.get(_snapshotKey(year, regionId, month))
        ?? _snapshotCacheBox.get(_snapshotKey(year, regionId, null))
        ?? _snapshotCacheBox.get(_snapshotKey(year, null, month))
        ?? _snapshotCacheBox.get(_snapshotKey(year, null, null));
    if (snapshot is! Map) {
      return const <Map<String, dynamic>>[];
    }

    final members = Map<String, dynamic>.from(snapshot)['members'];
    if (members is! List) {
      return const <Map<String, dynamic>>[];
    }

    return members.whereType<Map>().map((member) {
      final map = Map<String, dynamic>.from(member);
      return <String, dynamic>{
        '_id': map['_id'] ?? map['id'],
        'id': map['_id'] ?? map['id'],
        'fullname': map['fullname'],
        'name': map['fullname'] ?? map['name'],
        'npa': map['npa'],
      };
    }).toList();
  }

  static String localPeriodKey(int month, int year) => _key(month, year);

  static String _snapshotKey(int year, String? regionId, int? month) {
    final normalizedRegionId = regionId?.trim();
    final normalizedMonth = month?.toString().padLeft(2, '0');
    if (normalizedRegionId == null || normalizedRegionId.isEmpty) {
      return normalizedMonth == null ? '$year' : '$year-$normalizedMonth';
    }
    return normalizedMonth == null
        ? '$year-$normalizedRegionId'
        : '$year-$normalizedRegionId-$normalizedMonth';
  }

  static bool _looksLikeBackendId(String value) {
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value.trim());
  }

  static _ParsedPeriod? _parseMonthYear(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final numericMatch = RegExp(r'(\d{4})[-_/](\d{1,2})').firstMatch(raw);
    if (numericMatch != null) {
      final year = int.tryParse(numericMatch.group(1)!);
      final month = int.tryParse(numericMatch.group(2)!);
      if (year != null && month != null && month >= 1 && month <= 12) {
        return _ParsedPeriod(month: month, year: year);
      }
    }

    final yearMatch = RegExp(r'(19|20)\d{2}').firstMatch(raw);
    final year = yearMatch != null ? int.tryParse(yearMatch.group(0)!) : null;
    if (year == null) {
      return null;
    }

    final lower = raw.toLowerCase();
    for (var i = 0; i < _monthNames.length; i++) {
      if (lower.contains(_monthNames[i])) {
        return _ParsedPeriod(month: i + 1, year: year);
      }
    }

    return null;
  }

  static String _monthName(int month) {
    if (month < 1 || month > 12) {
      return 'Bulan Invalid';
    }

    return _monthNames[month - 1][0].toUpperCase() +
        _monthNames[month - 1].substring(1);
  }

  static const List<String> _monthNames = [
    'januari',
    'februari',
    'maret',
    'april',
    'mei',
    'juni',
    'juli',
    'agustus',
    'september',
    'oktober',
    'november',
    'desember',
  ];
}

class _ParsedPeriod {
  final int month;
  final int year;

  const _ParsedPeriod({required this.month, required this.year});
}
