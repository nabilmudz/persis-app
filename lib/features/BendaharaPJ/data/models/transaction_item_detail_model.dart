import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';

/// Model untuk satu item dari endpoint /api/transaction-item/user/{userId}.
class TransactionItemDetailModel {
  final String? id;
  final String? anggotaId;
  final String? transactionId;
  final String? duesPeriodId;
  final String? periodId;
  final String? status; // 'paid', 'tunggakan', 'unpaid', dll
  final int? amount;
  final String? description;

  // Jika backend menyertakan nested dues_period
  final DuesPeriodInfo? duesPeriod;

  const TransactionItemDetailModel({
    this.id,
    this.anggotaId,
    this.transactionId,
    this.duesPeriodId,
    this.periodId,
    this.status,
    this.amount,
    this.description,
    this.duesPeriod,
  });

  factory TransactionItemDetailModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemDetailModel(
      id: json['_id'] ?? json['id'],
      anggotaId: json['anggota_id'],
      transactionId: json['transaction_id'],
      duesPeriodId: json['dues_period_id'],
      periodId: json['period_id'],
      status: json['status'],
      amount: (json['amount'] as num?)?.toInt(),
      description: json['description'],
      duesPeriod: json['dues_period'] != null
          ? DuesPeriodInfo.fromJson(
              json['dues_period'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Resolve bulan dari data yang tersedia (nested dues_period, periodId, description).
  int? resolveMonth({List<DuesPeriodModel>? globalDuesPeriods}) {
    if (duesPeriod?.month != null) return duesPeriod!.month;

    // Coba lookup dari list DuesPeriods global
    if (globalDuesPeriods != null && duesPeriodId != null) {
      for (final dp in globalDuesPeriods) {
        if (dp.id == duesPeriodId && dp.month != null) {
          return dp.month;
        }
      }
    }

    final src = periodId ?? duesPeriodId ?? description ?? '';
    
    // Format YYYY-MM
    final match = RegExp(r'(\d{4})[-_/](\d{1,2})').firstMatch(src);
    if (match != null) {
      return int.tryParse(match.group(2)!);
    }

    // Format teks nama bulan, misal: "Iuran Maret 2026"
    final lowerSrc = src.toLowerCase();
    const months = [
      'januari', 'februari', 'maret', 'april', 'mei', 'juni',
      'juli', 'agustus', 'september', 'oktober', 'november', 'desember'
    ];
    for (int i = 0; i < months.length; i++) {
      if (lowerSrc.contains(months[i])) {
        return i + 1; // 1-12
      }
    }

    return null;
  }
  int? resolveYear({List<DuesPeriodModel>? globalDuesPeriods}) {
    if (duesPeriod?.year != null) return duesPeriod!.year;

    // Coba lookup dari list DuesPeriods global
    if (globalDuesPeriods != null && duesPeriodId != null) {
      for (final dp in globalDuesPeriods) {
        if (dp.id == duesPeriodId && dp.year != null) {
          return dp.year;
        }
      }
    }

    final src = periodId ?? duesPeriodId ?? description ?? '';
    
    // Format YYYY-MM
    final match = RegExp(r'(\d{4})[-_/](\d{1,2})').firstMatch(src);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    // Coba cari tahun berdiri sendiri (4 digit)
    final yearMatch = RegExp(r'(19|20)\d{2}').firstMatch(src);
    return yearMatch != null ? int.tryParse(yearMatch.group(0)!) : null;
  }

  Object? toJson() {}
}

/// Info dues period yang mungkin di-embed oleh backend.
class DuesPeriodInfo {
  final String? id;
  final int? month;
  final int? year;
  final double? amount;
  final bool? isActive;

  const DuesPeriodInfo({
    this.id,
    this.month,
    this.year,
    this.amount,
    this.isActive,
  });

  factory DuesPeriodInfo.fromJson(Map<String, dynamic> json) {
    return DuesPeriodInfo(
      id: json['_id'] ?? json['id'],
      month: (json['month'] as num?)?.toInt(),
      year: (json['year'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toDouble(),
      isActive: json['is_active'],
    );
  }
}
