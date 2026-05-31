import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/payment_model.dart';
import '../../data/datasources/payment_remote_datasource.dart';

class PembayaranController extends ChangeNotifier {
  final PaymentRemoteDataSource remoteDataSource;

  PembayaranController({required this.remoteDataSource});

  bool isLoading = false;
  bool isUploading = false;
  bool isSuccess = false;
  String? errorMessage;

  String periodeMulai = '';
  String periodeAkhir = '';
  int totalTagihan = 0;

  String selectedBank = 'BCA';
  String? qrisImageUrl;

  File? buktiFile;
  String? buktiUrl;

  final int hargaPerBulan = 20000;

  final List<String> listBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  final Map<String, String> rekeningBank = {
    'BCA': '0987 6543 21',
    'BSI': '7112 2334 45',
    'Mandiri': '1300 0011 2233',
  };

  void initPeriode(String mulai, String akhir, int total) {
    periodeMulai = mulai;
    periodeAkhir = akhir;
    totalTagihan = total;
    notifyListeners();
  }

  void setPeriodeMulai(String value) {
    periodeMulai = value;
    hitungTotal();
  }

  void setPeriodeAkhir(String value) {
    periodeAkhir = value;
    hitungTotal();
  }

  void hitungTotal() {
    try {
      if (periodeMulai.isEmpty || periodeAkhir.isEmpty) {
        totalTagihan = 0;
        notifyListeners();
        return;
      }

      final mulai = periodeMulai.split(' ');
      final akhir = periodeAkhir.split(' ');

      if (mulai.length < 2 || akhir.length < 2) {
        totalTagihan = 0;
        notifyListeners();
        return;
      }

      final tahunMulai = int.tryParse(mulai[1]) ?? 0;
      final tahunAkhir = int.tryParse(akhir[1]) ?? 0;
      final indexBulanMulai = listBulan.indexOf(mulai[0]);
      final indexBulanAkhir = listBulan.indexOf(akhir[0]);

      if (indexBulanMulai == -1 || indexBulanAkhir == -1) {
        errorMessage = 'Format bulan tidak valid.';
        totalTagihan = 0;
        notifyListeners();
        return;
      }

      final selisih =
          ((tahunAkhir - tahunMulai) * 12) + (indexBulanAkhir - indexBulanMulai) + 1;

      if (selisih <= 0) {
        errorMessage = 'Periode akhir harus sama atau setelah periode mulai.';
        totalTagihan = 0;
      } else {
        errorMessage = null;
        totalTagihan = selisih * hargaPerBulan;
      }
    } catch (_) {
      totalTagihan = hargaPerBulan;
    }
    notifyListeners();
  }

  String get labelPeriode {
    if (periodeMulai.isEmpty) return '-';
    if (periodeMulai == periodeAkhir) return periodeMulai;
    final mulai = periodeMulai.split(' ');
    final akhir = periodeAkhir.split(' ');
    if (mulai.length < 2 || akhir.length < 2) return periodeMulai;
    return '${mulai[0]} ${mulai[1]} - ${akhir[0]} ${akhir[1]}';
  }

  void setBank(String bank) {
    selectedBank = bank;
    notifyListeners();
  }

  String get nomorRekening => rekeningBank[selectedBank] ?? '-';

  Future<void> fetchQrisDetail() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await remoteDataSource.getQrisDetail();
      qrisImageUrl = data['qris_image_url'];
    } catch (e) {
      debugPrint('Error fetchQrisDetail: $e');
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setBuktiFile(File file) {
    buktiFile = file;
    buktiUrl = null;
    notifyListeners();
  }

  Future<void> uploadBukti() async {
    if (buktiFile == null) return;

    isUploading = true;
    errorMessage = null;
    notifyListeners();

    try {
      buktiUrl = await remoteDataSource.uploadBukti(buktiFile!);
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('Error uploadBukti: $e');
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> submitTransfer({required String anggotaId}) async {
    await _submit(anggotaId: anggotaId, method: 'transfer');
  }

  Future<void> submitQris({required String anggotaId}) async {
    await _submit(anggotaId: anggotaId, method: 'qris');
  }

  Future<void> _submit({
    required String anggotaId,
    required String method,
  }) async {
    isLoading = true;
    isSuccess = false;
    errorMessage = null;
    notifyListeners();

    try {
      final payment = PaymentModel(
        anggotaId: anggotaId,
        periodMulai: periodeMulai,
        periodAkhir: periodeAkhir,
        totalAmount: totalTagihan,
        paymentMethod: method,
        bank: method == 'transfer' ? selectedBank : null,
        buktiUrl: buktiUrl,
      );

      await remoteDataSource.submitPayment(payment);
      isSuccess = true;
    } catch (e) {
      debugPrint('Error submitPayment: $e');
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    isSuccess = false;
    errorMessage = null;
    buktiFile = null;
    buktiUrl = null;
    notifyListeners();
  }
}
