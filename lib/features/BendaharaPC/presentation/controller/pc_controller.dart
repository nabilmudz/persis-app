import 'package:flutter/foundation.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';

class PcController extends ChangeNotifier {
  PcController({TransactionRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? TransactionRemoteDataSource();

  static const List<String> verificationCategories = <String>[
    'Belum Diverifikasi',
    'Sudah Diverifikasi',
    'Tunggakan',
  ];

  final TransactionRemoteDataSource _dataSource;
  final List<TransactionModel> _allTransactions = <TransactionModel>[];

  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionModel> get allTransactions =>
      List<TransactionModel>.unmodifiable(_allTransactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transactions = await _dataSource.getHistory();
      
      _allTransactions
        ..clear()
        ..addAll(transactions);
    } catch (e) {
      _errorMessage = 'Error loading transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TransactionModel> get previewTransactions {
    final filtered = _allTransactions
        .where((item) => !isVerified(item))
        .toList();

    filtered.sort(_compareByCreatedAtDesc);
    return filtered.take(2).toList();
  }

  List<PcVerifikasiItem> filteredVerifikasiItems({
    required String category,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return _allTransactions.map(toVerifikasiItem).where((item) {
      final sameCategory = item.category == category;
      if (!sameCategory) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      return item.name.toLowerCase().contains(normalizedQuery) ||
          item.location.toLowerCase().contains(normalizedQuery) ||
          item.idNumber.toLowerCase().contains(normalizedQuery) ||
          item.paymentMethod.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  PcVerifikasiItem toVerifikasiItem(TransactionModel item) {
    return PcVerifikasiItem(
      transaction: item,
      date: formatDate(item.createdAt),
      location: 'Transaksi #${item.creatorId ?? '-'}',
      name: item.creatorId ?? 'Unknown',
      idNumber: '-',
      paymentMethod: paymentMethodText(item.paymentMethodId),
      price: formatCurrency(item.totalAmount ?? 0),
      category: categoryFromTransaction(item),
    );
  }

  Future<PcAccResult> accTransaction(TransactionModel item) async {
    final index = _allTransactions.indexWhere(
      (i) => _isSameTransaction(i, item),
    );

    if (index == -1) {
      return PcAccResult.notFound;
    }

    final current = _allTransactions[index];
    if (isVerified(current)) {
      return PcAccResult.alreadyVerified;
    }

    _allTransactions[index] = TransactionModel(
      creatorId: current.creatorId,
      paymentMethodId: current.paymentMethodId,
      totalAmount: current.totalAmount,
      status: current.status,
      accStatus: 'verified',
      isSynced: current.isSynced,
      createdAt: current.createdAt,
      items: current.items,
    );

    notifyListeners();
    return PcAccResult.success;
  }

  bool isVerified(TransactionModel item) {
    final acc = _normalize(item.accStatus);
    return acc == 'verified' || acc == 'diverifikasi';
  }

  String categoryFromTransaction(TransactionModel item) {
    if (isVerified(item)) {
      return 'Sudah Diverifikasi';
    }

    final status = _normalize(item.status);
    if (status == 'tunggakan') {
      return 'Tunggakan';
    }

    return 'Belum Diverifikasi';
  }

  String paymentMethodText(String? methodId) {
    if (methodId == null || methodId.trim().isEmpty) {
      return 'Unknown';
    }

    switch (_normalize(methodId)) {
      case 'bank_transfer':
      case 'transfer_bank':
      case 'transfer':
        return 'Transfer Bank';
      case 'cash':
      case 'tunai':
        return 'Tunai';
      case 'qris':
      case 'qris_code':
        return 'QRIS';
      default:
        return methodId;
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.trim().isEmpty) {
      return 'N/A';
    }

    final parsed = DateTime.tryParse(dateString);
    if (parsed == null) {
      return 'Invalid date';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    final day = parsed.day.toString().padLeft(2, '0');
    return '$day ${months[parsed.month - 1]} ${parsed.year}';
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

  bool _isSameTransaction(TransactionModel a, TransactionModel b) {
    return a.creatorId == b.creatorId &&
        a.createdAt == b.createdAt &&
        a.totalAmount == b.totalAmount;
  }

  int _compareByCreatedAtDesc(TransactionModel a, TransactionModel b) {
    final dateA = a.createdAt != null ? DateTime.tryParse(a.createdAt!) : null;
    final dateB = b.createdAt != null ? DateTime.tryParse(b.createdAt!) : null;

    if (dateA == null && dateB == null) return 0;
    if (dateA == null) return 1;
    if (dateB == null) return -1;
    return dateB.compareTo(dateA);
  }

  String _normalize(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }
}

class PcVerifikasiItem {
  final TransactionModel transaction;
  final String date;
  final String location;
  final String name;
  final String idNumber;
  final String paymentMethod;
  final String price;
  final String category;

  const PcVerifikasiItem({
    required this.transaction,
    required this.date,
    required this.location,
    required this.name,
    required this.idNumber,
    required this.paymentMethod,
    required this.price,
    required this.category,
  });
}

enum PcAccResult { success, alreadyVerified, notFound }
