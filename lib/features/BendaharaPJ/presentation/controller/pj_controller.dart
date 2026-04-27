import 'package:flutter/foundation.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import 'pj_verif_controller.dart';

export 'pj_verif_controller.dart'
    show PjMonthStatus, PjPaymentCartItem, PjSubmitResult;

class PjController extends ChangeNotifier {
  PjController({
    UserRemoteDataSource? userDataSource,
    TransactionRemoteDataSource? transactionDataSource,
  }) : _userDataSource =
           userDataSource ?? UserRemoteDataSource(ApiClient.baseUrl),
       _transactionDataSource =
           transactionDataSource ??
           TransactionRemoteDataSource(ApiClient.baseUrl) {
    _verifController = PjVerifController(
      transactions: _transactions,
      members: _members,
      transactionDataSource: _transactionDataSource,
    );
    _verifController.addListener(_onVerifChanged);
  }

  final UserRemoteDataSource _userDataSource;
  final TransactionRemoteDataSource _transactionDataSource;

  final List<UserModel> _members = [];
  final List<TransactionModel> _transactions = [];

  bool _isLoading = false;
  String? _errorMessage;

  late final PjVerifController _verifController;

  List<UserModel> get members => List<UserModel>.unmodifiable(_members);
  List<TransactionModel> get transactions =>
      List<TransactionModel>.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<PjPaymentCartItem> get cartItems => _verifController.cartItems;
  int get cartItemCount => _verifController.cartItemCount;
  double get cartTotalNominal => _verifController.cartTotalNominal;

  Future<void> loadInitialData() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _userDataSource.getAllUsers(),
        _transactionDataSource.getHistory(),
      ]);

      final users = (results[0] as List<UserModel>)
          .where((user) => user.id != null && user.id!.trim().isNotEmpty)
          .toList();
      final transactions = results[1] as List<TransactionModel>;

      _members
        ..clear()
        ..addAll(users);

      _transactions
        ..clear()
        ..addAll(transactions);
    } catch (e) {
      _errorMessage = 'Gagal memuat data anggota/transaksi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onVerifChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _verifController.removeListener(_onVerifChanged);
    _verifController.dispose();
    super.dispose();
  }

  String memberDisplayName(UserModel member) {
    final name = member.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final code = member.code?.trim();
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

  bool isInCart({
    required String anggotaId,
    required int month,
    required int year,
  }) {
    return _verifController.isInCart(
      anggotaId: anggotaId,
      month: month,
      year: year,
    );
  }

  void addMonthToCart({
    required UserModel member,
    required int month,
    required int year,
    double? nominal,
  }) {
    _verifController.addMonthToCart(
      member: member,
      month: month,
      year: year,
      nominal: nominal,
    );
  }

  void removeFromCart(String cartItemId) {
    _verifController.removeFromCart(cartItemId);
  }

  void removeMemberFromCart(String anggotaId) {
    _verifController.removeMemberFromCart(anggotaId);
  }

  void clearCart() {
    _verifController.clearCart();
  }

  Future<PjSubmitResult?> submitCart({
    String paymentMethodId = 'bank_transfer',
    String? creatorId,
  }) async {
    return _verifController.submitCart(
      paymentMethodId: paymentMethodId,
      creatorId: creatorId,
    );
  }

  int tunggakanCountByMember(String anggotaId) {
    return _verifController.tunggakanCountByMember(anggotaId);
  }

  double tunggakanNominalByMember(String anggotaId) {
    return _verifController.tunggakanNominalByMember(anggotaId);
  }

  List<String> memberIuranStatusLabels(String anggotaId, {int limit = 4}) {
    return _verifController.memberPeriodStatusLabels(anggotaId, limit: limit);
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

  void accPembayaran(String idIuran, Object roleBendahara) {
    _verifController.accPembayaran(idIuran, roleBendahara);
  }
}
