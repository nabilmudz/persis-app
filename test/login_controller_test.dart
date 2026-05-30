import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/auth/login_controller.dart';
import 'package:persis_app/app/routes.dart';

class MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}

void main() {
  late LoginController controller;
  late MockUserRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockUserRemoteDataSource();
    controller = LoginController(remoteDataSource: mockRemoteDataSource);
  });

  group('LoginController - Login', () {
    test('Harus mengembalikan error jika email atau password kosong', () async {
      final result = await controller.login('', '');

      expect(result.success, false);
      expect(result.message, 'Email/NPA dan Password tidak boleh kosong');
      expect(controller.errorMessage, 'Email/NPA dan Password tidak boleh kosong');
      expect(result.nextRoute, AppRoutes.login);
    });

    test('Harus mengubah isLoading menjadi true saat proses login', () async {
      // Arrange
      when(() => mockRemoteDataSource.login('test@email.com', 'password123'))
          .thenAnswer((_) async => {
                'access_token': 'dummy_token',
                'role': 'ANGGOTA',
              });

      // Act & Assert
      final futureResult = controller.login('test@email.com', 'password123');
      expect(controller.isLoading, true); // cek loading saat proses berjalan
      
      await futureResult;
      expect(controller.isLoading, false); // loading false setelah selesai
    });
  });

  group('LoginController - Check NPA', () {
    test('Harus mengembalikan NpaStatus.empty jika NPA kosong', () async {
      final result = await controller.checkNpa('   ');

      expect(result.status, NpaStatus.empty);
      expect(result.message, 'NPA tidak boleh kosong');
    });

    test('Harus mengembalikan NpaStatus.valid jika NPA ditemukan', () async {
      when(() => mockRemoteDataSource.checkNpa('123456'))
          .thenAnswer((_) async => {'message': 'NPA Valid ditemukan'});

      final result = await controller.checkNpa('123456');

      expect(result.status, NpaStatus.valid);
      expect(controller.npaNotFound, false);
    });

    test('Harus mengubah npaNotFound menjadi true jika server melempar Exception', () async {
      when(() => mockRemoteDataSource.checkNpa('000000'))
          .thenThrow(Exception('NPA Tidak Ditemukan'));

      final result = await controller.checkNpa('000000');

      expect(result.status, NpaStatus.notFound);
      expect(controller.npaNotFound, true);
    });
  });
}