import '../core/storage/secure_storage_service.dart';

class AuthHelper {
  AuthHelper._();

  static Future<bool> isLoggedIn() async {
    final token = await SecureStorageService.read(
      SecureStorageService.accessTokenKey,
    );
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getRole() async {
    return SecureStorageService.read(SecureStorageService.roleKey);
  }

  static Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    String? role,
  }) async {
    await SecureStorageService.write(
      SecureStorageService.accessTokenKey,
      accessToken,
    );

    if (refreshToken != null) {
      await SecureStorageService.write(
        SecureStorageService.refreshTokenKey,
        refreshToken,
      );
    }

    if (role != null) {
      await SecureStorageService.write(SecureStorageService.roleKey, role);
    }
  }

  static Future<void> clearSession() async {
    await SecureStorageService.deleteAll();
  }
}
