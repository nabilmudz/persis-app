import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/core/network/network_status.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import 'pj_verif_tunai_controller.dart';
import 'pj_hive_controller.dart';

export 'pj_verif_tunai_controller.dart'
    show MemberIuranStatusModel, PjMonthStatus;

class PjController extends ChangeNotifier {
  PjController({
    UserRemoteDataSource? userDataSource,
    TransactionRemoteDataSource? transactionDataSource,
  }) : _userDataSource =
           userDataSource ?? UserRemoteDataSource(ApiClient.baseUrl),
       _transactionDataSource =
           transactionDataSource ?? TransactionRemoteDataSource() {
    _verifController = PjVerifTunaiController(transactions: _transactions);
    _verifController.addListener(_onVerifChanged);
    _hiveController = PjHiveController();
    _hiveController.addListener(_onHiveChanged);
  }

  void _onHiveChanged() {
    notifyListeners();
  }

  /// Tambah transaksi ke state lokal (biasanya setelah berhasil di BE)
  /// agar UI langsung update tanpa menunggu fetch ulang.
  void addTransaction(TransactionModel tx) {
    // Hindari duplikat
    if (_transactions.any((t) => t.id == tx.id && tx.id != null)) {
      return;
    }
    _transactions.insert(0, tx);
    _verifController.updateData(transactions: _transactions);
    notifyListeners();
  }


  static const String _cacheBoxName = 'pj_data_cache';

  static Future<void> initCache() async {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      await Hive.openBox(_cacheBoxName);
    }
  }

  Box get _cacheBox => Hive.box(_cacheBoxName);

  final UserRemoteDataSource _userDataSource;
  final TransactionRemoteDataSource _transactionDataSource;

  final List<UserModel> _members = [];
  final List<TransactionModel> _transactions = [];
  late final PjHiveController _hiveController;

  bool _isLoading = false;
  String? _errorMessage;

  late final PjVerifTunaiController _verifController;

  List<UserModel> get members => List<UserModel>.unmodifiable(_members);
  List<TransactionModel> get transactions =>
      List<TransactionModel>.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadInitialData() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Load dari Cache dulu agar UI responsif (Offline-first)
      await _loadFromCache();

      // 2. Coba fetch data terbaru dari Network
      final isOnline = await NetworkStatus.hasInternetConnection();
      if (isOnline) {
        await _fetchAndCacheData();
      } else {
        if (_members.isEmpty && _transactions.isEmpty) {
          _errorMessage = 'Mode offline: Tidak ada data cache tersedia.';
        }
      }
    } catch (e) {
      debugPrint('[PjController] Error loadInitialData: $e');
      if (_members.isEmpty) {
        _errorMessage = 'Gagal memuat data: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedUsers = _cacheBox.get('members') as List?;
      final cachedTransactions = _cacheBox.get('transactions') as List?;

      if (cachedUsers != null) {
        _members
          ..clear()
          ..addAll(
            cachedUsers
                .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
                .toList(),
          );
      }

      if (cachedTransactions != null) {
        _transactions
          ..clear()
          ..addAll(
            cachedTransactions
                .map(
                  (e) =>
                      TransactionModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(),
          );
      }

      _verifController.updateData(transactions: _transactions);
    } catch (e) {
      debugPrint('[PjController] Gagal load dari cache: $e');
    }
  }

  Future<void> _fetchAndCacheData() async {
    try {
      final users = await _userDataSource.getAllUsers();
      final transactions = await _transactionDataSource.getHistory();

      final filteredUsers = users
          .where((u) => u.id != null && u.id!.trim().isNotEmpty)
          .toList();

      // Update State
      _members
        ..clear()
        ..addAll(filteredUsers);
      _transactions
        ..clear()
        ..addAll(transactions);
      _verifController.updateData(transactions: _transactions);

      // Save ke Cache
      await _cacheBox.put(
        'members',
        filteredUsers.map((e) => e.toJson()).toList(),
      );
      await _cacheBox.put(
        'transactions',
        transactions.map((e) => e.toJson()).toList(),
      );

      debugPrint('[PjController] Data berhasil di-cache untuk offline.');
    } catch (e) {
      debugPrint('[PjController] Gagal fetch data network: $e');
      // Tetap gunakan data cache jika network gagal
    }
  }

  void _onVerifChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _verifController.removeListener(_onVerifChanged);
    _verifController.dispose();
    _hiveController.removeListener(_onHiveChanged);
    super.dispose();
  }

  String memberDisplayName(UserModel member) {
    final name = member.fullname?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final code = member.npa?.trim();
    if (code != null && code.isNotEmpty) {
      return code;
    }

    final email = member.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Unknown Member';
  }

  String memberDisplayCode(UserModel member) {
    return (member.code ?? '').trim();
  }

  List<UserModel> filterMembers(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return members;
    }

    return _members.where((member) {
      final name = (member.name ?? '').toLowerCase();
      final code = (member.code ?? '').toLowerCase();
      final email = (member.email ?? '').toLowerCase();
      return name.contains(trimmed) ||
          code.contains(trimmed) ||
          email.contains(trimmed);
    }).toList();
  }

  int tunggakanCountByMember(String anggotaId) {
    return _verifController.tunggakanCountByMember(anggotaId);
  }

  double tunggakanNominalByMember(String anggotaId) {
    return _verifController.tunggakanNominalByMember(anggotaId);
  }

  List<MemberIuranStatusModel> memberIuranStatusItems(
    String anggotaId, {
    int limit = 4,
  }) {
    return _verifController.memberPeriodStatusItems(anggotaId, limit: limit);
  }

  List<String> memberIuranStatusLabels(String anggotaId, {int limit = 4}) {
    return _verifController.memberPeriodStatusLabels(anggotaId, limit: limit);
  }

  PjMonthStatus memberCardStatus(String anggotaId) {
    return _verifController.memberCardStatus(anggotaId);
  }

  double getNominalForMemberMonth({
    required String anggotaId,
    required int month,
    required int year,
  }) {
    return _verifController.getNominalForMemberMonth(
      anggotaId: anggotaId,
      month: month,
      year: year,
    );
  }

  PjMonthStatus getMonthStatus({
    required String anggotaId,
    required int month,
    int? year,
  }) {
    return _verifController.getMonthStatus(
      anggotaId: anggotaId,
      month: month,
      year: year,
    );
  }

  /// Ambil transaksi terakhir milik anggota (dari history yang sudah di-load)
  TransactionModel? lastTransactionForMember(String anggotaId) {
    if (anggotaId.isEmpty) return null;
    
    // Cari transaksi yang melibatkan anggota ini
    final memberTxs = _transactions.where((tx) {
      // 1. Cek apakah ada item yang ditujukan untuk anggota ini
      final hasItemForMember = tx.items?.any((item) => 
        (item.anggotaId?.toString() ?? '') == anggotaId
      ) ?? false;
      if (hasItemForMember) return true;

      // 2. Cek apakah anggota ini adalah pembuat transaksi (fallback)
      if ((tx.creatorId?.toString() ?? '') == anggotaId) return true;
      
      return false;
    }).toList();

    if (memberTxs.isEmpty) return null;

    // Sort by date descending (latest first)
    memberTxs.sort((a, b) {
      final aDate = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1900);
      final bDate = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1900);
      return bDate.compareTo(aDate);
    });

    return memberTxs.first;
  }
}
