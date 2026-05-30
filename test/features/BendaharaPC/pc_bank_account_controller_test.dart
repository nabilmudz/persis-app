import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:persis_app/features/BendaharaPC/data/datasources/bank_account_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPC/data/models/bank_account_model.dart';
import 'package:persis_app/features/BendaharaPC/presentation/controller/pc_bank_account_controller.dart';

class MockManualBankDataSource implements BankAccountRemoteDataSource {
  @override
  String get baseUrl => '';

  bool puraPuraError = false; 

  @override
  Future<List<BankAccountModel>> getAll() async {
    if (puraPuraError) throw Exception('Server sedang sibuk');
    return [
      BankAccountModel(id: '1', bankName: 'BSI', accountNumber: '123456', paymentMethodId: 'pm1')
    ];
  }

  @override
  Future<void> create(BankAccountModel bankAccount) async {
    if (puraPuraError) throw Exception('Gagal menambah rekening');
  }

  @override
  Future<void> delete(String id) async {
    if (puraPuraError) throw Exception('Gagal menghapus rekening');
  }

  @override
  Future<void> update(String id, BankAccountModel bankAccount) async {
    if (puraPuraError) throw Exception('Gagal update rekening');
  }

  @override
  Future<BankAccountModel> getOne(String id) async {
    throw UnimplementedError();
  }
}

void main() {
  late PcBankAccountController controller;
  late MockManualBankDataSource mockDataSource;
  
setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost');
  });

  setUp(() {
    mockDataSource = MockManualBankDataSource();
    controller = PcBankAccountController(dataSource: mockDataSource);
  });

  group('Skenario Bank Account Controller (Bendahara PC)', () {
    
    test('1. loadBankAccounts harus mengisi list bankAccounts jika berhasil', () async {
      await controller.loadBankAccounts();
      expect(controller.isLoading, false); 
      expect(controller.errorMessage, null); 
      expect(controller.bankAccounts.length, 1); 
    });

    test('2. loadBankAccounts harus mengisi errorMessage jika server error', () async {
      mockDataSource.puraPuraError = true; 
      await controller.loadBankAccounts();
      expect(controller.errorMessage, contains('Error loading bank accounts'));
    });

    test('3. addBankAccount harus mengembalikan TRUE jika berhasil', () async {
      final akunBaru = BankAccountModel(id: '2', bankName: 'BCA');
      final result = await controller.addBankAccount(akunBaru);
      expect(result, true); 
    });

    test('4. addBankAccount harus mengembalikan FALSE jika server error', () async {
      mockDataSource.puraPuraError = true;
      final akunBaru = BankAccountModel(id: '2', bankName: 'BCA');
      final result = await controller.addBankAccount(akunBaru);
      expect(result, false); 
    });

    test('5. deleteBankAccount harus mengembalikan TRUE jika berhasil', () async {
      final result = await controller.deleteBankAccount('1'); 
      expect(result, true);
    });
  });
}