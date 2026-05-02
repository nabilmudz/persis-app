class TransactionModel {
  final String? id; // MongoDB _id
  final String? creatorId;
  final String? paymentMethodId;
  final int? totalAmount;
  final String? status;
  final String? accStatus;
  final bool? isSynced;
  final String? createdAt;
  final List<TransactionItemModel>? items;

  TransactionModel({
    this.id,
    this.creatorId,
    this.paymentMethodId,
    this.totalAmount,
    this.status,
    this.accStatus,
    this.isSynced,
    this.createdAt,
    this.items,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['_id'] ?? json['id'],
        creatorId: json['creator_id'],
        paymentMethodId: json['payment_method_id'],
        totalAmount: json['total_amount'],
        status: json['status'],
        accStatus: json['acc_status'],
        isSynced: json['is_synced'],
        createdAt: json['created_at'],
        items: (json['items'] as List?)
            ?.map((x) => TransactionItemModel.fromJson(x))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "creator_id": creatorId,
    "payment_method_id": paymentMethodId,
    "total_amount": totalAmount,
    "status": status,
    "acc_status": accStatus,
    "is_synced": isSynced,
    "created_at": createdAt,
    "items": items?.map((x) => x.toJson()).toList(),
  };
}

class TransactionItemModel {
  final String? anggotaId;
  final String? periodId; // Baru
  final String? status; // Baru
  final String? duesPeriodId; // Baru
  final int? amount;
  final String? description;

  TransactionItemModel({
    this.anggotaId,
    this.periodId,
    this.status,
    this.duesPeriodId,
    this.amount,
    this.description,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) =>
      TransactionItemModel(
        anggotaId: json['anggota_id'],
        periodId: json['period_id'],
        status: json['status'],
        duesPeriodId: json['dues_period_id'],
        amount: json['amount'],
        description: json['description'],
      );

  Map<String, dynamic> toJson() => {
    "anggota_id": anggotaId,
    "period_id": periodId,
    "status": status,
    "dues_period_id": duesPeriodId,
    "amount": amount,
    "description": description,
  };
}

class DuesPeriodModel {
  final String? id; // MongoDB _id
  final int? year;
  final int? month;
  final double? amount;
  final bool? isActive;

  DuesPeriodModel({this.id, this.year, this.month, this.amount, this.isActive});

  factory DuesPeriodModel.fromJson(Map<String, dynamic> json) =>
      DuesPeriodModel(
        id: json['_id'] ?? json['id'], // Use _id from MongoDB
        year: json['year'],
        month: json['month'],
        amount: (json['amount'] as num?)?.toDouble(),
        isActive: json['is_active'],
      );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "year": year,
    "month": month,
    "amount": amount,
    "is_active": isActive,
  };
}
