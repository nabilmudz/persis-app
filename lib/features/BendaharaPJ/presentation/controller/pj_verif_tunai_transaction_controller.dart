import 'package:flutter/foundation.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/core/network/network_status.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'package:persis_app/features/BendaharaPC/data/datasources/payment_method_remote_datasources.dart';
import 'package:persis_app/helpers/object_id_helper.dart';
import 'pj_invoice_controller.dart';
import 'pj_hive_controller.dart';

class PjVerifTunaiTransactionController extends ChangeNotifier {
  late final TransactionRemoteDataSource _dataSource;
  late final PaymentMethodRemoteDataSource _paymentMethodDataSource;

  List<TransactionModel> _transactions = [];
  String? _tunaiPaymentMethodId;

  bool _isLoading = false;
  String? _errorMessage;

  PjVerifTunaiTransactionController({
    TransactionRemoteDataSource? dataSource,
    PaymentMethodRemoteDataSource? paymentMethodDataSource,
  }) {
    _dataSource = dataSource ?? TransactionRemoteDataSource();
    _paymentMethodDataSource =
        paymentMethodDataSource ??
        PaymentMethodRemoteDataSource(ApiClient.baseUrl);
  }

  // Getters
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load transaksi berdasarkan user ID
  Future<void> loadTransactions(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _dataSource.getHistory();
      // Filter hanya transaksi untuk user ini
      _transactions = results
          .where(
            (tx) => tx.items?.any((item) => item.anggotaId == userId) == true,
          )
          .toList();
    } catch (e) {
      _transactions = [];
      _errorMessage = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get tunggakan (belum bayar)
  List<TransactionModel> get uncompleted {
    return _transactions.where((tx) {
      final status = (tx.status ?? '').trim().toLowerCase();
      return status == 'draft' || status == 'pending' || status == 'unpaid';
    }).toList();
  }

  // Get completed (sudah bayar)
  List<TransactionModel> get completed {
    return _transactions.where((tx) {
      final status = (tx.status ?? '').trim().toLowerCase();
      return status == 'completed' || status == 'paid';
    }).toList();
  }

  // Get tunggakan (outstanding)
  List<TransactionModel> get tunggakan {
    return _transactions.where((tx) {
      final status = (tx.status ?? '').trim().toLowerCase();
      return status == 'tunggakan' || status == 'overdue';
    }).toList();
  }

  // Get periode label dari transaction
  String getPeriodLabel(TransactionModel transaction) {
    final item = transaction.items?.isNotEmpty == true
        ? transaction.items!.first
        : null;
    if (item == null) return 'Periode tidak tersedia';

    // Try to parse dari period_id atau dues_period_id
    final periodId = item.periodId ?? item.duesPeriodId ?? '';
    final parts = periodId.split(RegExp(r'[-/_]'));

    if (parts.length >= 2) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);

      if (year != null && month != null) {
        return '${_getMonthName(month)} $year';
      }
    }

    return 'Periode tidak tersedia';
  }

  // Load payment method "tunai"
  Future<void> _loadTunaiPaymentMethod() async {
    if (_tunaiPaymentMethodId != null) {
      return; // Already loaded
    }

    try {
      final methods = await _paymentMethodDataSource.getAllPaymentMethods();
      for (final method in methods) {
        final code = method.code?.toLowerCase().trim() ?? '';
        final label = method.label?.toLowerCase().trim() ?? '';
        if (code == 'tunai' ||
            label == 'tunai' ||
            code == 'cash' ||
            label == 'cash') {
          _tunaiPaymentMethodId = method.id;
          return;
        }
      }
      // Fallback: cari payment method yang mengandung kata tunai/cash secara eksplisit
      for (final method in methods) {
        final code = method.code?.toLowerCase().trim() ?? '';
        final label = method.label?.toLowerCase().trim() ?? '';
        if (code.contains('tunai') ||
            label.contains('tunai') ||
            code.contains('cash') ||
            label.contains('cash')) {
          _tunaiPaymentMethodId = method.id;
          return;
        }
      }
      throw Exception('Payment method "tunai" tidak ditemukan');
    } catch (e) {
      _errorMessage = 'Gagal memuat payment method: $e';
      notifyListeners();
    }
  }

  // Confirm recording transaksi
  Future<bool> confirmRecording(List<int> selectedIndices) async {
    try {
      // Logic untuk konfirmasi pencatatan
      // Bisa di-implement sesuai dengan API yang ada
      return true;
    } catch (e) {
      _errorMessage = 'Gagal konfirmasi pencatatan: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Buat transaksi baru untuk bulan-bulan yang dipilih
  Future<PjTransactionCreationResult?> createTransactionForSelectedMonths({
    required String anggotaId,
    required String memberId,
    required Set<int> selectedMonths,
    required int year,
    required double Function(int month, int year) getNominal,
    required String? Function(int month, int year) getPeriodId,
  }) async {
    if (selectedMonths.isEmpty) {
      _errorMessage = 'Pilih minimal satu bulan';
      notifyListeners();
      return null;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final orderedMonths = selectedMonths.toList()..sort();

      // Buat item-item transaksi untuk setiap bulan yang dipilih
      final items = <TransactionItemModel>[];
      int totalAmount = 0;

      // Generate ObjectId valid untuk Transaction ini dari frontend
      final transactionId = ObjectIdHelper.generateMongoObjectId();

      for (final month in orderedMonths) {
        final amount = getNominal(month, year).round();
        totalAmount += amount;

        final duesObjectId = getPeriodId(month, year);
        if (duesObjectId == null || duesObjectId.isEmpty) {
          _errorMessage =
              'Period ID tidak ditemukan untuk ${_getMonthName(month)} $year. Silakan hubungi admin.';
          _isLoading = false;
          notifyListeners();
          return null;
        }

        items.add(
          TransactionItemModel(
            anggotaId: anggotaId,
            transactionId: transactionId,
            periodId: duesObjectId,
            duesPeriodId: duesObjectId,
            status: 'paid',
            amount: amount,
            description: 'Iuran ${_getMonthName(month)} $year',
          ),
        );
      }

      // Load payment method tunai jika ada
      try {
        await _loadTunaiPaymentMethod();
      } catch (_) {}

      // Buat transaksi dengan payment_method_id yang benar
      final transaction = TransactionModel(
        id: transactionId,
        type: 'tunai',
        creatorId: memberId,
        paymentMethodId: _tunaiPaymentMethodId ?? 'tunai', // Pastikan tidak null agar bisa di-resolve PjHiveController
        totalAmount: totalAmount,
        status: 'pending',
        accStatus: null,
        isSynced: false,
        createdAt: DateTime.now().toIso8601String(),
        items: items,
      );

      // Simpan ke Hive secara lokal terlebih dahulu
      final hiveController = PjHiveController();
      final key = await hiveController.saveTransactionLocally(
        transaction.toJson(),
      );

      final generatedAt = DateTime.tryParse(transaction.createdAt ?? '') ??
          DateTime.now();

      if (!await NetworkStatus.hasInternetConnection()) {
        _errorMessage = null;
        return PjTransactionCreationResult(
          transaction: transaction.copyWith(
            status: 'pending',
            isSynced: false,
          ),
          selectedMonths: orderedMonths,
          year: year,
          totalAmount: totalAmount,
          syncedToBackend: false,
          generatedAt: generatedAt,
        );
      }

      // Mencoba mengirim ke API
      try {
        final transactionSync = transaction.copyWith(status: 'completed');
        final isCreated = await _dataSource.createTransaction(transactionSync);
        final syncedTransaction = transaction.copyWith(
          status: 'completed',
          isSynced: isCreated,
        );

        if (isCreated) {
          // Jika berhasil masuk backend (MongoDB), hapus dari Hive
          await hiveController.removeSyncedTransaction(key);
          _errorMessage = null;
          return PjTransactionCreationResult(
            transaction: syncedTransaction,
            selectedMonths: orderedMonths,
            year: year,
            totalAmount: totalAmount,
            syncedToBackend: true,
            generatedAt: generatedAt,
          );
        } else {
          // Gagal dari backend tetapi masih tersimpan di Hive
          _errorMessage = null;
          return PjTransactionCreationResult(
            transaction: syncedTransaction,
            selectedMonths: orderedMonths,
            year: year,
            totalAmount: totalAmount,
            syncedToBackend: false,
            generatedAt: generatedAt,
          );
        }
      } catch (e) {
        // Gagal karena jaringan atau lainnya, tetap tersimpan di Hive
        _errorMessage = null;
        return PjTransactionCreationResult(
          transaction: transaction.copyWith(
            status: 'pending',
            isSynced: false,
          ),
          selectedMonths: orderedMonths,
          year: year,
          totalAmount: totalAmount,
          syncedToBackend: false,
          generatedAt: generatedAt,
        );
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper: Dapatkan nama bulan
  String _getMonthName(int month) {
    const monthNames = [
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
    return month >= 1 && month <= 12 ? monthNames[month - 1] : 'Bulan Invalid';
  }
}
