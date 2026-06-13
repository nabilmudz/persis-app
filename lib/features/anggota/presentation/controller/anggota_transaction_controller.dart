import 'package:flutter/foundation.dart';
import 'package:persis_app/core/helpers/auth_helper.dart';
import 'package:persis_app/features/anggota/data/datasources/anggota_transaction_remote_datasource.dart';
import 'package:persis_app/features/bendahara_pj/data/models/transaction_model.dart';

class AnggotaTransactionController extends ChangeNotifier {
  final AnggotaTransactionRemoteDataSource _dataSource;

  AnggotaTransactionController({AnggotaTransactionRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? AnggotaTransactionRemoteDataSource();

  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionModel> _nonTunaiTransactions = [];
  int _selectedYear = DateTime.now().year;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TransactionModel> get nonTunaiTransactions => _nonTunaiTransactions;
  int get selectedYear => _selectedYear;

  Map<String, dynamic>? _paymentStatusData;
  bool _isLoadingStatus = false;
  String? _statusError;

  Map<String, dynamic>? get paymentStatusData => _paymentStatusData;
  bool get isLoadingStatus => _isLoadingStatus;
  String? get statusError => _statusError;

  Future<void> fetchNonTunaiTransactions({int? year}) async {
    final userId = await AuthHelper.getUserId();
    if (userId == null || userId.isEmpty) {
      _errorMessage = 'User ID tidak ditemukan.';
      _nonTunaiTransactions = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _nonTunaiTransactions = await _dataSource.getNonTunaiTransactions(
        userId,
        year: year ?? _selectedYear,
      );
    } catch (e) {
      _errorMessage = e.toString();
      _nonTunaiTransactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  Future<void> fetchPaymentStatus({int? year, int? month}) async {
    _isLoadingStatus = true;
    _statusError = null;
    notifyListeners();

    try {
      final regionId = await AuthHelper.getRegionId();
      _paymentStatusData = await _dataSource.getMembersPaymentStatus(
        year: year ?? DateTime.now().year,
        regionId: regionId,
        month: month,
      );
    } catch (e) {
      _statusError = e.toString();
      _paymentStatusData = null;
    } finally {
      _isLoadingStatus = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> get members {
    final data = _paymentStatusData;
    if (data == null) return [];
    final raw = data['members'] ?? data['data'];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    return [];
  }

  String paymentStatusFor(String memberId, int month) {
    final member = members.firstWhere(
      (m) => (m['_id'] ?? m['id'])?.toString() == memberId,
      orElse: () => <String, dynamic>{},
    );
    if (member.isEmpty) return 'unknown';

    final payments = member['payments'] as List? ?? [];
    for (final p in payments) {
      final m = p['month'] as int?;
      if (m == month) {
        return (p['status'] ?? '').toString().toLowerCase();
      }
    }
    return 'unpaid';
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'paid':
      case 'completed':
      case 'lunas':
        return 'Lunas';
      case 'partial':
        return 'Sebagian';
      case 'unpaid':
        return 'Belum';
      default:
        return '-';
    }
  }
}
