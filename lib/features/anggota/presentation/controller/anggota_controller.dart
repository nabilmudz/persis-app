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

  // Status yang dianggap "lunas" / sudah dibayar
  static const _statusLunas = {'lunas', 'paid', 'selesai', 'success'};

  Future<void> fetchRiwayatTransaksi({required String userId, int? year}) async {
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
      if (status == 'pending' ||
          status == 'tunggakan' ||
          status == 'unpaid') {
        final amount = item.amount ?? item.jumlah ?? 0;
        totalTagihan += (amount is String
            ? int.tryParse(amount) ?? 0
            : (amount as num).toInt());
      }
    }
  }

  /// Hanya transaksi yang sudah lunas/dibayar
  List<TransactionItemModel> get riwayatLunas {
    return riwayatTransaksi.where((tx) {
      final status = (tx.status ?? '').toLowerCase();
      return _statusLunas.any((s) => status.contains(s));
    }).toList();
  }

  /// Filter riwayat lunas berdasarkan tahun (string seperti "2025")
  /// Gunakan "Semua" untuk mengembalikan semua data lunas.
  List<TransactionItemModel> filterLunasByTahun(String tahun) {
    final lunas = riwayatLunas;
    if (tahun == 'Semua') return lunas;

    final keyword = tahun.replaceAll(RegExp(r'[Tt]ahun\s*'), '').trim();
    return lunas.where((tx) {
      final deskripsi = (tx.description ?? '').toLowerCase();
      return deskripsi.contains(keyword);
    }).toList();
  }

  /// Total nominal dari daftar transaksi yang diberikan
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
      riwayatLunas.take(3).toList();
}