import 'package:flutter/material.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import 'package:persis_app/helpers/auth_helper.dart';
import 'package:persis_app/app/routes.dart';

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

class LoginController extends ChangeNotifier {
  final UserRemoteDataSource remoteDataSource;

  LoginController({required this.remoteDataSource});

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  Future<LoginResult> login(
    String emailOrNpa,
    String password,
    BuildContext context, {
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

      // try parse user
      UserModel? parsedUser;
      try {
        final candidate = response['user'] ?? response['data'] ?? response;
        if (candidate is Map<String, dynamic>)
          parsedUser = UserModel.fromJson(candidate);
      } catch (_) {}

      _user = parsedUser;

      // extract token
      String? token;
      for (final key in ['access_token', 'accessToken', 'token', 'jwt']) {
        final v =
            response[key] ??
            (response['data'] is Map<String, dynamic>
                ? response['data'][key]
                : null);
        if (v is String && v.trim().isNotEmpty) {
          token = v.trim();
          break;
        }
      }

      String? refreshToken;
      for (final key in ['refresh_token', 'refreshToken']) {
        final v =
            response[key] ??
            (response['data'] is Map<String, dynamic>
                ? response['data'][key]
                : null);
        if (v is String && v.trim().isNotEmpty) {
          refreshToken = v.trim();
          break;
        }
      }

      // role fallback
      String? role = response['role'];
      if (role == null && parsedUser != null) role = parsedUser.role;

      if (token != null) {
        await AuthHelper.saveSession(
          accessToken: token,
          refreshToken: refreshToken,
          role: role,
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

  String _routeForRole(String? roleValue) {
    final role = roleValue?.trim().toLowerCase() ?? '';
    if (role.contains('bendahara_pj') ||
        role.contains('bendaharapj') ||
        role == 'pj')
      return AppRoutes.bendaharaPJ;
    if (role.contains('bendahara_pc') ||
        role.contains('bendaharapc') ||
        role == 'pc')
      return AppRoutes.bendaharaPC;
    if (role.contains('bendahara_pd') ||
        role.contains('bendaharapd') ||
        role == 'pd')
      return AppRoutes.dashboard;
    return AppRoutes.dashboard;
  }
}
