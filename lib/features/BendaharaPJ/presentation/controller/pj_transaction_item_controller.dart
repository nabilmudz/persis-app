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
///   - [PjMonthStatus.lunas]           → Hijau  (status API == 'paid')
///   - [PjMonthStatus.tunggakan]        → Merah  (status API == 'tunggakan')
///   - [PjMonthStatus.belumJatuhTempo]       → Putih/abu (status API == 'pending' = belum jatuh tempo)
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

  List<TransactionItemDetailModel> _items = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TransactionItemDetailModel> get items => List.unmodifiable(_items);

  List<TransactionItemDetailModel> get completed => _items.where((item) {
    final s = (item.status ?? '').trim().toLowerCase();
    return s == 'paid' || s == 'lunas';
  }).toList();

  List<TransactionItemDetailModel> get tunggakanItems => _items.where((item) {
    final s = (item.status ?? '').trim().toLowerCase();
    return s == 'tunggakan' || s == 'overdue';
  }).toList();

  List<TransactionItemDetailModel> get uncompleted => _items.where((item) {
    final s = (item.status ?? '').trim().toLowerCase();
    return s != 'paid' && s != 'lunas' && s != 'tunggakan' && s != 'overdue';
  }).toList();

  Future<void> loadByUser(
    String userId, {
    List<DuesPeriodModel>? globalDuesPeriods,
    bool forceRefresh = false,
  }) async {
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
            _buildStatusMap(cachedItems, globalDuesPeriods: globalDuesPeriods);
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

      _buildStatusMap(freshItems, globalDuesPeriods: globalDuesPeriods);
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

  void _buildStatusMap(
    List<TransactionItemDetailModel> items, {
    List<DuesPeriodModel>? globalDuesPeriods,
  }) {
    _items = List.of(items);
    _monthStatusMap.clear();
    _monthAmountMap.clear();

    for (final item in items) {
      final month = item.resolveMonth(globalDuesPeriods: globalDuesPeriods);
      final year = item.resolveYear(globalDuesPeriods: globalDuesPeriods);
      if (month == null || year == null) continue;

      final key = _key(month, year);
      final rawStatus = (item.status ?? '').trim().toLowerCase();

      // ✅ FIX: mapping status sesuai fakta API
      // API mengembalikan 3 kemungkinan:
      //   "paid"      → sudah dibayar        → lunas (hijau)
      //   "tunggakan" → lewat jatuh tempo    → tunggakan (merah)
      //   "pending"   → belum jatuh tempo    → belumJatuhTempo (putih/abu)
      final PjMonthStatus newStatus = switch (rawStatus) {
        'paid' || 'lunas' || 'completed' => PjMonthStatus.lunas,
        'tunggakan' || 'overdue' => PjMonthStatus.tunggakan,
        _ => PjMonthStatus.belumJatuhTempo,
        // ↑ "pending" dan status tidak dikenal → belumJatuhTempo, BUKAN tunggakan
      };

      // Jika entry sebelumnya sudah lunas, jangan overwrite
      final existing = _monthStatusMap[key];
      if (existing == PjMonthStatus.lunas) continue;

      _monthStatusMap[key] = newStatus;

      // Ambil nominal dari item, fallback ke info dues_period jika ada
      final nominal = (item.amount != null && item.amount! > 0)
          ? item.amount!
          : (item.duesPeriod?.amount?.round() ?? 0);

      if (nominal > 0) {
        _monthAmountMap[key] = nominal;
      }
    }
  }

  /// Status warna kartu bulan tertentu.
  PjMonthStatus getMonthStatus(int month, int year) {
    // ✅ FIX: jika bulan tidak ada di map sama sekali → belumJatuhTempo
    // (bukan tunggakan — bisa jadi period belum dibuat di backend)
    return _monthStatusMap[_key(month, year)] ?? PjMonthStatus.belumJatuhTempo;
  }

  /// Nominal iuran bulan tertentu (0 jika tidak ada data).
  int getMonthAmount(int month, int year) {
    return _monthAmountMap[_key(month, year)] ?? 0;
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
