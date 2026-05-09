class TransactionModel {
  final String? id; // MongoDB _id
  final String? code; // Ditambahkan agar sesuai copyWith
  final String? type; // Ditambahkan agar sesuai copyWith
  final String? creatorId;
  final String? paymentMethodId;
  final String? proofUrl; // Ditambahkan agar sesuai copyWith
  final String? bankName; // Ditambahkan agar sesuai copyWith
  final String? bankAccountName; // Ditambahkan agar sesuai copyWith
  final String? verifiedBy; // Ditambahkan agar sesuai copyWith
  final int? totalAmount;
  final String? status;
  final String? accStatus;
  final bool? isSynced;
  final String? createdAt;
  final String? updatedAt; // Ditambahkan agar sesuai copyWith
  final String? memberName; // Dari API: member_name
  final String? npa; // Dari API: npa
  final List<TransactionItemModel>? items;

  TransactionModel({
    this.id,
    this.code,
    this.type,
    this.creatorId,
    this.paymentMethodId,
    this.proofUrl,
    this.bankName,
    this.bankAccountName,
    this.verifiedBy,
    this.totalAmount,
    this.status,
    this.accStatus,
    this.isSynced,
    this.createdAt,
    this.updatedAt,
    this.memberName,
    this.npa,
    this.items,
  });

  factory TransactionModel.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return TransactionModel(
      id: map['_id'] ?? map['id'],
      code: map['code'],
      type: map['type'],
      creatorId: map['creator_id'],
      paymentMethodId: map['payment_method_id'],
      proofUrl: map['proof_url'],
      bankName: map['bank_name'],
      bankAccountName: map['bank_account_name'],
      verifiedBy: map['verified_by'],
      totalAmount: map['total_amount'],
      status: map['status'],
      accStatus: map['acc_status'],
      isSynced: map['is_synced'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      memberName: map['member_name'],
      npa: map['npa'],
      items: (map['items'] as List?)
          ?.map((x) => TransactionItemModel.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "code": code,
        "type": type,
        "creator_id": creatorId,
        "payment_method_id": paymentMethodId,
        "proof_url": proofUrl,
        "bank_name": bankName,
        "bank_account_name": bankAccountName,
        "verified_by": verifiedBy,
        "total_amount": totalAmount,
        "status": status,
        "acc_status": accStatus,
        "is_synced": isSynced,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "member_name": memberName,
        "npa": npa,
        "items": items?.map((x) => x.toJson()).toList(),
      };

  TransactionModel copyWith({
    String? id,
    String? code,
    String? type,
    String? proofUrl,
    String? bankName,
    String? bankAccountName,
    String? status,
    String? accStatus,
    String? verifiedBy,
    String? paymentMethodId,
    String? creatorId,
    int? totalAmount,
    bool? isSynced,
    String? createdAt,
    String? updatedAt,
    List<TransactionItemModel>? items,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      proofUrl: proofUrl ?? this.proofUrl,
      bankName: bankName ?? this.bankName,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      status: status ?? this.status,
      accStatus: accStatus ?? this.accStatus,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      creatorId: creatorId ?? this.creatorId,
      totalAmount: totalAmount ?? this.totalAmount,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

class TransactionItemModel {
  final String? anggotaId;
  final String? transactionId; // Baru
  final String? periodId; // Baru
  final String? status; // Baru
  final String? duesPeriodId; // Baru
  final int? amount;
  final String? description;

  TransactionItemModel({
    this.anggotaId,
    this.transactionId,
    this.periodId,
    this.status,
    this.duesPeriodId,
    this.amount,
    this.description,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) =>
      TransactionItemModel(
        anggotaId: json['anggota_id'],
        transactionId: json['transaction_id'],
        periodId: json['period_id'],
        status: json['status'],
        duesPeriodId: json['dues_period_id'],
        amount: json['amount'],
        description: json['description'],
      );

  TransactionItemModel copyWith({
    String? anggotaId,
    String? transactionId,
    String? periodId,
    String? status,
    String? duesPeriodId,
    int? amount,
    String? description,
  }) {
    return TransactionItemModel(
      anggotaId: anggotaId ?? this.anggotaId,
      transactionId: transactionId ?? this.transactionId,
      periodId: periodId ?? this.periodId,
      status: status ?? this.status,
      duesPeriodId: duesPeriodId ?? this.duesPeriodId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
    "anggota_id": anggotaId,
    "transaction_id": transactionId,
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
