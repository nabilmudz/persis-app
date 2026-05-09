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

  Future<void> fetchRiwayatTransaksi({required String userId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await repository.getRiwayatIuran(userId);
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
      if (item.status == 'pending' ||
          item.status == 'tunggakan' ||
          item.status == 'unpaid') {
        totalTagihan += (item.amount ?? 0);
      }
    }
  }

  List<TransactionItemModel> get riwayatTerakhir =>
      riwayatTransaksi.take(3).toList();

  List<TransactionItemModel> filterByTahun(String tahun) {
    if (tahun == 'Semua') return riwayatTransaksi;
    
    return riwayatTransaksi.where((tx) {
      final deskripsi = (tx.description ?? '').toLowerCase();
      return deskripsi.contains(tahun.toLowerCase().replaceAll('tahun ', ''));
    }).toList();
  }
}
