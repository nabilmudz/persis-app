class BankAccountModel {
  final String? id;
  final String? regionId;
  final String? paymentMethodId;
  final String? bankName;
  final String? accountNumber;
  final String? qrisImageUrl;
  final bool? isActive;

  BankAccountModel({
    this.id,
    this.regionId,
    this.paymentMethodId,
    this.bankName,
    this.accountNumber,
    this.qrisImageUrl,
    this.isActive,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) =>
      BankAccountModel(
        id: json['_id'] ?? json['id'],
        regionId: json['region_id'] ?? json['regionId'],
        paymentMethodId: json['payment_method_id'] ?? json['paymentMethodId'],
        bankName: json['bank_name'] ?? json['bankName'],
        accountNumber: json['account_number'] ?? json['accountNumber'],
        qrisImageUrl: json['qris_image_url'] ?? json['qrisImageUrl'],
        isActive: json['is_active'] ?? json['isActive'],
      );

  Map<String, dynamic> toJson() => {
    "payment_method_id": paymentMethodId,
    "bank_name": bankName,
    "account_number": accountNumber,
    "qris_image_url": qrisImageUrl,
    "is_active": isActive,
  };
}
