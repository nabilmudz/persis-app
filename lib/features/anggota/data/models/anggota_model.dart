import 'lokasi_model.dart';

class AnggotaModel {
  final String id;
  final String nama;
  final String noAnggota;
  final LokasiModel lokasiPj;

  AnggotaModel({
    required this.id,
    required this.nama,
    required this.noAnggota,
    required this.lokasiPj,
  });

  // Fungsi untuk mengubah data dari JSON (API/Firebase) ke Model
  factory AnggotaModel.fromJson(Map<String, dynamic> json) {
    final dynamic lokasiPjJson = json['lokasiPj'];

    return AnggotaModel(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      noAnggota: json['noAnggota'] ?? '',
      lokasiPj: lokasiPjJson is Map<String, dynamic>
          ? LokasiModel.fromJson(lokasiPjJson)
          : LokasiModel(
              id: lokasiPjJson?.toString() ?? '',
              nama: '',
              tingkat: TingkatLokasi.pj,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'noAnggota': noAnggota,
      'lokasiPj': lokasiPj.toJson(),
    };
  }
}
