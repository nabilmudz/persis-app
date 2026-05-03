class UserModel {
  final String? id;
  final String? npa;
  final String? name;
  final String? fullname;
  final String? email;
  final String? role;
  final String? roleId;
  final String? status;
  final String? createdAt;

  // Ini kuncinya! Getter untuk menghubungkan .code ke .npa
  // Jadi kodingan temenmu yang manggil 'member.code' nggak akan error lagi.
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
        createdAt: json['created_at'],
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
        'created_at': createdAt,
      };
}
