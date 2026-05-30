import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:persis_app/features/anggota/data/repositories/anggota_repository.dart';
import 'package:persis_app/features/anggota/presentation/controller/anggota_controller.dart';
import 'package:persis_app/features/anggota/data/models/transaction_item_model.dart';

class MockAnggotaRepository extends Mock implements AnggotaRepository {}

void main() {
  late AnggotaController controller;
  late MockAnggotaRepository mockRepo;

  setUp(() {
    mockRepo = MockAnggotaRepository();
    controller = AnggotaController(repository: mockRepo);
  });

  // Menyiapkan data pura-pura (Mock Data) untuk pengetesan
  final mockTxUnpaid = TransactionItemModel(
    status: 'pending',
    amount: 50000,
    description: 'Iuran Januari 2024',
  );
  final mockTxPaid1 = TransactionItemModel(
    status: 'lunas',
    amount: 20000,
    description: 'Iuran Februari 2024',
    createdAt: '2024-02-01T10:00:00Z',
  );
  final mockTxPaid2 = TransactionItemModel(
    status: 'success',
    amount: 20000,
    description: 'Iuran Maret 2023',
    createdAt: '2023-03-01T10:00:00Z',
  );

  group('AnggotaController Unit Tests', () {

    // ==========================================
    // TC01: fetchRiwayatTransaksi() - Positif
    // ==========================================
    test('TC01: fetchRiwayatTransaksi updates data and calculates unpaid tagihan', () async {
      // Setup (arrange, build)
      when(() => mockRepo.getRiwayatIuran(any(), year: any(named: 'year')))
          .thenAnswer((_) async => [mockTxUnpaid, mockTxPaid1]);

      // Exercise (act, operate)
      await controller.fetchRiwayatTransaksi(userId: '123');

      // Verify (assert, check)
      expect(controller.riwayatTransaksi.length, 2, reason: 'Harus tersimpan 2 data transaksi');
      expect(controller.totalTagihan, 50000, reason: 'Total tagihan hanya menghitung yang statusnya pending/unpaid');
      expect(controller.errorMessage, isNull);
    });

    // ==========================================
    // TC02: fetchRiwayatTransaksi() - Negatif
    // ==========================================
    test('TC02: fetchRiwayatTransaksi failure sets error and clears data', () async {
      // Setup (arrange, build)
      when(() => mockRepo.getRiwayatIuran(any(), year: any(named: 'year')))
          .thenThrow(Exception('Gagal ambil data'));

      // Exercise (act, operate)
      await controller.fetchRiwayatTransaksi(userId: '123');

      // Verify (assert, check)
      expect(controller.riwayatTransaksi, isEmpty, reason: 'Data harus kosong jika terjadi error');
      expect(controller.totalTagihan, 0, reason: 'Tagihan diset ke 0 jika error');
      expect(controller.errorMessage, contains('Gagal ambil data'));
    });

    // ==========================================
    // TC03: riwayatLunas() - Positif
    // ==========================================
    test('TC03: riwayatLunas only returns completed transactions', () {
      // Setup (arrange, build)
      controller.riwayatTransaksi = [mockTxUnpaid, mockTxPaid1, mockTxPaid2];
      
      // Exercise (act, operate)
      final lunas = controller.riwayatLunas;
      
      // Verify (assert, check)
      expect(lunas.length, 2, reason: 'Hanya ada 2 transaksi yang berstatus lunas');
      expect(lunas.every((tx) => tx.status != 'pending'), isTrue, reason: 'Tidak boleh ada transaksi pending');
    });

    // ==========================================
    // TC04: filterLunasByTahun() - Positif
    // ==========================================
    test('TC04: filterLunasByTahun correctly filters by year in description', () {
      // Setup (arrange, build)
      controller.riwayatTransaksi = [mockTxPaid1, mockTxPaid2];
      
      // Exercise (act, operate)
      final filtered2024 = controller.filterLunasByTahun('Tahun 2024');
      final semua = controller.filterLunasByTahun('Semua');

      // Verify (assert, check)
      expect(filtered2024.length, 1, reason: 'Hanya ada 1 transaksi lunas di tahun 2024');
      expect(filtered2024.first.description, contains('2024'));
      expect(semua.length, 2, reason: 'Filter "Semua" harus menampilkan seluruh data lunas');
    });

    // ==========================================
    // TC05: hitungTotalNominal() - Positif
    // ==========================================
    test('TC05: hitungTotalNominal correctly sums transaction amounts', () {
      // Setup (arrange, build)
      final transaksiLunas = [mockTxPaid1, mockTxPaid2];
      
      // Exercise (act, operate)
      final total = controller.hitungTotalNominal(transaksiLunas);
      
      // Verify (assert, check)
      // 20000 + 20000 = 40000
      expect(total, 40000.0, reason: 'Hasil perhitungan akumulasi data harus 40000');
    });

  });
}