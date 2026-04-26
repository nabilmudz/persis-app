import 'lokasi_model.dart';
import 'role_model.dart';
enum UserState { unactivated, active, inactive }

class AnggotaModel {
  final String id;
  final String nama;
  final String npa;
  final LokasiModel lokasiPj;
  final UserState state;
  final List<RoleModel> roles;
  final RoleType activeRole;
  
  AnggotaModel({
    required this.id,
    required this.nama,
    required this.npa,
    required this.lokasiPj,
    required this.state,
    required this.roles,
    required this.activeRole,
  });

  // Fungsi untuk mengubah data dari JSON (API/Firebase) ke Model
  factory AnggotaModel.fromJson(Map<String, dynamic> json) {
    final dynamic lokasiPjJson = json['lokasiPj'];

    return AnggotaModel(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      npa: json['npa'] ?? '',
      lokasiPj: lokasiPjJson is Map<String, dynamic>
          ? LokasiModel.fromJson(lokasiPjJson)
          : LokasiModel(
              id: lokasiPjJson?.toString() ?? '',
              nama: '',
              tingkat: TingkatLokasi.pj,
            ),
      state: UserState.values.firstWhere((e) => e.name == json['state'], orElse: () => UserState.unactivated),
      roles: (json['roles'] as List<dynamic>?)
          ?.map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      activeRole: RoleType.values.firstWhere((e) => e.name == json['activeRole'], orElse: () => RoleType.anggota),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'npa': npa,
      'lokasiPj': lokasiPj.toJson(),
      'state': state.name,
      'roles': roles.map((e) => e.toJson()).toList(),
      'activeRole': activeRole.name,
    };
  }
}
