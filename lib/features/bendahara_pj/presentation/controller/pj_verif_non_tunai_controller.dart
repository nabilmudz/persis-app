import 'package:flutter/foundation.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/features/bendahara_pj/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/bendahara_pj/data/models/transaction_model.dart';
import 'package:persis_app/features/bendahara_pc/data/datasources/payment_method_remote_datasources.dart';
import 'package:persis_app/features/bendahara_pc/presentation/controller/pc_controller.dart';

class PjVerifNonTunaiController extends ChangeNotifier {
  late final TransactionRemoteDataSource _transactionDataSource;
  late final PaymentMethodRemoteDataSource _paymentMethodDataSource;

  List<TransactionModel> _transactions = [];
  String? _tunaiMethodId;

  bool _isLoading = false;
  String? _errorMessage;

  PjVerifNonTunaiController({
    TransactionRemoteDataSource? transactionDataSource,
    PaymentMethodRemoteDataSource? paymentMethodDataSource,
  }) {
    _transactionDataSource =
        transactionDataSource ?? TransactionRemoteDataSource();
    _paymentMethodDataSource =
        paymentMethodDataSource ??
        PaymentMethodRemoteDataSource(ApiClient.baseUrl);
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TransactionModel> get transactions => _transactions;

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final methods = await _paymentMethodDataSource.getAllPaymentMethods();
      _tunaiMethodId = null;

      for (final method in methods) {
        final code = method.code?.toLowerCase() ?? '';
        final id = method.id;

        if (kDebugMode) {
          print("Checking Payment Method: ID=$id, Code=$code");
        }

        if (code == 'tunai') {
          _tunaiMethodId = id;
          if (kDebugMode) {
            print("Found Tunai Method ID: $_tunaiMethodId");
          }
        }
      }

      final allTransactions = await _transactionDataSource.getHistory();
      _transactions = allTransactions.where((tx) {
        final methodId = tx.paymentMethodId;
        return methodId != _tunaiMethodId;
      }).toList();

      if (kDebugMode) {
        print("Tunai Method ID (excluded): $_tunaiMethodId");
        print(
          "Found ${_transactions.length} non_tunai transactions from ${allTransactions.length} total",
        );
        for (var i = 0; i < _transactions.length && i < 3; i++) {
          print(
            "Transaction $i: status=${_transactions[i].status}, method_id=${_transactions[i].paymentMethodId}",
          );
        }
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<PcVerifikasiItem> getFilteredItems({
    required String category,
    required String query,
  }) {
    final filtered = _transactions.where((tx) {
      final status = (tx.status ?? '').toLowerCase().trim();
      final isVerified =
          status == 'completed' || status == 'paid' || status == 'verified';

      if (category == 'Belum Diverifikasi') {
        if (isVerified) return false;
      } else if (category == 'Sudah Diverifikasi') {
        if (!isVerified) return false;
      }

      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        final label = _getTransactionLabel(tx).toLowerCase();
        final creator = (tx.creatorId ?? '').toLowerCase();

        if (!label.contains(lowerQuery) && !creator.contains(lowerQuery)) {
          return false;
        }
      }

      return true;
    }).toList();

    return filtered.map((tx) => _mapToPcItem(tx)).toList();
  }

  PcVerifikasiItem _mapToPcItem(TransactionModel tx) {
    String dateStr = '-';
    if (tx.createdAt != null) {
      try {
        final date = DateTime.parse(tx.createdAt!);
        dateStr = "${date.day}/${date.month}/${date.year}";
      } catch (_) {}
    }

    final price = (tx.totalAmount ?? 0).toString();

    final status = (tx.status ?? '').toLowerCase();
    final category = (status == 'completed' || status == 'paid')
        ? 'Sudah Diverifikasi'
        : 'Belum Diverifikasi';

    return PcVerifikasiItem(
      transaction: tx,
      date: dateStr,
      location: 'Pusat/Cabang',
      name: _getTransactionLabel(tx),
      idNumber: tx.creatorId ?? '-',
      paymentMethod: 'Non-Tunai',
      price: price,
      category: category,
    );
  }

  String _getTransactionLabel(TransactionModel tx) {
    if (tx.items != null && tx.items!.isNotEmpty) {
      return tx.items!.first.description ?? 'Iuran Anggota';
    }
    return 'Transaksi Iuran';
  }

  Future<PcAccResult> accTransaction(TransactionModel transaction) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (transaction.id == null || transaction.id!.isEmpty) {
        return PcAccResult.notFound;
      }

      final updatedItems = transaction.items?.map((item) {
        return TransactionItemModel(
          anggotaId: item.anggotaId,
          periodId: item.periodId,
          status: 'paid',
          duesPeriodId: item.duesPeriodId,
          amount: item.amount,
          description: item.description,
        );
      }).toList();

      final updatedTx = TransactionModel(
        id: transaction.id,
        creatorId: transaction.creatorId,
        paymentMethodId: transaction.paymentMethodId,
        totalAmount: transaction.totalAmount,
        status: 'completed',
        accStatus: 'acc_pj',
        isSynced: transaction.isSynced,

        createdAt: transaction.createdAt,
        items: updatedItems,
      );

      final success = await _transactionDataSource.updateTransaction(
        transaction.id!,
        updatedTx,
      );

      if (success) {
        await loadInitialData();
        return PcAccResult.success;
      }
      return PcAccResult.notFound;
    } catch (e) {
      if (kDebugMode) {
        print("Error ACC Transaction: $e");
      }
      return PcAccResult.notFound;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isVerified(TransactionModel transaction) {
    final status = (transaction.status ?? '').toLowerCase();
    return status == 'completed' || status == 'paid';
  }
}
