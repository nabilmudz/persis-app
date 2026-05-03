class RoleModel {
  final String? id;
  final String? code;
  final String? name;
  final String? description;

  RoleModel({this.id, this.code, this.name, this.description});

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
    id: json['_id'] ?? json['id'],
    code: json['code'],
    name: json['name'],
    description: json['description'],
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "name": name,
    "description": description,
  };
}
