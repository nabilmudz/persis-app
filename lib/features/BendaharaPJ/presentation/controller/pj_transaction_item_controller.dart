import 'package:flutter/foundation.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_item_detail_model.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'pj_verif_tunai_controller.dart';

/// Controller yang mengelola status bulan iuran per anggota
/// berdasarkan data dari endpoint /api/transaction-item/user/{userId}.
///
/// Status warna:
///   - [PjMonthStatus.lunas]           → Hijau  (status == 'paid')
///   - [PjMonthStatus.tunggakan]        → Merah  (status == 'tunggakan' / period sudah lewat & belum dibayar)
///   - [PjMonthStatus.belumJatuhTempo]  → Default putih/abu
class PjTransactionItemController extends ChangeNotifier {
  PjTransactionItemController({TransactionRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? TransactionRemoteDataSource();

  final TransactionRemoteDataSource _dataSource;

  bool _isLoading = false;
  String? _errorMessage;

  /// Map dari key "$year-$month" → [PjMonthStatus]
  final Map<String, PjMonthStatus> _monthStatusMap = {};

  /// Map dari key "$year-$month" → nominal iuran (untuk keperluan konfirmasi)
  final Map<String, int> _monthAmountMap = {};

  List<TransactionItemDetailModel> _items = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TransactionItemDetailModel> get items => _items;

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

  /// Memuat semua transaction-item untuk userId tertentu dan
  /// membangun map status per bulan-tahun.
  Future<void> loadByUser(String userId, {List<DuesPeriodModel>? globalDuesPeriods}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _dataSource.getTransactionItemsByUser(userId);
      _buildStatusMap(items, globalDuesPeriods: globalDuesPeriods);
    } catch (e) {
      _errorMessage = 'Gagal memuat data iuran: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _buildStatusMap(List<TransactionItemDetailModel> items, {List<DuesPeriodModel>? globalDuesPeriods}) {
    _items = items;
    _monthStatusMap.clear();
    _monthAmountMap.clear();



    for (final item in items) {
      final month = item.resolveMonth(globalDuesPeriods: globalDuesPeriods);
      final year = item.resolveYear(globalDuesPeriods: globalDuesPeriods);
      if (month == null || year == null) continue;

      final key = _key(month, year);
      final rawStatus = (item.status ?? '').trim().toLowerCase();

      final PjMonthStatus newStatus;
      if (rawStatus == 'paid' || rawStatus == 'lunas' || rawStatus == 'completed') {
        newStatus = PjMonthStatus.lunas;
      } else if (rawStatus == 'tunggakan' || rawStatus == 'overdue') {
        newStatus = PjMonthStatus.tunggakan;
      } else {
        // Jika belum ada status eksplisit, anggap tunggakan (merah)
        newStatus = PjMonthStatus.tunggakan;
      }

      // Jika bulan ini sudah lunas di entry sebelumnya, jangan overwrite
      final existing = _monthStatusMap[key];
      if (existing == PjMonthStatus.lunas) continue;

      _monthStatusMap[key] = newStatus;

      if (item.amount != null && item.amount! > 0) {
        _monthAmountMap[key] = item.amount!;
      }
    }
  }

  /// Kembalikan status warna kartu bulan tertentu.
  PjMonthStatus getMonthStatus(int month, int year) {
    if (_monthStatusMap.containsKey(_key(month, year))) {
      return _monthStatusMap[_key(month, year)]!;
    }
    // Jika tidak ada data transaksi item untuk bulan ini, anggap tunggakan (merah)
    return PjMonthStatus.tunggakan;
  }

  /// Kembalikan nominal iuran bulan tertentu (0 jika tidak ada data).
  int getMonthAmount(int month, int year) {
    return _monthAmountMap[_key(month, year)] ?? 0;
  }

  /// Hitung total tunggakan (rupiah).
  int get totalTunggakan {
    int total = 0;
    for (final entry in _monthStatusMap.entries) {
      if (entry.value == PjMonthStatus.tunggakan) {
        total += _monthAmountMap[entry.key] ?? 0;
      }
    }
    return total;
  }

  static String _key(int month, int year) =>
      '$year-${month.toString().padLeft(2, '0')}';
}
