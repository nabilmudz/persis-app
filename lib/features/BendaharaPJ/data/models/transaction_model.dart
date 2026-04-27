class TransactionModel {
  final String? creatorId;
  final String? paymentMethodId;
  final int? totalAmount;
  final String? status;
  final String? accStatus; // Baru: sesuai JSON
  final bool? isSynced;    // Baru: sesuai JSON
  final String? createdAt; // Baru: format ISO8601
  final List<TransactionItemModel>? items;

  TransactionModel({
    this.creatorId, this.paymentMethodId, this.totalAmount, 
    this.status, this.accStatus, this.isSynced, this.createdAt, this.items
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    creatorId: json['creator_id'],
    paymentMethodId: json['payment_method_id'],
    totalAmount: json['total_amount'],
    status: json['status'],
    accStatus: json['acc_status'],
    isSynced: json['is_synced'],
    createdAt: json['created_at'],
    items: (json['items'] as List?)?.map((x) => TransactionItemModel.fromJson(x)).toList(),
  );

  Map<String, dynamic> toJson() => {
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
  final String? periodId;      // Baru
  final String? status;        // Baru
  final String? duesPeriodId;  // Baru
  final int? amount;
  final String? description;

  TransactionItemModel({
    this.anggotaId, this.periodId, this.status, 
    this.duesPeriodId, this.amount, this.description
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) => TransactionItemModel(
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