import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:persis_app/core/storage/hive_service.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_item_detail_model.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'pj_verif_tunai_controller.dart';

/// Controller yang mengelola status bulan iuran per anggota
/// berdasarkan data dari endpoint /api/transaction-item/user/{userId}.
///
/// Status warna:
///   - [PjMonthStatus.paid]           → Hijau  (status API == 'paid')
///   - [PjMonthStatus.tunggakan]        → Merah  (status API == 'tunggakan')
///   - [PjMonthStatus.pending]       → Putih/abu (status API == 'pending' = belum jatuh tempo)
class PjTransactionItemController extends ChangeNotifier {
  PjTransactionItemController({TransactionRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? TransactionRemoteDataSource();

  final TransactionRemoteDataSource _dataSource;

  static const String _cacheBoxName = 'pj_item_cache';

  static Future<void> initCache() async {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      await Hive.openBox(_cacheBoxName);
    }
  }

  Box get _cacheBox => HiveService.box(_cacheBoxName);

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

  Future<void> loadByUser(String userId, {bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
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
            _buildStatusMap(cachedItems);
            notifyListeners();
          }
        }
      } else {
        await _cacheBox.delete(userId);
      }

      final freshItems = await _dataSource.getTransactionItemsByUser(userId);

      try {
        await _cacheBox.put(userId, freshItems.map((e) => e.toJson()).toList());
      } catch (cacheError) {
        debugPrint(
          '[PjTransactionItemController] Gagal simpan cache: $cacheError',
        );
      }

      _buildStatusMap(freshItems);
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
        'paid' || 'paid' || 'completed' => PjMonthStatus.paid,
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
    return _monthStatusMap[_key(month, year)] ?? PjMonthStatus.pending;
  }

  /// Nominal iuran bulan tertentu (0 jika tidak ada data).
  int getMonthAmount(int month, int year) {
    return _monthAmountMap[_key(month, year)] ?? 0;
  }

  /// Mendapatkan periodId (Mongo ID) untuk bulan/tahun tertentu.
  String? getMonthPeriodId(int month, int year) {
    return _monthPeriodIdMap[_key(month, year)];
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
}
