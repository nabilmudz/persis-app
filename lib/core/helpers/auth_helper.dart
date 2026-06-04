import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';

class AuthHelper {
  AuthHelper._();

  static Future<bool> isLoggedIn() async {
    final token = await SecureStorageService.read(
      SecureStorageService.accessTokenKey,
    );
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getRole() async {
    final role = await SecureStorageService.read(SecureStorageService.roleKey);
    return role;
  }

  static Future<String?> getUserId() async {
    final uid = await SecureStorageService.read('user_id');
    return uid;
  }

  static Future<String?> getAccessToken() async {
    final token = await SecureStorageService.read(
      SecureStorageService.accessTokenKey,
    );
    return token;
  }

  static Future<String?> getRegionId() async {
    final regionId = await SecureStorageService.read('region_id');
    return regionId;
  }

  static Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    String? role,
    String? userId,
    String? regionId,
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

    if (userId != null) {
      await SecureStorageService.write('user_id', userId);
    } else {
      debugPrint('User ID is null, cannot fetch history');
    }

    if (regionId != null) {
      await SecureStorageService.write('region_id', regionId);
    }
  }

  static Future<void> clearSession() async {
    final savedEmail = await SecureStorageService.read('saved_email');
    final savedPassword = await SecureStorageService.read('saved_password');
    final rememberMe = await SecureStorageService.read('remember_me');
    await SecureStorageService.deleteAll();

    if (rememberMe == 'true' && savedEmail != null && savedPassword != null) {
      await SecureStorageService.write('saved_email', savedEmail);
      await SecureStorageService.write('saved_password', savedPassword);
      await SecureStorageService.write('remember_me', 'true');
    }
  }
}
