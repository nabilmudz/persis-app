import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:persis_app/features/anggota/data/repositories/payment_repository.dart';
import 'package:persis_app/features/anggota/presentation/controller/pembayaran_controller.dart';
import 'package:persis_app/features/anggota/data/models/payment_model.dart';

// Membutuhkan mocking karena berhubungan dengan API/Server
class MockPaymentRepository extends Mock implements PaymentRepository {}

void main() {
  late PembayaranController controller;
  late MockPaymentRepository mockRepository;

  setUpAll(() {
    // Mendaftarkan nilai default mock untuk PaymentModel
    registerFallbackValue(PaymentModel(
      anggotaId: 'dummy',
      periodMulai: 'dummy',
      periodAkhir: 'dummy',
      totalAmount: 0,
      paymentMethod: 'dummy',
    ));
  });

  setUp(() {
    mockRepository = MockPaymentRepository();
    controller = PembayaranController(repository: mockRepository);
  });

  group('PembayaranController Unit Tests', () {
    
    // ==========================================
    // TC01: hitungTotal() - Positif
    // ==========================================
    test('TC01: hitungTotal calculates correct amount for valid period', () {
      // Setup (arrange, build)
      controller.periodeMulai = 'Januari 2024';
      controller.periodeAkhir = 'Maret 2024';
      
      // Exercise (act, operate)
      controller.hitungTotal();
      
      // Verify (assert, check)
      // Jarak Januari ke Maret = 3 bulan. Harga per bulan 20.000. Harus = 60.000
      expect(controller.totalTagihan, 60000);
      expect(controller.errorMessage, isNull);
    });

    // ==========================================
    // TC02: hitungTotal() - Negatif
    // ==========================================
    test('TC02: hitungTotal sets error when end period is before start period', () {
      // Setup (arrange, build) - Skenario mundur (Maret ke Januari)
      controller.periodeMulai = 'Maret 2024';
      controller.periodeAkhir = 'Januari 2024';
      
      // Exercise (act, operate)
      controller.hitungTotal();
      
      // Verify (assert, check)
      expect(controller.totalTagihan, 0, reason: 'Total tagihan harus 0 karena input bulan invalid/mundur');
      expect(controller.errorMessage, 'Periode akhir harus sama atau setelah periode mulai.');
    });

    // ==========================================
    // TC03: setBank() - Positif
    // ==========================================
    test('TC03: setBank changes selected bank and returns correct rekening', () {
      // Setup (arrange, build) - Default BCA

      // Exercise (act, operate)
      controller.setBank('Mandiri');
      
      // Verify (assert, check)
      expect(controller.selectedBank, 'Mandiri');
      expect(controller.nomorRekening, '1300 0011 2233'); // Sesuai dengan default data di list
    });

    // ==========================================
    // TC04: submitTransfer() - Positif
    // ==========================================
    test('TC04: submitTransfer success changes isSuccess to true', () async {
      // Setup (arrange, build)
      // PERBAIKAN: Mengembalikan Map kosong <String, dynamic>{} agar tidak bentrok dengan tipe data
      when(() => mockRepository.submitPayment(any())).thenAnswer((_) async => <String, dynamic>{});
      
      controller.periodeMulai = 'Januari 2024';
      controller.periodeAkhir = 'Januari 2024';
      controller.hitungTotal(); // Trigger nilai ke 20.000
      controller.setBank('BCA');
      
      // Exercise (act, operate)
      final futureResult = controller.submitTransfer(anggotaId: '123');
      expect(controller.isLoading, true, reason: 'Status harus loading saat awal diklik');
      
      await futureResult;
      
      // Verify (assert, check)
      expect(controller.isLoading, false);
      expect(controller.isSuccess, true, reason: 'isSuccess harus true jika API merespon sukses');
      expect(controller.errorMessage, isNull);
    });

    // ==========================================
    // TC05: submitTransfer() - Negatif
    // ==========================================
    test('TC05: submitTransfer failure sets errorMessage and isSuccess false', () async {
      // Setup (arrange, build)
      when(() => mockRepository.submitPayment(any())).thenThrow(Exception('Gagal transfer uang'));
      
      // Exercise (act, operate)
      await controller.submitTransfer(anggotaId: '123');
      
      // Verify (assert, check)
      expect(controller.isLoading, false);
      expect(controller.isSuccess, false, reason: 'isSuccess harus tetap false jika terjadi error');
      expect(controller.errorMessage, contains('Gagal transfer uang'));
    });

  });
}