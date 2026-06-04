import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/helpers/auth_helper.dart';

class ProfileController extends ChangeNotifier {
  Map<String, dynamic>? userData;
  String cabang = '-';
  String role = 'ANGGOTA';
  bool isLoading = true;
  String? errorMessage;

  String get _baseUrl => AppConfig.baseUrl;

  Future<void> loadProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userId = await AuthHelper.getUserId();
      final token = await AuthHelper.getAccessToken();
      final storedRole = await AuthHelper.getRole();
      final storedRegionId = await AuthHelper.getRegionId();

      if (userId == null || token == null) {
        isLoading = false;
        errorMessage = 'Sesi tidak valid, silakan login ulang.';
        notifyListeners();
        return;
      }

      final userResponse = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (userResponse.statusCode == 200) {
        final body = jsonDecode(userResponse.body);
        userData = body['data'] ?? body['user'] ?? body;
        role =
            storedRole?.toUpperCase() ??
            userData?['role']?.toString().toUpperCase() ??
            'ANGGOTA';
      } else {
        isLoading = false;
        errorMessage = 'Gagal memuat data profil.';
        notifyListeners();
        return;
      }

      final regionId = _extractRegionId(storedRegionId);
      if (regionId != null && regionId.isNotEmpty) {
        await _fetchRegionName(regionId, token);
      } else {
        cabang = '-';
      }
    } catch (e) {
      debugPrint('Gagal memuat profil: $e');
      errorMessage = 'Tidak dapat terhubung ke server.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? _extractRegionId(String? storedRegionId) {
    if (userData == null) return storedRegionId;
    final regionId = userData!['region_id'] ?? userData!['regionId'];
    if (regionId is Map) {
      return (regionId['_id']?.toString() ?? regionId['id']?.toString());
    }
    if (regionId is String && regionId.isNotEmpty) return regionId;

    final region = userData!['region'];
    if (region is Map) {
      return (region['_id']?.toString() ?? region['id']?.toString());
    }
    if (region is String && region.isNotEmpty) return region;

    return storedRegionId;
  }

  Future<void> _fetchRegionName(String regionId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/regions/$regionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final regionData = body['data'] ?? body['region'] ?? body;
        final name =
            regionData['name']?.toString() ??
            regionData['region_name']?.toString() ??
            regionData['regionName']?.toString();
        if (name != null && name.isNotEmpty) {
          cabang = name;
          return;
        }
      }
    } catch (e) {
      debugPrint('Gagal fetch region: $e');
    }
    cabang = regionId;
  }

  Future<void> updateProfile({
    required String email,
    required String noHp,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final userId = await AuthHelper.getUserId();
      final token = await AuthHelper.getAccessToken();

      if (userId == null || token == null) {
        errorMessage = 'Sesi tidak valid, silakan login ulang.';
        isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.patch(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'email': email, 'no_hp': noHp}),
      );

      if (response.statusCode == 200) {
        userData = {...?userData, 'email': email, 'no_hp': noHp};
        errorMessage = null;
      } else {
        final body = jsonDecode(response.body);
        errorMessage = body['message'] ?? 'Gagal memperbarui profil.';
      }
    } catch (e) {
      debugPrint('Error update profil: $e');
      errorMessage = 'Terjadi kesalahan. Coba lagi.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
