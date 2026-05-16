import 'package:flutter/foundation.dart';
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
    final role = await SecureStorageService.read(SecureStorageService.roleKey);
    debugPrint('AuthHelper: Reading Role -> $role');
    return role;
  }

  static Future<String?> getUserId() async {
    final uid = await SecureStorageService.read('user_id');
    debugPrint('AuthHelper: Reading User ID -> $uid');
    return uid;
  }

  static Future<String?> getAccessToken() async {
    final token = await SecureStorageService.read(SecureStorageService.accessTokenKey);
    debugPrint('AuthHelper: Reading Access Token -> ${token != null ? "FOUND" : "NULL"}');
    return token;
  }


  static Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    String? role,
    String? userId,
  }) async {
    debugPrint('=== AUTH SESSION SAVING ===');
    debugPrint('Role: $role');
    debugPrint('User ID: $userId');
    debugPrint('Token: ${accessToken.substring(0, 10)}...');

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
    
    
  }

  static Future<void> clearSession() async {
    debugPrint('=== CLEARING AUTH SESSION ===');
    await SecureStorageService.deleteAll();
  }
}
