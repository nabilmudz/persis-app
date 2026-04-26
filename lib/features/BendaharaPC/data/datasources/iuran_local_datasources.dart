import '../models/iuran_model.dart';
import 'package:persis_app/features/anggota/data/models/lokasi_model.dart';
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

String _lokasiPjNama(String? lokasiNama) {
  final lokasi = dummyLokasi.firstWhere(
    (item) => item.tingkat == TingkatLokasi.pj && item.nama == lokasiNama,
    orElse: _fallbackLokasiPj,
  );
  return lokasi.nama;
}

List<IuranModel> dummyDaftarIuran = [
  // 1. Contoh: Baru bayar transfer, nunggu di-ACC PJ
  IuranModel(
    id: 'IUR-001',
    lokasiPjNama: _lokasiPjNama('Jamaah Al-Hikmah'),
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
    lokasiPjNama: _lokasiPjNama('Jamaah Al-Hikmah'),
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
    lokasiPjNama: _lokasiPjNama('Cabang Bandung Selatan'),
    nominal: 20000,
    tanggalBayar: DateTime.now().subtract(const Duration(days: 5)),
    buktiTransferUrl: 'https://contoh.com/gambar_bukti_3.jpg',
    metodePembayaran: MetodePembayaran.qrisCode,
    status: StatusIuran.menungguVerifikasi,
  ),

  // 4. Contoh: Iuran sudah lunas / terverifikasi sampai akhir
  IuranModel(
    id: 'IUR-004',
    lokasiPjNama: _lokasiPjNama('Daerah Kota Bandung'),
    nominal: 100000,
    tanggalBayar: DateTime.now().subtract(const Duration(days: 10)),
    buktiTransferUrl: 'https://contoh.com/gambar_bukti_4.jpg',
    metodePembayaran: MetodePembayaran.transferBank,
    status: StatusIuran.diverifikasi,
  ),
];
