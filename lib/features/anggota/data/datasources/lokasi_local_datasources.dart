import '../models/lokasi_model.dart';

List<LokasiModel> dummyLokasi = [
  // Level PD
  LokasiModel(id: 'PD-01', nama: 'Jawa Barat', tingkat: TingkatLokasi.pd),
  
  // Level PC (Induknya ke PD-01)
  LokasiModel(id: 'PC-01', nama: 'Kab. Bandung', tingkat: TingkatLokasi.pc, parentId: 'PD-01'),
  LokasiModel(id: 'PC-02', nama: 'Kota Bandung', tingkat: TingkatLokasi.pc, parentId: 'PD-01'),

  // Level PJ (Induknya ke PC-01 / Kab. Bandung)
  LokasiModel(id: 'PJ-01', nama: 'Ciparay', tingkat: TingkatLokasi.pj, parentId: 'PC-01'),
  LokasiModel(id: 'PJ-02', nama: 'Baleendah', tingkat: TingkatLokasi.pj, parentId: 'PC-01'),
  
  // Level PJ (Induknya ke PC-02 / Kota Bandung)
  LokasiModel(id: 'PJ-03', nama: 'Cibiru', tingkat: TingkatLokasi.pj, parentId: 'PC-02'),
];