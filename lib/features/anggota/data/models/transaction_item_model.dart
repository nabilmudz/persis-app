class TransactionItemModel {
  final String? id;
  final String? anggotaId;
  final String? periodId;
  final String? status;
  final int? amount;
  final String? description;
  final String? createdAt;
  final int? periodMonth;
  final int? periodYear;

  TransactionItemModel({
    this.id,
    this.anggotaId,
    this.periodId,
    this.status,
    this.amount,
    this.description,
    this.createdAt,
    this.periodMonth,
    this.periodYear,
  });
  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    final itemJson = json['item'] is Map
        ? Map<String, dynamic>.from(json['item'] as Map)
        : <String, dynamic>{};

    final periodJson = json['period'] is Map
        ? Map<String, dynamic>.from(json['period'] as Map)
        : json['dues_period'] is Map
        ? Map<String, dynamic>.from(json['dues_period'] as Map)
        : json['duesPeriod'] is Map
        ? Map<String, dynamic>.from(json['duesPeriod'] as Map)
        : null;

    final source = <String, dynamic>{...itemJson, ...json};

    return TransactionItemModel(
      id: _readString(source['_id'] ?? source['id']),
      anggotaId: _readString(source['anggota_id'] ?? source['anggotaId']),
      periodId: _readString(
        source['period_id'] ??
            source['periodId'] ??
            source['dues_period_id'] ??
            source['duesPeriodId'],
      ),
      status: _readString(source['status']),
      amount:
          _readInt(periodJson?['amount']) ??
          _readInt(source['amount']) ??
          _readInt(source['total_amount']) ??
          _readInt(source['totalAmount']),
      description:
          _readString(source['description']) ??
          _buildPeriodDescription(
            _readInt(periodJson?['month']),
            _readInt(periodJson?['year']),
          ),
      createdAt: _readString(source['created_at'] ?? source['createdAt']),
      periodMonth: _readInt(periodJson?['month']),
      periodYear: _readInt(periodJson?['year']),
    );
  }

  Object? get jumlah => amount;

  static String? _readString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int? _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _buildPeriodDescription(int? month, int? year) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    if (month == null || year == null) {
      return 'Iuran';
    }

    return 'Iuran ${months[month]} $year';
  }
}
