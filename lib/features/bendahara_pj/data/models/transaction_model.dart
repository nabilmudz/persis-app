class TransactionModel {
  final String? id;
  final String? code;
  final String? type;
  final String? creatorId;
  final String? paymentMethodId;
  final String? paymentMethodName;
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
  final String? rejectionReason;

  TransactionModel({
    this.id,
    this.code,
    this.type,
    this.creatorId,
    this.paymentMethodId,
    this.paymentMethodName,
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
    this.rejectionReason,
  });

  factory TransactionModel.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    final id = map['_id'] ?? map['id'];
    final code = map['code'];
    final type = map['type'];
    final creatorId = map['creator_id'] is Map
        ? (map['creator_id']['_id'] ?? map['creator_id']['id'])?.toString()
        : (map['creator_id'] ?? map['creatorId'])?.toString();
    final paymentMethodId = map['payment_method_id'] is Map
        ? (map['payment_method_id']['_id'] ?? map['payment_method_id']['id'])
              ?.toString()
        : (map['payment_method_id'] ?? map['paymentMethodId'])?.toString();
    final paymentMethodName = map['payment_method_id'] is Map
        ? (map['payment_method_id']['code'] ??
                  map['payment_method_id']['name'] ??
                  map['payment_method_id']['nama'])
              ?.toString()
              ?.trim()
        : null;
    final proofUrl = map['proof_url'] ?? map['proofUrl'];
    final bankName = map['bank_name'] ?? map['bankName'];
    final bankAccountName = map['bank_account_name'] ?? map['bankAccountName'];
    final verifiedBy = map['verified_by'] is Map
        ? (map['verified_by']['fullname'] ??
                  map['verified_by']['name'] ??
                  map['verified_by']['full_name'])
              ?.toString()
        : (map['verified_by'] ?? map['verifiedBy'])?.toString();
    final totalAmount = map['total_amount'] ?? map['totalAmount'];
    final status = map['status'];
    final accStatus = (map['acc_status'] ?? map['accStatus'])?.toString();
    final isSynced = map['is_synced'] ?? map['isSynced'];
    final createdAt = map['created_at'] ?? map['createdAt'];
    final updatedAt = map['updated_at'] ?? map['updatedAt'];
    final accBy = map['acc_by'] is Map
        ? (map['acc_by']['fullname'] ??
                  map['acc_by']['name'] ??
                  map['acc_by']['full_name'])
              ?.toString()
        : (map['acc_by'] ?? map['accBy'])?.toString();
    final accAt = map['acc_at'] ?? map['accAt'];
    final syncedAt = map['synced_at'] ?? map['syncedAt'];
    final rejectionReason = map['rejection_reason']?.toString();

    final rawItems = map['items'] ?? map['transaction_items'];
    List<TransactionItemModel> parsedItems;
    if (rawItems is List) {
      parsedItems = rawItems
          .map(
            (x) => TransactionItemModel.fromJson(
              Map<String, dynamic>.from(x as Map),
            ),
          )
          .toList();
    } else if (rawItems is Map) {
      parsedItems = [
        TransactionItemModel.fromJson(Map<String, dynamic>.from(rawItems)),
      ];
    } else {
      parsedItems = <TransactionItemModel>[];
    }

    String? memberName =
        map['member_name']?.toString() ?? map['memberName']?.toString();
    String? npa = map['npa']?.toString();

    final rawCreator = map['creator_id'];
    if (memberName == null && rawCreator is Map) {
      memberName =
          (rawCreator['fullname'] ??
                  rawCreator['name'] ??
                  rawCreator['full_name'])
              ?.toString();
    }
    if (npa == null && rawCreator is Map) {
      npa = rawCreator['npa']?.toString();
    }
    final rawCreator2 = map['creator'];
    if (memberName == null && rawCreator2 is Map) {
      memberName =
          (rawCreator2['fullname'] ??
                  rawCreator2['name'] ??
                  rawCreator2['full_name'])
              ?.toString();
    }
    if (npa == null && rawCreator2 is Map) {
      npa = rawCreator2['npa']?.toString();
    }
    if (memberName == null && parsedItems.isNotEmpty) {
      memberName = parsedItems.first.memberName;
    }
    if (npa == null && parsedItems.isNotEmpty) {
      npa = parsedItems.first.npa;
    }

    final rawAnggota = map['anggota_id'];
    String? anggotaId;
    if (rawAnggota is Map) {
      anggotaId = (rawAnggota['_id'] ?? rawAnggota['id'])?.toString();
    } else if (rawAnggota is String) {
      anggotaId = rawAnggota;
    } else {
      anggotaId = (map['anggotaId'])?.toString();
    }

    return TransactionModel(
      id: id,
      code: code,
      type: type,
      creatorId: creatorId,
      paymentMethodId: paymentMethodId,
      paymentMethodName: paymentMethodName,
      proofUrl: proofUrl,
      bankName: bankName,
      bankAccountName: bankAccountName,
      verifiedBy: verifiedBy,
      totalAmount: totalAmount,
      status: status,
      accStatus: accStatus,
      isSynced: isSynced,
      createdAt: createdAt,
      updatedAt: updatedAt,
      accBy: accBy,
      accAt: accAt,
      syncedAt: syncedAt,
      memberName: memberName,
      npa: npa,
      items: parsedItems,
      anggotaId: anggotaId,
      rejectionReason: rejectionReason,
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "code": code,
    "type": type,
    "creator_id": creatorId,
    "payment_method_id": paymentMethodId,
    if (paymentMethodName != null) "payment_method_name": paymentMethodName,
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
    if (rejectionReason != null) "rejection_reason": rejectionReason,
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
    String? paymentMethodName,
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
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
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
  final String? transactionId;
  final String? periodId;
  final String? status;
  final String? duesPeriodId;
  final int? amount;
  final String? description;
  final String? memberName;
  final String? npa;
  final String? buktiUrl;
  final int? periodMonth;
  final int? periodYear;

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
    this.buktiUrl,
    this.periodMonth,
    this.periodYear,
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
    int? resolvedPeriodMonth;
    int? resolvedPeriodYear;
    if (rawPeriod is String) {
      resolvedPeriodId = rawPeriod;
    } else if (rawPeriod is Map) {
      resolvedPeriodId =
          rawPeriod['_id']?.toString() ?? rawPeriod['id']?.toString();
      resolvedPeriodMonth = rawPeriod['month'] is int
          ? rawPeriod['month'] as int
          : int.tryParse(rawPeriod['month']?.toString() ?? '');
      resolvedPeriodYear = rawPeriod['year'] is int
          ? rawPeriod['year'] as int
          : int.tryParse(rawPeriod['year']?.toString() ?? '');
    }

    final rawDuesPeriod =
        json['dues_period_id'] ?? json['duesPeriodId'] ?? json['dues_period'];
    if (resolvedPeriodMonth == null && rawDuesPeriod is Map) {
      resolvedPeriodMonth = rawDuesPeriod['month'] is int
          ? rawDuesPeriod['month'] as int
          : int.tryParse(rawDuesPeriod['month']?.toString() ?? '');
      resolvedPeriodYear = rawDuesPeriod['year'] is int
          ? rawDuesPeriod['year'] as int
          : int.tryParse(rawDuesPeriod['year']?.toString() ?? '');
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
      buktiUrl: json['bukti_url']?.toString(),
      periodMonth: resolvedPeriodMonth,
      periodYear: resolvedPeriodYear,
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
    String? buktiUrl,
    int? periodMonth,
    int? periodYear,
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
      buktiUrl: buktiUrl ?? this.buktiUrl,
      periodMonth: periodMonth ?? this.periodMonth,
      periodYear: periodYear ?? this.periodYear,
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
    if (buktiUrl != null) "bukti_url": buktiUrl,
    if (periodMonth != null) "period_month": periodMonth,
    if (periodYear != null) "period_year": periodYear,
  };
}

class DuesPeriodModel {
  final String? id;
  final int? year;
  final int? month;
  final double? amount;
  final bool? isActive;

  DuesPeriodModel({this.id, this.year, this.month, this.amount, this.isActive});

  factory DuesPeriodModel.fromJson(Map<String, dynamic> json) =>
      DuesPeriodModel(
        id: json['_id'] ?? json['id'],
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
