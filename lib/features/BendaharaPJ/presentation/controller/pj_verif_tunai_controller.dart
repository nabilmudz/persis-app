import 'package:flutter/foundation.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';

enum PjMonthStatus { lunas, tunggakan, belumJatuhTempo }

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

  PjVerifTunaiController({
    required List<TransactionModel> transactions,
    List<DuesPeriodModel> duesPeriods = const [],
  }) : _transactions = List<TransactionModel>.from(transactions),
       _duesPeriods = List<DuesPeriodModel>.from(duesPeriods);

  List<TransactionModel> _transactions;
  List<DuesPeriodModel>? _duesPeriods;

  List<DuesPeriodModel> get _safeDuesPeriods =>
      _duesPeriods ?? const <DuesPeriodModel>[];

  void updateData({
    required List<TransactionModel> transactions,
    required List<DuesPeriodModel> duesPeriods,
  }) {
    _transactions = List<TransactionModel>.from(transactions);
    _duesPeriods = List<DuesPeriodModel>.from(duesPeriods);
    notifyListeners();
  }

  String _periodKey(int month, int year) {
    final mm = month.toString().padLeft(2, '0');
    return '$year-$mm';
  }

  DuesPeriodModel? _findDuesPeriodByMonthYear(int month, int year) {
    for (final period in _safeDuesPeriods) {
      if (period.month == month && period.year == year) {
        return period;
      }
    }
    return null;
  }

  DuesPeriodModel? _findDuesPeriodById(String? id) {
    final normalized = id?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    for (final period in _safeDuesPeriods) {
      if (period.id == normalized) {
        return period;
      }
    }

    return null;
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
      final duesPeriod = _findDuesPeriodById(source);
      if (duesPeriod != null &&
          duesPeriod.month != null &&
          duesPeriod.year != null) {
        return _periodKey(duesPeriod.month!, duesPeriod.year!);
      }

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
    // Prioritaskan status 'paid' sesuai instruksi user
    if (itemStatus == 'paid') {
      return true;
    }

    // Fallback manual jika status item adalah 'unpaid'
    if (itemStatus == 'unpaid') {
      return false;
    }

    // Jika item status tidak eksplisit, cek status transaksi utama
    final txStatus = (tx.status ?? '').trim().toLowerCase();
    if (txStatus == 'completed' || txStatus == 'paid') {
      return true;
    }

    return false;
  }

  PjMonthStatus _resolvePeriodStatus({
    required String anggotaId,
    required int month,
    required int year,
  }) {
    final duesPeriod = _findDuesPeriodByMonthYear(month, year);
    if (duesPeriod == null) {
      return PjMonthStatus.belumJatuhTempo;
    }

    final periodId = duesPeriod.id;
    bool hasPaidItem = false;

    for (final tx in _transactions) {
      final items = tx.items ?? const <TransactionItemModel>[];
      for (final item in items) {
        // Cek apakah anggotaId sama dengan anggota kartu iuran
        if (item.anggotaId != anggotaId) {
          continue;
        }

        // Ambil dues-periods ID dari item (biasanya di periodId atau duesPeriodId)
        final itemPeriodSource = item.periodId ?? item.duesPeriodId ?? '';

        // Cek apakah dues-periods sama dengan bulan dan tahun pada kartu iuran
        // Kita bandingkan via ID karena ID tersebut unik untuk kombinasi bulan/tahun
        if (itemPeriodSource == periodId &&
            periodId != null &&
            periodId.isNotEmpty) {
          // Cek status transaction-item = "paid"
          if (_hasPaidTransaction(tx: tx, item: item)) {
            hasPaidItem = true;
            break;
          }
        }
      }
      if (hasPaidItem) break;
    }

    if (hasPaidItem) {
      return PjMonthStatus.lunas; // Warna Hijau
    }

    if (_isPastPeriod(month, year)) {
      return PjMonthStatus.tunggakan; // Warna Merah
    }

    return PjMonthStatus.belumJatuhTempo; // Warna Putih
  }

  Map<String, _MemberPeriodState> periodStatesByMember(String anggotaId) {
    final map = <String, _MemberPeriodState>{};

    if (_safeDuesPeriods.isEmpty) {
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
          final status =
              parsed != null && _isPastPeriod(parsed.month, parsed.year)
              ? (paid ? PjMonthStatus.lunas : PjMonthStatus.tunggakan)
              : (paid ? PjMonthStatus.lunas : PjMonthStatus.belumJatuhTempo);

          if (current == null) {
            map[periodKey] = _MemberPeriodState(
              periodKey: periodKey,
              nominal: nominal,
              status: status,
            );
            continue;
          }

          map[periodKey] = _MemberPeriodState(
            periodKey: periodKey,
            nominal: nominal > 0 ? nominal : current.nominal,
            status:
                current.status == PjMonthStatus.lunas ||
                    status == PjMonthStatus.lunas
                ? PjMonthStatus.lunas
                : status,
          );
        }
      }

      return map;
    }

    for (final period in _safeDuesPeriods) {
      final month = period.month;
      final year = period.year;
      if (month == null || year == null) {
        continue;
      }

      final periodKey = _periodKey(month, year);
      final current = map[periodKey];
      final nominal = (period.amount ?? 0).round();
      final status = _resolvePeriodStatus(
        anggotaId: anggotaId,
        month: month,
        year: year,
      );

      if (current == null) {
        map[periodKey] = _MemberPeriodState(
          periodKey: periodKey,
          nominal: nominal,
          status: status,
        );
        continue;
      }

      map[periodKey] = _MemberPeriodState(
        periodKey: periodKey,
        nominal: nominal > 0 ? nominal : current.nominal,
        status:
            current.status == PjMonthStatus.lunas ||
                status == PjMonthStatus.lunas
            ? PjMonthStatus.lunas
            : status,
      );
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
    // Untuk status kartu di list anggota, kita cek apakah ada tunggakan.
    // Jika ada satu saja tunggakan, maka status kartu jadi tunggakan (merah).
    final states = periodStatesByMember(anggotaId).values.toList();

    if (states.any((state) => state.status == PjMonthStatus.tunggakan)) {
      return PjMonthStatus.tunggakan;
    }

    if (states.any((state) => state.status == PjMonthStatus.lunas)) {
      return PjMonthStatus.lunas;
    }

    return PjMonthStatus.belumJatuhTempo;
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
    final duesPeriod = _findDuesPeriodByMonthYear(month, targetYear);
    if (duesPeriod == null) {
      return PjMonthStatus.belumJatuhTempo;
    }

    return _resolvePeriodStatus(
      anggotaId: anggotaId,
      month: month,
      year: targetYear,
    );
  }

  String _statusLabel(PjMonthStatus status) {
    switch (status) {
      case PjMonthStatus.lunas:
        return 'Lunas';
      case PjMonthStatus.tunggakan:
        return 'Tunggakan';
      case PjMonthStatus.belumJatuhTempo:
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
