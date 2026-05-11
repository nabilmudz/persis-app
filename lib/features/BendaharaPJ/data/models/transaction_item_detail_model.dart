class TransactionItemDetailModel {
  final String? id;
  final String? anggotaId;
  final String? transactionId;
  final String? duesPeriodId;
  final String? periodId;
  final String? status;
  final int? amount;
  final String? description;

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
    final itemJson = json['item'] is Map
        ? Map<String, dynamic>.from(json['item'] as Map)
        : <String, dynamic>{};
    final periodJson = json['period'] is Map
        ? Map<String, dynamic>.from(json['period'] as Map)
        : json['dues_period'] is Map
        ? Map<String, dynamic>.from(json['dues_period'] as Map)
        : null;

    final source = <String, dynamic>{...itemJson, ...json};

    return TransactionItemDetailModel(
      id: source['_id'] ?? source['id'],
      anggotaId: source['anggota_id'],
      transactionId: source['transaction_id'],
      duesPeriodId: source['dues_period_id'],
      periodId: source['period_id'] ?? itemJson['period_id'],
      status: json['status'] as String?, // ← eksplisit dari root
      amount: periodJson?['amount'] is num
          ? (periodJson!['amount'] as num).toInt()
          : source['amount'] is num
          ? (source['amount'] as num).toInt()
          : int.tryParse(source['amount']?.toString() ?? ''),
      description: source['description'],
      duesPeriod: periodJson != null
          ? DuesPeriodInfo.fromJson(periodJson)
          : null,
    );
  }

  /// Resolve bulan dari data yang tersedia (nested dues_period, periodId, description).
  int? resolveMonth() {
    if (duesPeriod?.month != null) return duesPeriod!.month;

    final src = periodId ?? duesPeriodId ?? description ?? '';

    // Format YYYY-MM
    final match = RegExp(r'(\d{4})[-_/](\d{1,2})').firstMatch(src);
    if (match != null) {
      return int.tryParse(match.group(2)!);
    }

    // Format teks nama bulan, misal: "Iuran Maret 2026"
    final lowerSrc = src.toLowerCase();
    const months = [
      'januari',
      'februari',
      'maret',
      'april',
      'mei',
      'juni',
      'juli',
      'agustus',
      'september',
      'oktober',
      'november',
      'desember',
    ];
    for (int i = 0; i < months.length; i++) {
      if (lowerSrc.contains(months[i])) {
        return i + 1; // 1-12
      }
    }

    return null;
  }

  int? resolveYear() {
    if (duesPeriod?.year != null) return duesPeriod!.year;

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

  Map<String, dynamic> toJson() => {
    'id': id,
    '_id': id,
    'anggota_id': anggotaId,
    'transaction_id': transactionId,
    'dues_period_id': duesPeriodId,
    'period_id': periodId,
    'status': status,
    'amount': amount,
    'description': description,
    'period': duesPeriod != null
        ? {
            '_id': duesPeriod!.id,
            'month': duesPeriod!.month,
            'year': duesPeriod!.year,
            'amount': duesPeriod!.amount,
          }
        : null,
    'item': {
      '_id': id,
      'anggota_id': anggotaId,
      'transaction_id': transactionId,
      'dues_period_id': duesPeriodId,
      'period_id': periodId,
      'status': status,
      'amount': amount,
      'description': description,
    },
  };
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
