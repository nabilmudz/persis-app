class TransactionItemModel {
  final String? id;
  final String? anggotaId;
  final String? periodId;
  final String? status;
  final int? amount;
  final String? description;
  final String? createdAt;

  TransactionItemModel({
    this.id,
    this.anggotaId,
    this.periodId,
    this.status,
    this.amount,
    this.description,
    this.createdAt,
  });
  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      id: json['_id'] ?? json['id'],
      anggotaId: json['anggota_id'],
      periodId: json['period_id'],
      status: json['status'] as String?,
      amount: json['amount'],
      description: json['description'],
      createdAt: json['created_at'],
    );
  }
}
