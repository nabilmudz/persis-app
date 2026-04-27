class PaymentMethodModel {
  final String? id;
  final String? code;
  final String? name;
  final String? description;

  PaymentMethodModel({
    this.id,
    this.code,
    this.name,
    this.description,
  });

  // Untuk mengubah JSON dari API (Response) menjadi Objek Dart
  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      // Mengantisipasi format ID dari NestJS/MongoDB (_id) atau standar (id)
      id: json['_id'] ?? json['id'],
      code: json['code'],
      name: json['name'],
      description: json['description'],
    );
  }

  // Untuk mengubah Objek Dart menjadi JSON (Request Body) saat Create/Update
  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "name": name,
      "description": description,
    };
  }
}