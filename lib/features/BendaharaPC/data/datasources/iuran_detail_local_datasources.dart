import 'package:persis_app/features/BendaharaPC/data/models/iuran_detail_model.dart';

final List<IuranDetailModel> dummyDaftarIuranDetail = [

  // =========================================================
  // SKENARIO 1: SETORAN KOLEKTIF OLEH BENDHARA PJ
  // Header IUR-PJ-001 (Total: Rp 30.000)
  // PJ membayar untuk NPA 10.10.12345 & 10.10.54321
  // =========================================================
  
  // NPA: 10.10.12345 (Bayar 2 Bulan)
  IuranDetailModel(
    idDetail: 'DTL-001',
    idIuran: 'IUR-PJ-001', 
    npa: '10.10.12345',
    bulan: 1, // Januari
    tahun: 2026,
    nominal: 10000,
  ),
  IuranDetailModel(
    idDetail: 'DTL-002',
    idIuran: 'IUR-PJ-001', 
    npa: '10.10.12345',
    bulan: 2, // Februari
    tahun: 2026,
    nominal: 10000,
  ),
  
  // NPA: 10.10.54321 (Bayar 1 Bulan) - Beda user, satu struk
  IuranDetailModel(
    idDetail: 'DTL-003',
    idIuran: 'IUR-PJ-001', 
    npa: '10.10.54321',
    bulan: 1, // Januari
    tahun: 2026,
    nominal: 10000,
  ),

  // =========================================================
  // SKENARIO 2: SETORAN INDIVIDU OLEH ANGGOTA LANGSUNG
  // Header IUR-ANG-002 (Total: Rp 20.000)
  // NPA 10.10.99999 bayar mandiri langsung (2 Bulan)
  // =========================================================
  
  // NPA: 10.10.99999 (Bayar 2 Bulan)
  IuranDetailModel(
    idDetail: 'DTL-004',
    idIuran: 'IUR-ANG-002', 
    npa: '10.10.99999',
    bulan: 3, // Maret
    tahun: 2026,
    nominal: 10000,
  ),
  IuranDetailModel(
    idDetail: 'DTL-005',
    idIuran: 'IUR-ANG-002', 
    npa: '10.10.99999',
    bulan: 4, // April
    tahun: 2026,
    nominal: 10000,
  ),
];