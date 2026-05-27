import 'package:flutter/material.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/repositories/anggota_repository.dart';

class AnggotaController extends ChangeNotifier {
  final AnggotaRepository repository;

  AnggotaController({required this.repository});

  bool isLoading = false;
  String? errorMessage;

  List<TransactionItemModel> riwayatTransaksi = [];
  int totalTagihan = 0;

  static const _statusLunas = {
    'lunas',
    'paid',
    'selesai',
    'success',
    'completed',
  };

  Future<void> fetchRiwayatTransaksi({
    required String userId,
    int? year,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await repository.getRiwayatIuran(userId, year: year);
      riwayatTransaksi = data;
      _hitungTotalTagihan();
    } catch (e) {
      debugPrint('Error fetchRiwayatTransaksi: $e');
      errorMessage = e.toString();
      riwayatTransaksi = [];
      totalTagihan = 0;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _hitungTotalTagihan() {
    totalTagihan = 0;

    final now = DateTime.now();

    for (final item in riwayatTransaksi) {
      final isUnpaid = item.id == null || item.id!.isEmpty;

      if (!isUnpaid) continue;

      final periodDate = _resolvePeriodDate(item);
      if (periodDate == null) continue;
      final isPastMonth =
          periodDate.year < now.year ||
          (periodDate.year == now.year && periodDate.month < now.month);

      if (!isPastMonth) continue;

      dynamic rawAmount = item.amount ?? item.jumlah;

      if (rawAmount == null || rawAmount == 0 || rawAmount == '0') {
        rawAmount = 20000;
      }

      final nominal = rawAmount is String
          ? int.tryParse(rawAmount) ?? 0
          : (rawAmount as num).toInt();

      totalTagihan += nominal;
    }
  }

  List<TransactionItemModel> get riwayatLunas {
    return riwayatTransaksi.where((tx) {
      final status = (tx.status ?? '').toLowerCase().trim();

      return _statusLunas.contains(status);
    }).toList();
  }

  List<TransactionItemModel> filterLunasByTahun(String tahun) {
    final lunas = riwayatLunas;
    if (tahun == 'Semua') return lunas;

    final keyword = tahun.replaceAll(RegExp(r'[Tt]ahun\s*'), '').trim();
    return lunas.where((tx) {
      final deskripsi = (tx.description ?? '').toLowerCase();
      return deskripsi.contains(keyword);
    }).toList();
  }

  double hitungTotalNominal(List<TransactionItemModel> transactions) {
    return transactions.fold(0.0, (sum, tx) {
      final amount = tx.amount ?? tx.jumlah ?? 0;
      return sum +
          (amount is String
              ? double.tryParse(amount) ?? 0
              : (amount as num).toDouble());
    });
  }

  List<TransactionItemModel> get riwayatTerakhir {
    final items = List<TransactionItemModel>.from(riwayatLunas);

    items.sort((a, b) {
      final aDate = _resolvePeriodDate(a);
      final bDate = _resolvePeriodDate(b);

      if (aDate == null || bDate == null) return 0;

      return bDate.compareTo(aDate);
    });

    return items.take(3).toList();
  }

  DateTime? _resolvePeriodDate(TransactionItemModel tx) {
    if (tx.periodYear != null &&
        tx.periodMonth != null &&
        tx.periodMonth! >= 1 &&
        tx.periodMonth! <= 12) {
      return DateTime(tx.periodYear!, tx.periodMonth!);
    }

    final source = '${tx.periodId ?? ''} ${tx.description ?? ''}';

    final numericMatch = RegExp(r'(\d{4})[-_/](\d{1,2})').firstMatch(source);

    if (numericMatch != null) {
      final year = int.tryParse(numericMatch.group(1)!);
      final month = int.tryParse(numericMatch.group(2)!);

      if (year != null && month != null && month >= 1 && month <= 12) {
        return DateTime(year, month);
      }
    }

    return null;
  }
}
