import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:persis_app/helpers/auth_helper.dart';
import 'package:persis_app/core/storage/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthHelper', () {
    setUp(() {
      // Clear up the mock storage before each test
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('isLoggedIn returns false when token is absent', () async {
      final isLoggedIn = await AuthHelper.isLoggedIn();
      expect(isLoggedIn, isFalse);
    });

    test('isLoggedIn returns true when token is present', () async {
      FlutterSecureStorage.setMockInitialValues({
        SecureStorageService.accessTokenKey: 'dummy_token',
      });
      final isLoggedIn = await AuthHelper.isLoggedIn();
      expect(isLoggedIn, isTrue);
    });

    test('getRole returns the correct role', () async {
      FlutterSecureStorage.setMockInitialValues({
        SecureStorageService.roleKey: 'ANGGOTA',
      });
      final role = await AuthHelper.getRole();
      expect(role, 'ANGGOTA');
    });

    test('getUserId returns the correct userId', () async {
      FlutterSecureStorage.setMockInitialValues({
        'user_id': '12345',
      });
      final userId = await AuthHelper.getUserId();
      expect(userId, '12345');
    });

    test('saveSession saves the correct data', () async {
      await AuthHelper.saveSession(
        accessToken: 'new_token_12345',
        refreshToken: 'refresh_token',
        role: 'ADMIN',
        userId: '987',
        regionId: 'reg_1',
      );

      final token = await AuthHelper.getAccessToken();
      final role = await AuthHelper.getRole();
      final userId = await AuthHelper.getUserId();
      final regionId = await AuthHelper.getRegionId();

      expect(token, 'new_token_12345');
      expect(role, 'ADMIN');
      expect(userId, '987');
      expect(regionId, 'reg_1');
    });

    test('clearSession removes all session data except remembered credentials', () async {
      // Arrange: mock initial values with session data and saved credentials
      FlutterSecureStorage.setMockInitialValues({
        SecureStorageService.accessTokenKey: 'some_token',
        'user_id': '123',
        'saved_email': 'test@example.com',
        'saved_password': 'password123',
        'remember_me': 'true',
      });

      // Act
      await AuthHelper.clearSession();

      // Assert: token and user_id should be cleared, credentials restored
      final token = await AuthHelper.getAccessToken();
      final userId = await AuthHelper.getUserId();

      // Fetching directly from SecureStorageService since AuthHelper doesn't have getSavedEmail
      final savedEmail = await SecureStorageService.read('saved_email');
      final savedPassword = await SecureStorageService.read('saved_password');
      final rememberMe = await SecureStorageService.read('remember_me');

      expect(token, isNull);
      expect(userId, isNull);
      expect(savedEmail, 'test@example.com');
      expect(savedPassword, 'password123');
      expect(rememberMe, 'true');
    });
  });
}
