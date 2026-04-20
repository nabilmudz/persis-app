import '../models/anggota_model.dart';
import '../models/lokasi_model.dart';
import 'lokasi_local_datasources.dart';

LokasiModel _lokasiPjById(String lokasiId) {
  return dummyLokasi.firstWhere(
    (lokasi) => lokasi.id == lokasiId,
    orElse: () => LokasiModel(
      id: lokasiId,
      nama: 'Lokasi tidak ditemukan',
      tingkat: TingkatLokasi.pj,
    ),
  );
}

List<AnggotaModel> dummyAnggota = [
  AnggotaModel(
    id: 'ANG-001',
    nama: 'Ahmad Fauzan',
    noAnggota: '2026.01.001',
    lokasiPj: _lokasiPjById('PJ-01'), // Terhubung ke Ciparay
  ),
  AnggotaModel(
    id: 'ANG-002',
    nama: 'Nashwa Fathia',
    noAnggota: '2026.01.002',
    lokasiPj: _lokasiPjById('PJ-02'), // Terhubung ke Baleendah
  ),
  AnggotaModel(
    id: 'ANG-003',
    nama: 'Budi Santoso',
    noAnggota: '2026.01.003',
    lokasiPj: _lokasiPjById('PJ-01'), // Terhubung ke Ciparay juga
  ),
  AnggotaModel(
    id: 'ANG-004',
    nama: 'Siti Aminah',
    noAnggota: '2026.01.004',
    lokasiPj: _lokasiPjById('PJ-03'), // Terhubung ke Cibiru
  ),
];
