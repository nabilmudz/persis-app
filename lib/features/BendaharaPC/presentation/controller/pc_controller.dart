import 'package:flutter/foundation.dart';
import 'package:persis_app/features/BendaharaPC/data/models/iuran_model.dart';
import 'package:persis_app/features/BendaharaPC/data/datasources/iuran_local_datasources.dart';
import 'package:persis_app/features/anggota/data/models/lokasi_model.dart';

class PcController extends ChangeNotifier {
  List<IuranModel> daftarIuran = dummyDaftarIuran;

  void accPembayaran(String idIuran, TingkatLokasi roleBendahara) {
    // Cari index iuran yang mau di-ACC di dalam list
    int index = daftarIuran.indexWhere((i) => i.id == idIuran);

    if (index == -1) {
      print('Data Iuran tidak ditemukan!');
      return;
    }

    if (daftarIuran[index].status == StatusIuran.belumDibayar ||
        daftarIuran[index].status == StatusIuran.tunggakan) {
      daftarIuran[index].status = StatusIuran.diverifikasi;
      notifyListeners();
      print('Iuran berhasil diverifikasi');
    } else {
      print('Iuran tidak terverifikasi');
    }
  }
}
