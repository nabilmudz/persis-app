enum StatusIuran { diverifikasi, menungguVerifikasi, belumDibayar, tunggakan }

enum MetodePembayaran { transferBank, tunai, qrisCode }

class IuranModel {
  final String id;
  final String lokasiPjNama;
  final double nominal;
  final DateTime tanggalBayar;
  final String? buktiTransferUrl;
  MetodePembayaran? metodePembayaran;
  StatusIuran status;
  final String? catatan;

  IuranModel({
    required this.id,
    required this.lokasiPjNama,
    required this.nominal,
    required this.tanggalBayar,
    required this.buktiTransferUrl,
    this.metodePembayaran,
    this.status = StatusIuran.belumDibayar, // Default saat pertama kali buat
    this.catatan,
  });

  // Parsing dari JSON (contoh ngambil dari database)
  factory IuranModel.fromJson(Map<String, dynamic> json) {
    return IuranModel(
      id: json['id'] ?? '',
      lokasiPjNama: (json['lokasiPjNama'] ?? '').toString(),
      nominal: (json['nominal'] ?? 0).toDouble(),
      tanggalBayar: DateTime.parse(json['tanggalBayar']),
      buktiTransferUrl: json['buktiTransferUrl'] ?? '',
      metodePembayaran: json['metodePembayaran'] != null
          ? MetodePembayaran.values.firstWhere(
              (e) => e.name == json['metodePembayaran'],
              orElse: () => MetodePembayaran.transferBank,
            )
          : null,
      // Mengubah string dari database jadi Enum
      status: StatusIuran.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StatusIuran.belumDibayar,
      ),
      catatan: json['catatan'],
    );
  }

  // Convert ke JSON untuk dikirim ke database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lokasiPjNama': lokasiPjNama,
      'nominal': nominal,
      'tanggalBayar': tanggalBayar.toIso8601String(),
      'buktiTransferUrl': buktiTransferUrl,
      'status':
          status.name, // Simpan sebagai string (belumDibayar, tunggakan, dll)
      'catatan': catatan,
      'metodePembayaran': metodePembayaran?.name,
    };
  }
}
