import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/role_model.dart';

class RoleRemoteDataSource {
  final String baseUrl;
  RoleRemoteDataSource(this.baseUrl);

  Future<List<RoleModel>> getAll() async {
    final response = await http.get(Uri.parse('$baseUrl/roles'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => RoleModel.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat roles');
  }

  Future<void> create(RoleModel role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/roles'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(role.toJson()),
    );
    if (response.statusCode != 201) throw Exception('Gagal membuat role');
  }

  Future<void> update(String id, RoleModel role) async {
    await http.patch(
      Uri.parse('$baseUrl/roles/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(role.toJson()),
    );
  }
}
