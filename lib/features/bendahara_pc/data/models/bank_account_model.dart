import 'dart:typed_data';

class BankAccountModel {
  final String? id;
  final String? regionId;
  final String? paymentMethodId;
  final String? bankName;
  final String? accountNumber;
  final String? qrisImageUrl;
  final Uint8List? qrisImageBytes;
  final String? qrisImageName;
  final bool? isActive;

  BankAccountModel({
    this.id,
    this.regionId,
    this.paymentMethodId,
    this.bankName,
    this.accountNumber,
    this.qrisImageUrl,
    this.qrisImageBytes,
    this.qrisImageName,
    this.isActive,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    String? resolveId(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) return raw;
      if (raw is Map) {
        return (raw['_id'] ?? raw['id'])?.toString();
      }
      return raw.toString();
    }

    return BankAccountModel(
      id: json['_id'] ?? json['id'],
      regionId: resolveId(json['region_id'] ?? json['regionId']),
      paymentMethodId: resolveId(
        json['payment_method_id'] ?? json['paymentMethodId'],
      ),
      bankName: json['bank_name'] ?? json['bankName'],
      accountNumber: json['account_number'] ?? json['accountNumber'],
      qrisImageUrl: json['qris_image_url'] ?? json['qrisImageUrl'],
      isActive: json['is_active'] ?? json['isActive'],
    );
  }

  Map<String, dynamic> toJson() => {
    "payment_method_id": paymentMethodId,
    "bank_name": bankName,
    "account_number": accountNumber,
    "qris_image_url": qrisImageUrl,
    "is_active": isActive,
  };
}
