import 'package:flutter/foundation.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import 'pj_verif_tunai_controller.dart';

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
  }

  final UserRemoteDataSource _userDataSource;
  final TransactionRemoteDataSource _transactionDataSource;

  final List<UserModel> _members = [];
  final List<TransactionModel> _transactions = [];

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
      final results = await Future.wait<dynamic>([
        _userDataSource.getAllUsers(),
        _transactionDataSource.getHistory(),
        _transactionDataSource.getDuesPeriods(),
      ]);

      final users = (results[0] as List<UserModel>)
          .where((user) => user.id != null && user.id!.trim().isNotEmpty)
          .toList();
      final transactions = results[1] as List<TransactionModel>;
      final duesPeriods = results[2] as List<DuesPeriodModel>;

      _members
        ..clear()
        ..addAll(users);

      _transactions
        ..clear()
        ..addAll(transactions);

      _verifController.updateData(
        transactions: _transactions,
        duesPeriods: duesPeriods,
      );
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
}
