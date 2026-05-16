import 'package:flutter/material.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import 'package:persis_app/helpers/auth_helper.dart';
import 'package:persis_app/app/routes.dart';

// ─── Result Models ────────────────────────────────────────────────────────────

enum NpaStatus { valid, alreadyActive, notFound, empty, error }

class CekNpaResult {
  final NpaStatus status;
  final String? message;
  const CekNpaResult({required this.status, this.message});
}

class LoginResult {
  final bool success;
  final String message;
  final String nextRoute;
  const LoginResult({
    required this.success,
    required this.message,
    required this.nextRoute,
  });
}

// ─── Controller ───────────────────────────────────────────────────────────────

class LoginController extends ChangeNotifier {
  final UserRemoteDataSource remoteDataSource;
  LoginController({required this.remoteDataSource});

  bool _isLoading = false;
  bool _npaNotFound = false;
  String? _errorMessage;
  UserModel? _user;

  bool get isLoading => _isLoading;
  bool get npaNotFound => _npaNotFound;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<LoginResult> login(
    String emailOrNpa,
    String password, {
    bool rememberMe = false,
  }) async {
    final identifier = emailOrNpa.trim();
    final pwd = password.trim();

    if (identifier.isEmpty || pwd.isEmpty) {
      const msg = 'Email/NPA dan Password tidak boleh kosong';
      _errorMessage = msg;
      notifyListeners();
      return const LoginResult(
        success: false,
        message: msg,
        nextRoute: AppRoutes.login,
      );
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await remoteDataSource.login(identifier, pwd);

      // ── Parse user map ───────────────────────────────────────────────────
      Map<String, dynamic>? dataMap;
      try {
        dataMap = response['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(response['data'])
            : Map<String, dynamic>.from(response);
      } catch (_) {
        dataMap = null;
      }

      Map<String, dynamic>? userMap;
      if (response['user'] is Map<String, dynamic>) {
        userMap = Map.from(response['user']);
      }
      userMap ??= dataMap?['user'] is Map<String, dynamic>
          ? Map.from(dataMap!['user'])
          : null;
      userMap ??= dataMap;

      UserModel? parsedUser;
      try {
        if (userMap != null) parsedUser = UserModel.fromJson(userMap);
      } catch (_) {}
      _user = parsedUser;

      // ── Parse token ──────────────────────────────────────────────────────
      String? token;
      for (final key in ['access_token', 'accessToken', 'token', 'jwt']) {
        final v = response[key] ?? dataMap?[key];
        if (v is String && v.trim().isNotEmpty) {
          token = v.trim();
          break;
        }
      }

      String? refreshToken;
      for (final key in ['refresh_token', 'refreshToken']) {
        final v = response[key] ?? dataMap?[key];
        if (v is String && v.trim().isNotEmpty) {
          refreshToken = v.trim();
          break;
        }
      }

      // ── Parse role ───────────────────────────────────────────────────────
      String? role = response['role'] is String ? response['role'] : null;
      role ??= dataMap?['role'] is String ? dataMap!['role'] : null;
      role ??= userMap?['role'] is String ? userMap!['role'] : null;
      role ??= parsedUser?.role;

      if (token != null) {
        await AuthHelper.saveSession(
          accessToken: token,
          refreshToken: refreshToken,
          role: role,
          userId: parsedUser?.id,
        );

      }

      final route = _routeForRole(role);
      final name =
          parsedUser?.fullname ??
          parsedUser?.email ??
          parsedUser?.npa ??
          'Pengguna';
      final rememberText = rememberMe ? ' (Ingat Saya aktif)' : '';

      return LoginResult(
        success: true,
        message: 'Login berhasil. Selamat datang, $name$rememberText',
        nextRoute: route,
      );
    } catch (e) {
      final raw = e.toString();
      final msg = raw.startsWith('Exception: ')
          ? raw.substring('Exception: '.length)
          : raw;
      _errorMessage = msg;
      return LoginResult(
        success: false,
        message: msg,
        nextRoute: AppRoutes.login,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CekNpaResult> checkNpa(String npa) async {
    final trimmed = npa.trim();

    if (trimmed.isEmpty) {
      return const CekNpaResult(
        status: NpaStatus.empty,
        message: 'NPA tidak boleh kosong',
      );
    }

    _isLoading = true;
    _npaNotFound = false;
    notifyListeners();

    try {
      final response = await remoteDataSource.checkNpa(trimmed);

      _isLoading = false;
      _npaNotFound = false;
      notifyListeners();

      return CekNpaResult(
        status: NpaStatus.valid,
        message: response['message'] as String? ?? 'NPA ditemukan',
      );
    } on Exception catch (e) {
      _isLoading = false;
      final msg = e.toString().replaceFirst('Exception: ', '');

      if (msg.toLowerCase().contains('sudah')) {
        notifyListeners();
        return CekNpaResult(status: NpaStatus.alreadyActive, message: msg);
      }

      _npaNotFound = true;
      notifyListeners();
      return CekNpaResult(status: NpaStatus.notFound, message: msg);
    } catch (e) {
      _isLoading = false;
      _npaNotFound = true;
      notifyListeners();
      return const CekNpaResult(
        status: NpaStatus.error,
        message: 'Tidak dapat terhubung ke server',
      );
    }
  }

  void resetNpaNotFound() {
    _npaNotFound = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Role Routing (Disempurnakan) ──────────────────────────────────────────
  String _routeForRole(String? roleValue) {
    final role = roleValue?.trim().toUpperCase() ?? '';

    // Sesuai dengan nama role di Database Backend
    if (role == 'BENDAHARA_PJ') return AppRoutes.bendaharaPJ;
    if (role == 'BENDAHARA_PC') return AppRoutes.bendaharaPC;
    if (role == 'BENDAHARA_PD') return AppRoutes.dashboard;
    if (role == 'ANGGOTA') return AppRoutes.anggota;

    // Fallback keamanan
    final roleLower = role.toLowerCase();
    if (roleLower.contains('pj')) return AppRoutes.bendaharaPJ;
    if (roleLower.contains('pc')) return AppRoutes.bendaharaPC;
    if (roleLower.contains('pd')) return AppRoutes.dashboard;
    if (roleLower.contains('anggota')) return AppRoutes.anggota;

    return AppRoutes.dashboard;
  }
}
