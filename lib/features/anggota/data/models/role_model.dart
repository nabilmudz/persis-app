enum RoleType { anggota, bendaharaPJ, bendaharaPC, bendaharaPD, admin }

class RoleModel {
  final RoleType type;

  RoleModel({required this.type});

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      type: RoleType.values.firstWhere((e) => e.name == json['type']),
    );
  }

  Map<String, dynamic> toJson() => {'type': type.name};
}
