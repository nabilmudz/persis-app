class TransactionModel {
  final String? id; 
  final String? code; 
  final String? type; 
  final String? creatorId;
  final String? paymentMethodId;
  final String? proofUrl; 
  final String? bankName; 
  final String? bankAccountName; 
  final String? verifiedBy; 
  final int? totalAmount;
  final String? status;
  final String? accStatus;
  final bool? isSynced;
  final String? createdAt;
  final String? updatedAt; 
  final String? accBy;
  final String? accAt;
  final String? syncedAt;
  final String? memberName; 
  final String? npa; 
  final List<TransactionItemModel>? items;
  final String? anggotaId;

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
    this.accBy,
    this.accAt,
    this.syncedAt,
    this.memberName,
    this.npa,
    this.items,
    this.anggotaId,
  });


  factory TransactionModel.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return TransactionModel(
      id: map['_id'] ?? map['id'],
      code: map['code'],
      type: map['type'],
      creatorId: map['creator_id'] is Map 
          ? (map['creator_id']['_id'] ?? map['creator_id']['id'])?.toString()
          : (map['creator_id'] ?? map['creatorId'])?.toString(),
      paymentMethodId: map['payment_method_id'] ?? map['paymentMethodId'],
      proofUrl: map['proof_url'] ?? map['proofUrl'],
      bankName: map['bank_name'] ?? map['bankName'],
      bankAccountName: map['bank_account_name'] ?? map['bankAccountName'],
      verifiedBy: map['verified_by'] is Map
          ? (map['verified_by']['fullname'] ?? map['verified_by']['name'] ?? map['verified_by']['full_name'])?.toString()
          : (map['verified_by'] ?? map['verifiedBy'])?.toString(),
      totalAmount: map['total_amount'] ?? map['totalAmount'],
      status: map['status'],
      accStatus: map['acc_status']?.toString(),
      isSynced: map['is_synced'] ?? map['isSynced'],
      createdAt: map['created_at'] ?? map['createdAt'],
      updatedAt: map['updated_at'] ?? map['updatedAt'],
      accBy: map['acc_by'] is Map
          ? (map['acc_by']['fullname'] ?? map['acc_by']['name'] ?? map['acc_by']['full_name'])?.toString()
          : (map['acc_by'] ?? map['accBy'])?.toString(),
      accAt: map['acc_at'] ?? map['accAt'],
      syncedAt: map['synced_at'] ?? map['syncedAt'],
      memberName: map['member_name'] ?? map['memberName'] ?? 
          (map['creator_id'] is Map 
              ? (map['creator_id']['fullname'] ?? map['creator_id']['name'] ?? map['creator_id']['full_name'])?.toString()
              : (map['creator'] is Map
                  ? (map['creator']['fullname'] ?? map['creator']['name'] ?? map['creator']['full_name'])?.toString()
                  : null)),
      npa: map['npa'] ?? 
          (map['creator_id'] is Map 
              ? map['creator_id']['npa']?.toString()
              : (map['creator'] is Map
                  ? map['creator']['npa']?.toString()
                  : null)),
      items: (() {
        final rawItems = map['items'] ?? map['transaction_items'];
        if (rawItems is List) {
          return rawItems
              .map((x) => TransactionItemModel.fromJson(Map<String, dynamic>.from(x as Map)))
              .toList();
        } else if (rawItems is Map) {
          return [TransactionItemModel.fromJson(Map<String, dynamic>.from(rawItems))];
        }
        return <TransactionItemModel>[];
      })(),
      anggotaId: map['anggota_id'] is Map
          ? (map['anggota_id']['_id'] ?? map['anggota_id']['id'])?.toString()
          : (map['anggota_id'] ?? map['anggotaId'])?.toString(),
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
        "acc_by": accBy,
        "acc_at": accAt,
        "synced_at": syncedAt,
        "member_name": memberName,
        "npa": npa,
        "items": items?.map((x) => x.toJson()).toList(),
        "anggota_id": anggotaId,
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
    String? accBy,
    String? accAt,
    String? syncedAt,
    List<TransactionItemModel>? items,
    String? anggotaId,
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
      accBy: accBy ?? this.accBy,
      accAt: accAt ?? this.accAt,
      syncedAt: syncedAt ?? this.syncedAt,
      items: items ?? this.items,
      anggotaId: anggotaId ?? this.anggotaId,
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
  final String? memberName; // Baru dari populated user
  final String? npa; // Baru dari populated user

  TransactionItemModel({
    this.anggotaId,
    this.transactionId,
    this.periodId,
    this.status,
    this.duesPeriodId,
    this.amount,
    this.description,
    this.memberName,
    this.npa,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    final rawAnggota = json['anggota_id'] ?? json['anggotaId'];
    String? resolvedAnggotaId;
    String? resolvedMemberName;
    String? resolvedNpa;

    if (rawAnggota is String) {
      resolvedAnggotaId = rawAnggota;
    } else if (rawAnggota is Map) {
      resolvedAnggotaId =
          rawAnggota['_id']?.toString() ?? rawAnggota['id']?.toString();
      resolvedMemberName =
          rawAnggota['fullname']?.toString() ?? rawAnggota['name']?.toString();
      resolvedNpa = rawAnggota['npa']?.toString();
    }

    final rawPeriod = json['period_id'] ?? json['periodId'];
    String? resolvedPeriodId;
    if (rawPeriod is String) {
      resolvedPeriodId = rawPeriod;
    } else if (rawPeriod is Map) {
      resolvedPeriodId =
          rawPeriod['_id']?.toString() ?? rawPeriod['id']?.toString();
    }

    return TransactionItemModel(
      anggotaId: resolvedAnggotaId,
      transactionId: json['transaction_id'] ?? json['transactionId'],
      periodId: resolvedPeriodId,
      status: json['status'],
      duesPeriodId: json['dues_period_id'] ?? json['duesPeriodId'],
      amount: json['amount'],
      description: json['description'],
      memberName: resolvedMemberName,
      npa: resolvedNpa,
    );
  }

  TransactionItemModel copyWith({
    String? anggotaId,
    String? transactionId,
    String? periodId,
    String? status,
    String? duesPeriodId,
    int? amount,
    String? description,
    String? memberName,
    String? npa,
  }) {
    return TransactionItemModel(
      anggotaId: anggotaId ?? this.anggotaId,
      transactionId: transactionId ?? this.transactionId,
      periodId: periodId ?? this.periodId,
      status: status ?? this.status,
      duesPeriodId: duesPeriodId ?? this.duesPeriodId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      memberName: memberName ?? this.memberName,
      npa: npa ?? this.npa,
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
    "member_name": memberName,
    "npa": npa,
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
