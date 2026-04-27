class UserModel {
  final String? id;
  final String? npa;
  final String? email;
  final String? password;
  final String? fullname;
  final bool? isActive;
  final String? noHp;
  final String? role;
  final int? v;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    this.npa,
    this.email,
    this.password,
    this.fullname,
    this.isActive,
    this.noHp,
    this.role,
    this.v,
    this.createdAt,
    this.updatedAt,
  });

  // Compatibility aliases for existing UI/controller usage.
  String? get code => npa;
  String? get name => fullname;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['_id'] ?? json['id'],
    npa: json['npa'] ?? json['code'],
    email: json['email'],
    fullname: json['fullname'] ?? json['name'],
    isActive: json['is_active'] ?? json['isActive'],
    noHp: json['no_hp'] ?? json['noHp'],
    role: json['role'],
    v: json['__v'] is int ? json['__v'] : int.tryParse('${json['__v'] ?? ''}'),
    createdAt: _parseDateTime(json['createdAt']),
    updatedAt: _parseDateTime(json['updatedAt']),
  );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (id != null) data['_id'] = id;
    if (npa != null) data['npa'] = npa;
    if (email != null) data['email'] = email;
    if (password != null) data['password'] = password;
    if (fullname != null) data['fullname'] = fullname;
    if (isActive != null) data['is_active'] = isActive;
    if (noHp != null) data['no_hp'] = noHp;
    if (role != null) data['role'] = role;
    if (v != null) data['__v'] = v;
    if (createdAt != null) data['createdAt'] = createdAt!.toIso8601String();
    if (updatedAt != null) data['updatedAt'] = updatedAt!.toIso8601String();
    return data;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
