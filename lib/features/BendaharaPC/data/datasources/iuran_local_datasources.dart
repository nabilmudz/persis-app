import '../models/iuran_model.dart';
import 'package:persis_app/features/anggota/data/models/anggota_model.dart';
import 'package:persis_app/features/anggota/data/models/lokasi_model.dart';
import 'package:persis_app/features/anggota/data/datasources/anggota_local_datasource.dart';
import 'package:persis_app/features/anggota/data/datasources/lokasi_local_datasources.dart';

LokasiModel _fallbackLokasiPj() {
  return dummyLokasi.firstWhere(
    (lokasi) => lokasi.tingkat == TingkatLokasi.pj,
    orElse: () => LokasiModel(
      id: 'PJ-00',
      nama: 'Lokasi default',
      tingkat: TingkatLokasi.pj,
    ),
  );
}

AnggotaModel _anggotaById(String anggotaId) {
  return dummyAnggota.firstWhere(
    (anggota) => anggota.id == anggotaId,
    orElse: () => AnggotaModel(
      id: anggotaId,
      nama: 'Anggota tidak ditemukan',
      noAnggota: 'N/A',
      lokasiPj: _fallbackLokasiPj(),
    ),
  );
}

List<IuranModel> dummyDaftarIuran = [
  // 1. Contoh: Baru bayar transfer, nunggu di-ACC PJ
  IuranModel(
    id: 'IUR-001',
    idAnggota: _anggotaById('ANG-001'),
    nominal: 20000,
    tanggalBayar: DateTime.now().subtract(
      const Duration(days: 1),
    ), // Bayar kemarin
    buktiTransferUrl: 'https://contoh.com/gambar_bukti_1.jpg',
    metodePembayaran: MetodePembayaran.transferBank,
    status: StatusIuran.tunggakan,
  ),

  // 2. Contoh: Bayar tunai (tanpa bukti), sudah di-ACC PJ, nunggu PC
  IuranModel(
    id: 'IUR-002',
    idAnggota: _anggotaById('ANG-002'),
    nominal: 50000,
    tanggalBayar: DateTime.now().subtract(
      const Duration(days: 3),
    ), // 3 hari lalu
    buktiTransferUrl: null, // Kosong karena bayar cash
    metodePembayaran: MetodePembayaran.tunai,
    status: StatusIuran.menungguVerifikasi,
  ),

  // 3. Contoh: Udah di-ACC PC, nunggu PD
  IuranModel(
    id: 'IUR-003',
    idAnggota: _anggotaById('ANG-003'),
    nominal: 20000,
    tanggalBayar: DateTime.now().subtract(const Duration(days: 5)),
    buktiTransferUrl: 'https://contoh.com/gambar_bukti_3.jpg',
    metodePembayaran: MetodePembayaran.qrisCode,
    status: StatusIuran.menungguVerifikasi,
  ),

  // 4. Contoh: Iuran sudah lunas / terverifikasi sampai akhir
  IuranModel(
    id: 'IUR-004',
    idAnggota: _anggotaById('ANG-004'),
    nominal: 100000,
    tanggalBayar: DateTime.now().subtract(const Duration(days: 10)),
    buktiTransferUrl: 'https://contoh.com/gambar_bukti_4.jpg',
    metodePembayaran: MetodePembayaran.transferBank,
    status: StatusIuran.diverifikasi,
  ),
];
