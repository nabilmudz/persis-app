class IuranDetailModel {
  final String idDetail;
  final String idIuran; 
  final String npa;     
  final int bulan;
  final int tahun;
  final double nominal;

  IuranDetailModel({
    required this.idDetail,
    required this.idIuran,
    required this.npa,
    required this.bulan,
    required this.tahun,
    required this.nominal,
  });

  factory IuranDetailModel.fromJson(Map<String, dynamic> json) {
    return IuranDetailModel(
      idDetail: json['idDetail'] ?? '',
      idIuran: json['idIuran'] ?? '',
      npa: json['npa'] ?? '',
      bulan: json['bulan'] ?? 1,
      tahun: json['tahun'] ?? DateTime.now().year,
      nominal: (json['nominal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idDetail': idDetail,
      'idIuran': idIuran,
      'npa': npa,
      'bulan': bulan,
      'tahun': tahun,
      'nominal': nominal,
    };
  }
}