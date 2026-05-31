import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_verif_tunai_controller.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';

// --- MOCKING MODELS ---
class MockTransactionModel extends Mock implements TransactionModel {}
class MockTransactionItemModel extends Mock implements TransactionItemModel {}

void main() {
  late PjVerifTunaiController controller;


  
  // Member 1: Punya 1 tunggakan, 1 lunas, 1 pending.
  late MockTransactionItemModel itemUnpaid;
  late MockTransactionItemModel itemPaid;
  late MockTransactionItemModel itemPending;
  late MockTransactionModel txMember1;

  // Member 2: Punya 1 lunas (tidak punya tunggakan sama sekali)
  late MockTransactionItemModel itemPaidM2;
  late MockTransactionModel txMember2;

  setUp(() {
    itemUnpaid = MockTransactionItemModel();
    when(() => itemUnpaid.anggotaId).thenReturn('member1');
    when(() => itemUnpaid.periodId).thenReturn('2020-01');
    when(() => itemUnpaid.status).thenReturn('unpaid');
    when(() => itemUnpaid.amount).thenReturn(30000);
    when(() => itemUnpaid.duesPeriodId).thenReturn(null);

    itemPaid = MockTransactionItemModel();
    when(() => itemPaid.anggotaId).thenReturn('member1');
    when(() => itemPaid.periodId).thenReturn('2020-02');
    when(() => itemPaid.status).thenReturn('paid');
    when(() => itemPaid.amount).thenReturn(20000);
    when(() => itemPaid.duesPeriodId).thenReturn(null);

    itemPending = MockTransactionItemModel();
    when(() => itemPending.anggotaId).thenReturn('member1');
    when(() => itemPending.periodId).thenReturn('2050-12'); // Masa depan
    when(() => itemPending.status).thenReturn('pending');
    when(() => itemPending.amount).thenReturn(25000);
    when(() => itemPending.duesPeriodId).thenReturn(null);

    txMember1 = MockTransactionModel();
    when(() => txMember1.items).thenReturn([itemUnpaid, itemPaid, itemPending]);
    when(() => txMember1.status).thenReturn('pending');
    when(() => txMember1.createdAt).thenReturn(null);

    itemPaidM2 = MockTransactionItemModel();
    when(() => itemPaidM2.anggotaId).thenReturn('member2');
    when(() => itemPaidM2.periodId).thenReturn('2020-05');
    when(() => itemPaidM2.status).thenReturn('completed');
    when(() => itemPaidM2.amount).thenReturn(20000);
    when(() => itemPaidM2.duesPeriodId).thenReturn(null);

    txMember2 = MockTransactionModel();
    when(() => txMember2.items).thenReturn([itemPaidM2]);
    when(() => txMember2.status).thenReturn('completed');
    when(() => txMember2.createdAt).thenReturn(null);

    // Inisialisasi Controller
    controller = PjVerifTunaiController(transactions: [txMember1, txMember2]);
  });

  group('PjVerifTunaiController Unit Tests', () {
    
    // ==========================================
    // TC01: memberCardStatus() - Positif
    // ==========================================
    test('TC01: memberCardStatus returns tunggakan if any past period is unpaid', () {
      // Exercise (act, operate)
      final status = controller.memberCardStatus('member1');

      // Verify (assert, check)
      // Member 1 memiliki tunggakan di 2020-01
      expect(status, PjMonthStatus.tunggakan);
    });

    // ==========================================
    // TC02: memberCardStatus() - Positif
    // ==========================================
    test('TC02: memberCardStatus returns paid if no tunggakan and at least one paid', () {
      // Exercise (act, operate)
      final status = controller.memberCardStatus('member2');

      // Verify (assert, check)
      // Member 2 hanya punya transaksi paid
      expect(status, PjMonthStatus.paid);
    });

    // ==========================================
    // TC03: tunggakanCount & tunggakanNominal - Positif
    // ==========================================
    test('TC03: calculates correct tunggakan count and nominal', () {
      // Exercise (act, operate)
      final count = controller.tunggakanCountByMember('member1');
      final nominal = controller.tunggakanNominalByMember('member1');

      // Verify (assert, check)
      // Member 1 hanya punya 1 transaksi tunggakan seharga 30.000
      expect(count, 1);
      expect(nominal, 30000.0);
    });

    // ==========================================
    // TC04: getMonthStatus() - Positif
    // ==========================================
    test('TC04: getMonthStatus correctly resolves statuses', () {
      // Exercise (act, operate)
      final statusPaid = controller.getMonthStatus(anggotaId: 'member1', month: 2, year: 2020);
      final statusPending = controller.getMonthStatus(anggotaId: 'member1', month: 12, year: 2050);
      
      // Verify (assert, check)
      expect(statusPaid, PjMonthStatus.paid, reason: 'Bulan 2 2020 sudah dibayar');
      expect(statusPending, PjMonthStatus.pending, reason: 'Bulan 12 2050 belum waktunya');
    });

    // ==========================================
    // TC05: updateData() - Positif
    // ==========================================
    test('TC05: updateData refreshes transaction list and state', () {
      // Setup: Buat controller dengan list kosong
      final emptyController = PjVerifTunaiController(transactions: []);
      expect(emptyController.tunggakanCountByMember('member1'), 0);

      // Exercise: Update dengan data baru (txMember1 punya 1 tunggakan)
      emptyController.updateData(transactions: [txMember1]);

      // Verify
      expect(emptyController.tunggakanCountByMember('member1'), 1, reason: 'Data harus terupdate');
    });

  });
}