class UserModel {
  final String? id;
  final String? npa;
  final String? name;
  final String? fullname;
  final String? email;
  final String? role;
  final String? roleId;
  final String? status;
  final String? noHp; // ← tambah
  final bool? isActive; // ← tambah, ganti dari status String
  final DateTime? createdAt; // ← ganti dari String

  String? get code => npa;

  UserModel({
    this.id,
    this.npa,
    this.name,
    this.fullname,
    this.email,
    this.role,
    this.roleId,
    this.status,
    this.noHp,
    this.isActive,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['_id'] ?? json['id'],
    npa: json['npa'],
    name: json['name'],
    fullname: json['fullname'] ?? json['full_name'] ?? json['name'],
    email: json['email'],
    role: json['role'],
    roleId: json['role_id'],
    status: json['status'],
    noHp:
        json['no_hp'] ??
        json['no_telp'] ??
        json['phone'], // ← common key variants
    isActive:
        json['is_active'] ??
        (json['status'] == 'active' ||
            json['status'] == 'aktif'), // ← fallback dari status
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'npa': npa,
    'name': name,
    'fullname': fullname,
    'email': email,
    'role': role,
    'role_id': roleId,
    'status': status,
    'no_hp': noHp,
    'is_active': isActive,
    'created_at': createdAt?.toIso8601String(),
  };
}
