class PaymentMethodModel {
  final String? id;
  final String? code;
  final String? label;

  PaymentMethodModel({this.id, this.code, this.label});

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) =>
      PaymentMethodModel(
        id: json['_id'] ?? json['id'],
        code: json['code'],
        label: json['label'],
      );

  Map<String, dynamic> toJson() => {
    "code": code,
    "label": label,
  };
}
