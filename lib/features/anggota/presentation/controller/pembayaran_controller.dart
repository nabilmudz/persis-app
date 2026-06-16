import 'dart:io';
import 'package:flutter/material.dart';
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/helpers/auth_helper.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/anggota/data/models/transaction_item_model.dart';
import 'package:persis_app/features/bendahara_pc/data/datasources/bank_account_remote_datasources.dart';
import 'package:persis_app/features/bendahara_pc/data/datasources/payment_method_remote_datasources.dart';
import 'package:persis_app/features/bendahara_pc/data/models/bank_account_model.dart';
import 'package:persis_app/features/bendahara_pj/presentation/controller/pj_transaction_item_controller.dart';

import '../../data/datasources/payment_remote_datasource.dart';

enum AnggotaMonthStatus { paid, tunggakan, pending, nonTunaiPending }

class PembayaranController extends ChangeNotifier {
  final PaymentRemoteDataSource remoteDataSource;
  final UserRemoteDataSource userRemoteDataSource;

  PembayaranController({
    required this.remoteDataSource,
    UserRemoteDataSource? userRemoteDataSource,
  }) : userRemoteDataSource =
           userRemoteDataSource ?? UserRemoteDataSource(AppConfig.baseUrl);

  bool isLoading = false;
  bool isUploading = false;
  bool isSuccess = false;
  bool isLoadingAccounts = false;
  String? errorMessage;

  int selectedYear = DateTime.now().year;
  final Set<int> selectedMonths = <int>{};
  final Map<int, AnggotaMonthStatus> _monthStatusMap = {};
  final Map<int, int> _monthAmountMap = {};
  final Map<int, String?> _periodIdMap = {};
  bool isLoadingItems = false;

  String? selectedPaymentMethod;
  bool showPaymentDetails = false;

  String periodeMulai = '';
  String periodeAkhir = '';
  int totalTagihan = 0;

  List<BankAccountModel> _transferAccounts = [];
  List<BankAccountModel> _qrisAccounts = [];

  List<BankAccountModel> get transferAccounts => _transferAccounts;
  List<BankAccountModel> get qrisAccounts => _qrisAccounts;

  String selectedBankId = '';
  String selectedQrisId = '';

  String? get qrisImageUrl => selectedQrisAccount?.qrisImageUrl;

  File? buktiFile;
  String? buktiUrl;

  String? _paymentMethodTransferId;
  String? _paymentMethodQrisId;

  final int hargaPerBulan = 20000;

  static const List<String> listBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  Future<void> loadSelfTransactionItems(String userId, {int? year}) async {
    isLoadingItems = true;
    notifyListeners();

    try {
      final items = await userRemoteDataSource.getRiwayatIuran(
        userId,
        year: year ?? selectedYear,
      );
      _buildStatusMap(items, year: year ?? selectedYear);
    } catch (e) {
      debugPrint('Error loadSelfTransactionItems: $e');
    } finally {
      isLoadingItems = false;
      notifyListeners();
    }
  }

  void _buildStatusMap(List<TransactionItemModel> items, {required int year}) {
    _monthStatusMap.clear();
    _monthAmountMap.clear();
    _periodIdMap.clear();

    for (final item in items) {
      final month = item.periodMonth;
      if (month == null || month < 1 || month > 12) continue;
      if (item.id == null) continue;

      final rawStatus = (item.status ?? '').trim().toLowerCase();
      final newStatus = switch (rawStatus) {
        'paid' || 'lunas' || 'completed' => AnggotaMonthStatus.paid,
        'tunggakan' ||
        'overdue' ||
        'rejected' ||
        'ditolak' => AnggotaMonthStatus.tunggakan,
        'pending' => AnggotaMonthStatus.nonTunaiPending,
        _ => AnggotaMonthStatus.tunggakan,
      };

      final existing = _monthStatusMap[month];
      if (existing == AnggotaMonthStatus.paid) continue;

      _monthStatusMap[month] = newStatus;

      final amount = item.amount ?? 20000;
      if (amount > 0) {
        _monthAmountMap[month] = amount;
      }

      if (item.periodId != null && item.periodId!.isNotEmpty) {
        _periodIdMap[month] = item.periodId;
        PjTransactionItemController.cachePeriodId(
          month: month,
          year: selectedYear,
          periodId: item.periodId,
        );
      }
    }
  }

  String? getPeriodId(int month) {
    if (_periodIdMap[month] != null && _periodIdMap[month]!.isNotEmpty) {
      return _periodIdMap[month];
    }
    final cached = PjTransactionItemController.getCachedPeriodId(
      month: month,
      year: selectedYear,
    );
    if (cached != null && cached.isNotEmpty) return cached;
    return _periodIdMap[month];
  }

  AnggotaMonthStatus getMonthStatus(int month) {
    final cached = _monthStatusMap[month];
    if (cached != null) return cached;

    final now = DateTime.now();
    final isPast =
        selectedYear < now.year ||
        (selectedYear == now.year && month < now.month);
    return isPast ? AnggotaMonthStatus.tunggakan : AnggotaMonthStatus.pending;
  }

  int getMonthAmount(int month) {
    return _monthAmountMap[month] ?? 20000;
  }

  int get totalTunggakan {
    int total = 0;
    for (int m = 1; m <= 12; m++) {
      if (getMonthStatus(m) == AnggotaMonthStatus.tunggakan) {
        total += getMonthAmount(m);
      }
    }
    return total;
  }

  void handleMonthTap(int month) {
    final status = getMonthStatus(month);
    if (status == AnggotaMonthStatus.paid) return;
    if (status == AnggotaMonthStatus.nonTunaiPending) return;

    if (selectedMonths.contains(month)) {
      bool hasLaterSelected = selectedMonths.any((m) => m > month);
      if (hasLaterSelected) return;

      selectedMonths.remove(month);
    } else {
      bool isDisabled = false;
      for (int i = 1; i < month; i++) {
        final s = getMonthStatus(i);
        if (s != AnggotaMonthStatus.paid && !selectedMonths.contains(i)) {
          isDisabled = true;
          break;
        }
      }
      if (isDisabled) return;

      selectedMonths.add(month);
    }

    _recalculateTotal();
    notifyListeners();
  }

  void setSelectedYear(int year) {
    selectedYear = year;
    selectedMonths.clear();
    _recalculateTotal();
    notifyListeners();
  }

  void _recalculateTotal() {
    if (selectedMonths.isEmpty) {
      totalTagihan = 0;
      periodeMulai = '';
      periodeAkhir = '';
      return;
    }

    final sorted = selectedMonths.toList()..sort();
    totalTagihan = 0;
    for (final m in sorted) {
      totalTagihan += getMonthAmount(m);
    }

    final first = sorted.first;
    final last = sorted.last;
    periodeMulai = '${monthNames[first - 1]} $selectedYear';
    periodeAkhir = '${monthNames[last - 1]} $selectedYear';
  }

  String get selectedMonthsLabel {
    if (selectedMonths.isEmpty) return '-';
    final sorted = selectedMonths.toList()..sort();
    return sorted.map((m) => monthNames[m - 1]).join(', ');
  }

  Future<void> fetchBankAccounts() async {
    isLoadingAccounts = true;
    notifyListeners();

    try {
      final regionId = await AuthHelper.getRegionId();
      final bankDs = BankAccountRemoteDataSource(AppConfig.baseUrl);
      final pmDs = PaymentMethodRemoteDataSource(AppConfig.baseUrl);

      final paymentMethods = await pmDs.getAllPaymentMethods();
      for (final pm in paymentMethods) {
        final code = (pm.code ?? '').toLowerCase().trim();
        if (code == 'qris') {
          _paymentMethodQrisId = pm.id;
        } else if (code == 'transfer_bank' || code == 'transfer bank') {
          _paymentMethodTransferId = pm.id;
        }
      }

      if (selectedPaymentMethod == 'transfer') {
        final all = await bankDs.getAll(
          regionId: regionId,
          paymentMethodId: _paymentMethodTransferId,
        );
        _transferAccounts = all.where((a) => a.isActive == true).toList();
        if (_transferAccounts.isNotEmpty && selectedBankId.isEmpty) {
          selectedBankId = _transferAccounts.first.id ?? '';
        }
      } else if (selectedPaymentMethod == 'qris') {
        final all = await bankDs.getAll(
          regionId: regionId,
          paymentMethodId: _paymentMethodQrisId,
        );
        _qrisAccounts = all.where((a) => a.isActive == true).toList();
        if (_qrisAccounts.isNotEmpty && selectedQrisId.isEmpty) {
          selectedQrisId = _qrisAccounts.first.id ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error fetchBankAccounts: $e');
    } finally {
      isLoadingAccounts = false;
      notifyListeners();
    }
  }

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
          ((tahunAkhir - tahunMulai) * 12) +
          (indexBulanAkhir - indexBulanMulai) +
          1;

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

  void selectPaymentMethod(String method) {
    selectedPaymentMethod = method;
    selectedBankId = '';
    selectedQrisId = '';
    _qrisAccounts = [];
    _transferAccounts = [];
    buktiFile = null;
    buktiUrl = null;
    showPaymentDetails = true;
    notifyListeners();
  }

  void resetPaymentMethod() {
    selectedPaymentMethod = null;
    showPaymentDetails = false;
    _transferAccounts = [];
    _qrisAccounts = [];
    selectedBankId = '';
    selectedQrisId = '';
    buktiFile = null;
    buktiUrl = null;
    notifyListeners();
  }

  BankAccountModel? get selectedBankAccount {
    if (selectedBankId.isEmpty) {
      return _transferAccounts.isNotEmpty ? _transferAccounts.first : null;
    }
    try {
      return _transferAccounts.firstWhere((a) => a.id == selectedBankId);
    } catch (_) {
      return _transferAccounts.isNotEmpty ? _transferAccounts.first : null;
    }
  }

  String get selectedBankName => selectedBankAccount?.bankName ?? '-';
  String get selectedAccountNumber => selectedBankAccount?.accountNumber ?? '-';
  String get selectedAccountHolder =>
      selectedBankAccount?.bankName ?? 'PC Pemuda Persis';

  void setBankById(String id) {
    selectedBankId = id;
    notifyListeners();
  }

  BankAccountModel? get selectedQrisAccount {
    if (selectedQrisId.isEmpty) {
      return _qrisAccounts.isNotEmpty ? _qrisAccounts.first : null;
    }
    try {
      return _qrisAccounts.firstWhere((a) => a.id == selectedQrisId);
    } catch (_) {
      return _qrisAccounts.isNotEmpty ? _qrisAccounts.first : null;
    }
  }

  String get selectedQrisName => selectedQrisAccount?.bankName ?? '-';

  void setQrisById(String id) {
    selectedQrisId = id;
    notifyListeners();
  }

  String? get selectedPaymentMethodId {
    if (selectedPaymentMethod == 'transfer') {
      return selectedBankAccount?.paymentMethodId ?? _paymentMethodTransferId;
    } else if (selectedPaymentMethod == 'qris') {
      return selectedQrisAccount?.paymentMethodId ?? _paymentMethodQrisId;
    }
    return null;
  }

  bool get canSubmit => buktiUrl != null && buktiUrl!.isNotEmpty;

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
      final token = await AuthHelper.getAccessToken();
      buktiUrl = await remoteDataSource.uploadBukti(buktiFile!, token: token);
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('Error uploadBukti: $e');
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> submitTransaction({required String anggotaId}) async {
    if (!canSubmit) {
      errorMessage = 'Upload bukti pembayaran terlebih dahulu.';
      notifyListeners();
      return;
    }

    isLoading = true;
    isSuccess = false;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await AuthHelper.getAccessToken();
      final sorted = selectedMonths.toList()..sort();

      final items = sorted.map((month) {
        return <String, dynamic>{
          'anggota_id': anggotaId,
          'period_id': getPeriodId(month) ?? '',
          'status': 'pending',
          'bukti_url': buktiUrl,
        };
      }).toList();

      final payload = <String, dynamic>{
        'creator_id': anggotaId,
        'payment_method_id': selectedPaymentMethodId ?? '',
        'total_amount': totalTagihan,
        'status': 'completed',
        'items': items,
      };

      await remoteDataSource.createTransaction(payload, token: token);
      isSuccess = true;
    } catch (e) {
      debugPrint('Error submitTransaction: $e');
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitTransfer({required String anggotaId}) async {
    await submitTransaction(anggotaId: anggotaId);
  }

  Future<void> submitQris({required String anggotaId}) async {
    await submitTransaction(anggotaId: anggotaId);
  }

  void reset() {
    isSuccess = false;
    errorMessage = null;
    buktiFile = null;
    buktiUrl = null;
    selectedPaymentMethod = null;
    showPaymentDetails = false;
    notifyListeners();
  }

  String formatCurrency(int amount) {
    final number = amount.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < number.length; i++) {
      final reverseIndex = number.length - i;
      buffer.write(number[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp. ${buffer.toString()}';
  }
}
