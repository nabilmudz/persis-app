import 'package:flutter/foundation.dart';
import 'package:persis_app/features/bendahara_pj/data/models/transaction_model.dart';

enum PjMonthStatus { paid, tunggakan, pending }

class MemberIuranStatusModel {
  final String label;
  final PjMonthStatus status;
  final double nominal;

  const MemberIuranStatusModel({
    required this.label,
    required this.status,
    required this.nominal,
  });
}

class PjVerifTunaiController extends ChangeNotifier {
  static const int _fallbackNominal = 20000;

  PjVerifTunaiController({required List<TransactionModel> transactions})
    : _transactions = List<TransactionModel>.from(transactions);

  List<TransactionModel> _transactions;

  void updateData({required List<TransactionModel> transactions}) {
    _transactions = List<TransactionModel>.from(transactions);
    notifyListeners();
  }

  String _periodKey(int month, int year) {
    final mm = month.toString().padLeft(2, '0');
    return '$year-$mm';
  }

  bool _isPastPeriod(int month, int year) {
    final now = DateTime.now();
    return year < now.year || (year == now.year && month < now.month);
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

  bool _hasPaidTransaction({
    required TransactionModel tx,
    required TransactionItemModel item,
  }) {
    final itemStatus = (item.status ?? '').trim().toLowerCase();
    if (itemStatus == 'paid' ||
        itemStatus == 'paid' ||
        itemStatus == 'completed') {
      return true;
    }

    if (itemStatus == 'unpaid' || itemStatus == 'tunggakan') {
      return false;
    }

    final txStatus = (tx.status ?? '').trim().toLowerCase();
    if (txStatus == 'completed' || txStatus == 'paid') {
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
        final paid = _hasPaidTransaction(tx: tx, item: item);
        final parsed = _parsePeriodKey(periodKey);

        final status = paid
            ? PjMonthStatus.paid
            : (parsed != null && _isPastPeriod(parsed.month, parsed.year)
                  ? PjMonthStatus.tunggakan
                  : PjMonthStatus.pending);

        if (current == null) {
          map[periodKey] = _MemberPeriodState(
            periodKey: periodKey,
            nominal: nominal > 0 ? nominal : _fallbackNominal,
            status: status,
          );
          continue;
        }

        map[periodKey] = _MemberPeriodState(
          periodKey: periodKey,
          nominal: nominal > 0
              ? nominal
              : (current.nominal > 0 ? current.nominal : _fallbackNominal),
          status:
              current.status == PjMonthStatus.paid ||
                  status == PjMonthStatus.paid
              ? PjMonthStatus.paid
              : (current.status == PjMonthStatus.tunggakan ||
                        status == PjMonthStatus.tunggakan
                    ? PjMonthStatus.tunggakan
                    : PjMonthStatus.pending),
        );
      }
    }

    return map;
  }

  List<MemberIuranStatusModel> memberPeriodStatusItems(
    String anggotaId, {
    int limit = 4,
  }) {
    final states = periodStatesByMember(anggotaId).values.toList();
    if (states.isEmpty) {
      return const <MemberIuranStatusModel>[];
    }

    states.sort((a, b) => b.periodKey.compareTo(a.periodKey));
    return states.take(limit).map((state) {
      return MemberIuranStatusModel(
        label: _periodLabelFromKey(state.periodKey),
        status: state.status,
        nominal: state.nominal.toDouble(),
      );
    }).toList();
  }

  List<String> memberPeriodStatusLabels(String anggotaId, {int limit = 4}) {
    final items = memberPeriodStatusItems(anggotaId, limit: limit);
    if (items.isEmpty) {
      return const <String>['Belum ada transaksi'];
    }

    return items
        .map((item) => '${item.label}: ${_statusLabel(item.status)}')
        .toList();
  }

  PjMonthStatus memberCardStatus(String anggotaId) {
    final states = periodStatesByMember(anggotaId).values.toList();

    if (states.any((state) => state.status == PjMonthStatus.tunggakan)) {
      return PjMonthStatus.tunggakan;
    }

    if (states.any((state) => state.status == PjMonthStatus.paid)) {
      return PjMonthStatus.paid;
    }

    return PjMonthStatus.pending;
  }

  int tunggakanCountByMember(String anggotaId) {
    return periodStatesByMember(
      anggotaId,
    ).values.where((state) => state.status == PjMonthStatus.tunggakan).length;
  }

  double tunggakanNominalByMember(String anggotaId) {
    final total = periodStatesByMember(anggotaId).values
        .where((state) => state.status == PjMonthStatus.tunggakan)
        .fold<int>(0, (sum, state) => sum + state.nominal);
    return total.toDouble();
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

    return _fallbackNominal.toDouble();
  }

  PjMonthStatus getMonthStatus({
    required String anggotaId,
    required int month,
    int? year,
  }) {
    final targetYear = year ?? DateTime.now().year;
    final periodKey = _periodKey(month, targetYear);
    final states = periodStatesByMember(anggotaId);
    final state = states[periodKey];

    if (state != null) {
      return state.status;
    }

    if (_isPastPeriod(month, targetYear)) {
      return PjMonthStatus.tunggakan;
    }

    return PjMonthStatus.pending;
  }

  String _statusLabel(PjMonthStatus status) {
    switch (status) {
      case PjMonthStatus.paid:
        return 'paid';
      case PjMonthStatus.tunggakan:
        return 'Tunggakan';
      case PjMonthStatus.pending:
        return 'Belum Bayar';
    }
  }
}

class _MemberPeriodState {
  final String periodKey;
  final int nominal;
  final PjMonthStatus status;

  const _MemberPeriodState({
    required this.periodKey,
    required this.nominal,
    required this.status,
  });
}

class _PeriodValue {
  final int month;
  final int year;

  const _PeriodValue({required this.month, required this.year});
}
