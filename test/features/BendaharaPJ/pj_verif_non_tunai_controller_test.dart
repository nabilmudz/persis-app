import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'package:persis_app/features/BendaharaPC/data/datasources/payment_method_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPC/data/models/payment_method_model.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_verif_non_tunai_controller.dart';
import 'package:persis_app/features/BendaharaPC/presentation/controller/pc_controller.dart';

// --- MOCKING DATASOURCES ---
class MockTransactionRemoteDataSource extends Mock implements TransactionRemoteDataSource {}
class MockPaymentMethodRemoteDataSource extends Mock implements PaymentMethodRemoteDataSource {}

void main() {
  late PjVerifNonTunaiController controller;
  late MockTransactionRemoteDataSource mockTxSource;
  late MockPaymentMethodRemoteDataSource mockMethodSource;

  setUpAll(() {
    // Mendaftarkan fallback (nilai asal) untuk updateTransaction
    registerFallbackValue(TransactionModel(id: 'dummy'));
  });

  setUp(() {
    mockTxSource = MockTransactionRemoteDataSource();
    mockMethodSource = MockPaymentMethodRemoteDataSource();

    controller = PjVerifNonTunaiController(
      transactionDataSource: mockTxSource,
      paymentMethodDataSource: mockMethodSource,
    );
  });

  // --- DATA DUMMY ---
  final metodeTunai = PaymentMethodModel(id: 'method_1', code: 'tunai');
  final metodeBCA = PaymentMethodModel(id: 'method_2', code: 'bca');

  final itemTx = TransactionItemModel(
    anggotaId: 'member1',
    description: 'Iuran Wajib Budi',
  );

  final txTunai = TransactionModel(
    id: 'tx_1',
    paymentMethodId: 'method_1', // Ini tunai
    status: 'pending',
    creatorId: 'Nabil',
    items: [itemTx],
  );

  final txNonTunaiPending = TransactionModel(
    id: 'tx_2',
    paymentMethodId: 'method_2', // Ini non-tunai
    status: 'pending',
    creatorId: 'Andi',
    items: [itemTx],
  );

  final txNonTunaiCompleted = TransactionModel(
    id: 'tx_3',
    paymentMethodId: 'method_2', // Ini non-tunai
    status: 'completed',
    creatorId: 'Budi',
    items: [itemTx],
  );

  group('PjVerifNonTunaiController Unit Tests', () {

    // ==========================================
    // TC01: loadInitialData() - Positif
    // ==========================================
    test('TC01: loadInitialData fetches and filters non-tunai transactions', () async {
      // Setup
      when(() => mockMethodSource.getAllPaymentMethods())
          .thenAnswer((_) async => [metodeTunai, metodeBCA]);
      // Mock kembalikan 1 tx tunai dan 2 tx non-tunai
      when(() => mockTxSource.getHistory())
          .thenAnswer((_) async => [txTunai, txNonTunaiPending, txNonTunaiCompleted]);

      // Exercise
      await controller.loadInitialData();

      // Verify
      expect(controller.transactions.length, 2, reason: 'Harus membuang transaksi tunai, hanya sisa 2');
      expect(controller.transactions.any((tx) => tx.id == 'tx_1'), isFalse, reason: 'tx_1 adalah tunai, tidak boleh masuk list');
      expect(controller.errorMessage, isNull);
    });

    // ==========================================
    // TC02: loadInitialData() - Negatif
    // ==========================================
    test('TC02: loadInitialData handles error properly', () async {
      // Setup
      when(() => mockMethodSource.getAllPaymentMethods())
          .thenThrow(Exception('Server Timeout'));

      // Exercise
      await controller.loadInitialData();

      // Verify
      expect(controller.transactions.isEmpty, isTrue);
      expect(controller.errorMessage, contains('Server Timeout'));
      expect(controller.isLoading, isFalse);
    });

    // ==========================================
    // TC03 & TC04: getFilteredItems() - Positif
    // ==========================================
    test('TC03 & TC04: getFilteredItems filters by category and query correctly', () async {
      // Pre-fill transaksi tanpa perlu panggil API
      when(() => mockMethodSource.getAllPaymentMethods()).thenAnswer((_) async => []);
      when(() => mockTxSource.getHistory()).thenAnswer((_) async => [txNonTunaiPending, txNonTunaiCompleted]);
      await controller.loadInitialData();

      // TC03: Filter 'Belum Diverifikasi'
      final unverifiedItems = controller.getFilteredItems(category: 'Belum Diverifikasi', query: '');
      expect(unverifiedItems.length, 1);
      expect(unverifiedItems.first.name, contains('Iuran'));

      // TC04: Filter query search 'Andi'
      final searchItems = controller.getFilteredItems(category: '', query: 'Andi');
      expect(searchItems.length, 1);
      expect(searchItems.first.idNumber, 'Andi');
    });

    // ==========================================
    // TC05: accTransaction() - Positif
    // ==========================================
    test('TC05: accTransaction successfully updates transaction', () async {
      // Setup
      when(() => mockTxSource.updateTransaction('tx_2', any()))
          .thenAnswer((_) async => true);
      // Agar loadInitialData (yang dipanggil setelah ACC sukses) tidak error
      when(() => mockMethodSource.getAllPaymentMethods()).thenAnswer((_) async => []);
      when(() => mockTxSource.getHistory()).thenAnswer((_) async => []);

      // Exercise
      final result = await controller.accTransaction(txNonTunaiPending);

      // Verify
      expect(result, PcAccResult.success);
      verify(() => mockTxSource.updateTransaction('tx_2', any())).called(1); // Pastikan fungsi update API terpanggil 1 kali
    });

    // ==========================================
    // TC06: accTransaction() - Negatif
    // ==========================================
    test('TC06: accTransaction returns notFound if transaction id is null', () async {
      // Setup
      final invalidTx = TransactionModel(id: null, items: []);

      // Exercise
      final result = await controller.accTransaction(invalidTx);

      // Verify
      expect(result, PcAccResult.notFound, reason: 'Jika id null, harus langsung return notFound tanpa panggil API');
    });

    // ==========================================
    // TC07: isVerified() - Positif
    // ==========================================
    test('TC07: isVerified returns true for completed/paid status', () {
      // Exercise & Verify
      expect(controller.isVerified(txNonTunaiCompleted), isTrue);
      expect(controller.isVerified(txNonTunaiPending), isFalse);
    });

  });
}