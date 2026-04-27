import 'package:flutter/foundation.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import 'package:persis_app/helpers/object_id_helper.dart';

enum PjMonthStatus { lunas, tunggakan, belumJatuhTempo }

class PjPaymentCartItem {
  final String id;
  final String anggotaId;
  final String anggotaNama;
  final int month;
  final int year;
  final double nominal;

  const PjPaymentCartItem({
    required this.id,
    required this.anggotaId,
    required this.anggotaNama,
    required this.month,
    required this.year,
    required this.nominal,
  });

  String get periodLabel => '$month/$year';
}

class PjSubmitResult {
  final String transactionId;
  final int totalItems;
  final double totalNominal;

  const PjSubmitResult({
    required this.transactionId,
    required this.totalItems,
    required this.totalNominal,
  });
}

class PjVerifController extends ChangeNotifier {
  static const int _fallbackNominal = 10000;
  static const Set<String> _paidStatuses = {
    'paid',
    'lunas',
    'verified',
    'diverifikasi',
    'success',
    'done',
  };
  static const Set<String> _unpaidStatuses = {
    'unpaid',
    'pending',
    'belum',
    'tunggakan',
    'overdue',
  };

  PjVerifController({
    required List<TransactionModel> transactions,
    required List<UserModel> members,
    required TransactionRemoteDataSource transactionDataSource,
  }) : _transactions = transactions,
       _members = members,
       _transactionDataSource = transactionDataSource;

  final List<TransactionModel> _transactions;
  final List<UserModel> _members;
  final TransactionRemoteDataSource _transactionDataSource;
  final List<PjPaymentCartItem> _cartItems = [];

  String _displayName(UserModel member) {
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

  String _periodKey(int month, int year) {
    final mm = month.toString().padLeft(2, '0');
    return '$year-$mm';
  }

  String _monthLabel(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    if (month < 1 || month > 12) {
      return '-';
    }

    return monthNames[month - 1];
  }

  String _periodLabelFromKey(String periodKey) {
    final parsed = _parsePeriodKey(periodKey);
    if (parsed == null) {
      return periodKey;
    }

    return '${_monthLabel(parsed.month)} ${parsed.year}';
  }

  _PeriodValue? _parsePeriodKey(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final match = RegExp(r'(\d{4})[-_/](\d{1,2})').firstMatch(raw);
    if (match == null) {
      return null;
    }

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    if (year == null || month == null || month < 1 || month > 12) {
      return null;
    }

    return _PeriodValue(month: month, year: year);
  }

  String _resolveItemPeriodKey(TransactionItemModel item, TransactionModel tx) {
    final periodSources = [item.periodId, item.duesPeriodId];
    for (final source in periodSources) {
      final parsed = _parsePeriodKey(source);
      if (parsed != null) {
        return _periodKey(parsed.month, parsed.year);
      }
    }

    final createdAt = tx.createdAt;
    if (createdAt != null) {
      final parsedDate = DateTime.tryParse(createdAt);
      if (parsedDate != null) {
        return _periodKey(parsedDate.month, parsedDate.year);
      }
    }

    final now = DateTime.now();
    return _periodKey(now.month, now.year);
  }

  bool _isPaid({
    required TransactionModel tx,
    required TransactionItemModel item,
  }) {
    final itemStatus = (item.status ?? '').trim().toLowerCase();
    if (_paidStatuses.contains(itemStatus)) {
      return true;
    }

    if (_unpaidStatuses.contains(itemStatus)) {
      return false;
    }

    final txAcc = (tx.accStatus ?? '').trim().toLowerCase();
    if (_paidStatuses.contains(txAcc)) {
      return true;
    }

    final txStatus = (tx.status ?? '').trim().toLowerCase();
    if (_paidStatuses.contains(txStatus)) {
      return true;
    }

    return false;
  }

  Map<String, _MemberPeriodState> periodStatesByMember(String anggotaId) {
    final map = <String, _MemberPeriodState>{};

    for (final tx in _transactions) {
      final items = tx.items ?? const <TransactionItemModel>[];
      for (final item in items) {
        if (item.anggotaId != anggotaId) {
          continue;
        }

        final periodKey = _resolveItemPeriodKey(item, tx);
        final current = map[periodKey];
        final nominal = item.amount ?? 0;
        final isPaid = _isPaid(tx: tx, item: item);

        if (current == null) {
          map[periodKey] = _MemberPeriodState(
            periodKey: periodKey,
            nominal: nominal,
            isPaid: isPaid,
          );
          continue;
        }

        map[periodKey] = _MemberPeriodState(
          periodKey: periodKey,
          nominal: nominal > 0 ? nominal : current.nominal,
          isPaid: current.isPaid || isPaid,
        );
      }
    }

    return map;
  }

  List<String> memberPeriodStatusLabels(String anggotaId, {int limit = 4}) {
    final states = periodStatesByMember(anggotaId).values.toList();
    if (states.isEmpty) {
      return const <String>['Belum ada transaksi'];
    }

    states.sort((a, b) => b.periodKey.compareTo(a.periodKey));
    return states.take(limit).map((state) {
      final label = _periodLabelFromKey(state.periodKey);
      return '$label: ${state.isPaid ? 'Lunas' : 'Belum'}';
    }).toList();
  }

  int tunggakanCountByMember(String anggotaId) {
    return periodStatesByMember(
      anggotaId,
    ).values.where((state) => !state.isPaid).length;
  }

  double tunggakanNominalByMember(String anggotaId) {
    final total = periodStatesByMember(anggotaId).values
        .where((state) => !state.isPaid)
        .fold<int>(0, (sum, state) => sum + state.nominal);
    return total.toDouble();
  }

  List<PjPaymentCartItem> get cartItems =>
      List<PjPaymentCartItem>.unmodifiable(_cartItems);
  int get cartItemCount => _cartItems.length;
  double get cartTotalNominal =>
      _cartItems.fold(0, (total, item) => total + item.nominal);

  bool isInCart({
    required String anggotaId,
    required int month,
    required int year,
  }) {
    return _cartItems.any(
      (item) =>
          item.anggotaId == anggotaId &&
          item.month == month &&
          item.year == year,
    );
  }

  void addMonthToCart({
    required UserModel member,
    required int month,
    required int year,
    double? nominal,
  }) {
    final anggotaId = member.id;
    if (anggotaId == null || anggotaId.isEmpty) {
      return;
    }

    final isKnownMember = _members.any((m) => m.id == anggotaId);
    if (!isKnownMember) {
      return;
    }

    if (isInCart(anggotaId: anggotaId, month: month, year: year)) {
      return;
    }

    final resolvedNominal =
        nominal ??
        getNominalForMemberMonth(
          anggotaId: anggotaId,
          month: month,
          year: year,
        );

    _cartItems.add(
      PjPaymentCartItem(
        id: ObjectIdHelper.generateLocalId(),
        anggotaId: anggotaId,
        anggotaNama: _displayName(member),
        month: month,
        year: year,
        nominal: resolvedNominal,
      ),
    );

    notifyListeners();
  }

  void removeFromCart(String cartItemId) {
    _cartItems.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
  }

  void removeMemberFromCart(String anggotaId) {
    _cartItems.removeWhere((item) => item.anggotaId == anggotaId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<PjSubmitResult?> submitCart({
    String paymentMethodId = 'bank_transfer',
    String? creatorId,
  }) async {
    if (_cartItems.isEmpty) {
      return null;
    }

    final transactionId = ObjectIdHelper.generateLocalId();
    final totalNominalInt = cartTotalNominal.round();

    final transaction = TransactionModel(
      creatorId: creatorId,
      paymentMethodId: paymentMethodId,
      totalAmount: totalNominalInt,
      status: 'submitted',
      accStatus: 'pending',
      isSynced: true,
      createdAt: DateTime.now().toIso8601String(),
      items: _cartItems
          .map(
            (item) => TransactionItemModel(
              anggotaId: item.anggotaId,
              periodId: _periodKey(item.month, item.year),
              status: 'pending',
              duesPeriodId: null,
              amount: item.nominal.round(),
              description:
                  'Iuran ${_monthLabel(item.month)} ${item.year} dari keranjang $transactionId',
            ),
          )
          .toList(),
    );

    final isCreated = await _transactionDataSource.createTransaction(
      transaction,
    );
    if (!isCreated) {
      return null;
    }

    _transactions.add(transaction);

    final result = PjSubmitResult(
      transactionId: transactionId,
      totalItems: _cartItems.length,
      totalNominal: cartTotalNominal,
    );

    _cartItems.clear();
    notifyListeners();
    return result;
  }

  double getNominalForMemberMonth({
    required String anggotaId,
    required int month,
    required int year,
  }) {
    final expectedKey = _periodKey(month, year);
    int? latestAmount;

    for (final tx in _transactions) {
      final items = tx.items ?? const <TransactionItemModel>[];
      for (final item in items) {
        if (item.anggotaId != anggotaId) {
          continue;
        }

        final periodKey = _resolveItemPeriodKey(item, tx);
        if (periodKey == expectedKey && item.amount != null) {
          latestAmount = item.amount;
        }
      }
    }

    if (latestAmount != null && latestAmount > 0) {
      return latestAmount.toDouble();
    }

    final memberStates = periodStatesByMember(anggotaId).values.toList();
    if (memberStates.isEmpty) {
      return _fallbackNominal.toDouble();
    }

    memberStates.sort((a, b) => b.periodKey.compareTo(a.periodKey));
    final nominal = memberStates.first.nominal;
    if (nominal <= 0) {
      return _fallbackNominal.toDouble();
    }

    return nominal.toDouble();
  }

  PjMonthStatus getMonthStatus({
    required String anggotaId,
    required int month,
    int? year,
  }) {
    final targetYear = year ?? DateTime.now().year;
    final targetKey = _periodKey(month, targetYear);
    final state = periodStatesByMember(anggotaId)[targetKey];

    if (state == null) {
      return PjMonthStatus.belumJatuhTempo;
    }

    if (state.isPaid) {
      return PjMonthStatus.lunas;
    }

    return PjMonthStatus.tunggakan;
  }

  void accPembayaran(String idIuran, Object roleBendahara) {
    // Tidak digunakan pada alur terbaru PJ.
  }
}

class _MemberPeriodState {
  final String periodKey;
  final int nominal;
  final bool isPaid;

  const _MemberPeriodState({
    required this.periodKey,
    required this.nominal,
    required this.isPaid,
  });
}

class _PeriodValue {
  final int month;
  final int year;

  const _PeriodValue({required this.month, required this.year});
}
