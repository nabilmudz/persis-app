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
    for (final item in riwayatTransaksi) {
      final status = (item.status ?? '').toLowerCase();
      if (status == 'pending' || status == 'tunggakan' || status == 'unpaid') {
        final amount = item.amount ?? item.jumlah ?? 0;
        totalTagihan += (amount is String
            ? int.tryParse(amount) ?? 0
            : (amount as num).toInt());
      }
    }
  }

  List<TransactionItemModel> get riwayatLunas {
    return riwayatTransaksi.where((tx) {
      final status = (tx.status ?? '').toLowerCase();
      return _statusLunas.any((s) => status.contains(s));
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

  List<TransactionItemModel> get riwayatTerakhir =>
      (List<TransactionItemModel>.from(riwayatLunas)
            ..sort((a, b) => _sortValue(b).compareTo(_sortValue(a))))
          .take(3)
          .toList();

  int _sortValue(TransactionItemModel tx) {
    final createdAt = DateTime.tryParse(tx.createdAt ?? '');
    if (createdAt != null) return createdAt.millisecondsSinceEpoch;

    final periodDate = _resolvePeriodDate(tx);
    if (periodDate != null) return periodDate.millisecondsSinceEpoch;

    return 0;
  }

  DateTime? _resolvePeriodDate(TransactionItemModel tx) {
    final source = '${tx.periodId ?? ''} ${tx.description ?? ''}';

    final numericMatch = RegExp(r'(\d{4})[-_/](\d{1,2})').firstMatch(source);
    if (numericMatch != null) {
      final year = int.tryParse(numericMatch.group(1)!);
      final month = int.tryParse(numericMatch.group(2)!);
      if (year != null && month != null && month >= 1 && month <= 12) {
        return DateTime(year, month);
      }
    }

    final yearMatch = RegExp(r'(19|20)\d{2}').firstMatch(source);
    final year = yearMatch == null ? null : int.tryParse(yearMatch.group(0)!);
    if (year == null) return null;

    const months = [
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
    final lowerSource = source.toLowerCase();
    for (var i = 0; i < months.length; i++) {
      if (lowerSource.contains(months[i])) {
        return DateTime(year, i + 1);
      }
    }

    return DateTime(year);
  }
}
