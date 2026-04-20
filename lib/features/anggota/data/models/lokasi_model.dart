enum TingkatLokasi {
  pj, 
  pc, 
  pd, 
}

// 2. Class Model Lokasi
class LokasiModel {
  final String id;
  final String nama; // Contoh: "Ciparay" atau "Bandung"
  final TingkatLokasi tingkat; 
  final String? parentId; // ID lokasi di atasnya (bisa null kalau dia PD / level paling atas)

  LokasiModel({
    required this.id,
    required this.nama,
    required this.tingkat,
    this.parentId, 
  });

  // Fungsi dari JSON (Database) ke Model
  factory LokasiModel.fromJson(Map<String, dynamic> json) {
    return LokasiModel(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      // Parsing String dari DB ke Enum TingkatLokasi
      tingkat: json['tingkat'] != null
          ? TingkatLokasi.values.firstWhere(
              (e) => e.name == json['tingkat'],
              orElse: () => TingkatLokasi.pj, // Default ke PJ jika error
            )
          : TingkatLokasi.pj,
      parentId: json['parentId'], // Nullable
    );
  }

  // Fungsi dari Model ke JSON (untuk kirim ke Database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'tingkat': tingkat.name, // Simpan sebagai teks: "pj", "pc", atau "pd"
      'parentId': parentId,
    };
  }
}