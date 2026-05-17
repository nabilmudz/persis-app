import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/theme/app_colors.dart';
import 'package:persis_app/helpers/auth_helper.dart';
import 'package:persis_app/core/storage/secure_storage_service.dart';
import '../../app/routes.dart';
import 'isi_data_screen.dart';
import 'forgot_password_screen.dart';

final String _baseUrl = AppConfig.baseUrl;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _npaController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _npaNotFound = false;
  bool _isCheckingNpa = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedCredentials();
  }

  // ─── Load saved credentials jika rememberMe aktif ────────────────────────
  Future<void> _loadSavedCredentials() async {
    final savedEmail = await SecureStorageService.read('saved_email');
    final savedPassword = await SecureStorageService.read('saved_password');
    final savedRemember = await SecureStorageService.read('remember_me');

    if (savedRemember == 'true' &&
        savedEmail != null &&
        savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _npaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: Colors.white,
      body: isWide
          ? Row(
              children: [
                Expanded(flex: 4, child: _buildLeftPanel()),
                Expanded(flex: 5, child: _buildLoginForm()),
              ],
            )
          : _buildLoginForm(),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      color: lightGreen,
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -60,
            child: _circle(200, primaryGreen.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 80,
            right: -40,
            child: _circle(160, primaryGreen.withValues(alpha: 0.06)),
          ),
          Positioned(
            top: 120,
            right: 20,
            child: _circle(80, accentGreen.withValues(alpha: 0.15)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 100,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Aman & Terpercaya',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pembayaran dan rekapitulasi iuran anggota. Pantau aliran dana dengan akurat dan terpercaya.',
                    style: TextStyle(
                        fontSize: 14, color: greyText, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded,
                color: primaryGreen, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'InfaQu',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: darkText,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sistem Manajemen Iuran Terpusat',
            style: TextStyle(fontSize: 13, color: greyText),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: darkText,
              unselectedLabelColor: greyText,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Masuk'),
                Tab(text: 'Aktivasi Akun'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 340,
            child: TabBarView(
              controller: _tabController,
              children: [_buildMasukTab(), _buildAktivasiTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasukTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Email / NPA'),
        const SizedBox(height: 8),
        _textField(
          controller: _emailController,
          hint: 'Masukkan Email atau NPA',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 18),
        _label('Password'),
        const SizedBox(height: 8),
        _passwordField(
          controller: _passwordController,
          obscure: _obscurePassword,
          onToggle: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: inputBorder, width: 1.5),
                    onChanged: (v) => setState(() => _rememberMe = v!),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Ingat Saya',
                    style: TextStyle(fontSize: 13, color: greyText)),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Lupa password?',
                style: TextStyle(
                  fontSize: 13,
                  color: primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _isCheckingNpa
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Masuk',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildAktivasiTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Masukkan Nomor Pokok Anggota (NPA) Anda. Sistem akan memvalidasi data ke database eksternal pusat.',
          style: TextStyle(fontSize: 13, color: greyText, height: 1.5),
        ),
        const SizedBox(height: 16),
        _label('NPA'),
        const SizedBox(height: 8),
        _textField(
          controller: _npaController,
          hint: 'Masukkan NPA',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.text,
          onChanged: (_) => setState(() => _npaNotFound = false),
        ),
        if (_npaNotFound) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'NPA Tidak Terdaftar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'NPA tidak ditemukan di database. Silakan hubungi admin.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade500,
                      height: 1.4),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _hubungiAdmin,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.headset_mic_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Hubungi Admin',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
        ElevatedButton(
          onPressed: _isCheckingNpa ? null : _handleCekNpa,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _isCheckingNpa
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Daftar',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: darkText),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onChanged: onChanged,
      style: TextStyle(
          fontSize: 14, color: readOnly ? greyText : darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: greyText, fontSize: 14),
        prefixIcon: Icon(icon, color: greyText, size: 20),
        suffixIcon: readOnly
            ? const Icon(Icons.lock_outline_rounded,
                color: greyText, size: 16)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: readOnly ? const Color(0xFFEEEEEE) : inputBorder,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: readOnly ? const Color(0xFFEEEEEE) : primaryGreen,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF0F0F0) : Colors.white,
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    String hint = 'Masukkan password',
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: greyText, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: greyText, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: greyText,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Future<void> _handleLogin() async {
    final input = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _snackbar('Email dan Password tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _isCheckingNpa = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/login'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'email': input, 'password': password}),
      );

      setState(() => _isCheckingNpa = false);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final role = body['user']?['role'];
        final userId = body['user']?['_id']?.toString();
        final token = _extractString(body, const [
          'access_token',
          'accessToken',
          'token',
          'jwt',
        ]);
        final refreshToken = _extractString(body, const [
          'refresh_token',
          'refreshToken',
        ]);

        log('role: $role');
        log('userId: $userId');

        // Simpan atau hapus credentials berdasarkan rememberMe
        if (_rememberMe) {
          await SecureStorageService.write('saved_email', input);
          await SecureStorageService.write('saved_password', password);
          await SecureStorageService.write('remember_me', 'true');
        } else {
          await SecureStorageService.delete('saved_email');
          await SecureStorageService.delete('saved_password');
          await SecureStorageService.write('remember_me', 'false');
        }

        // Selalu simpan session token
        await AuthHelper.saveSession(
          accessToken: token ?? '',
          refreshToken: refreshToken,
          role: role?.toString(),
          userId: userId,
        );

        _snackbar('Login berhasil! Selamat datang 👋');

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            final route = _routeForRole(role?.toString());
            Navigator.pushReplacementNamed(context, route);
          }
        });
      } else {
        final msg = body['message'] ?? 'Email atau password salah';
        _snackbar(msg, isError: true);
      }
    } catch (e) {
      setState(() => _isCheckingNpa = false);
      _snackbar('Tidak dapat terhubung ke server', isError: true);
    }
  }

  String? _extractString(
      Map<String, dynamic> body, List<String> keys) {
    final data = body['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(body['data'])
        : body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : null;

    for (final key in keys) {
      final value = body[key] ?? data?[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String _routeForRole(String? roleValue) {
    final role = roleValue?.trim().toLowerCase() ?? '';
    if (role.contains('bendahara_pj') ||
        role.contains('bendaharapj') ||
        role == 'pj') {
      return AppRoutes.bendaharaPJ;
    }
    if (role.contains('bendahara_pc') ||
        role.contains('bendaharapc') ||
        role == 'pc') {
      return AppRoutes.bendaharaPC;
    }
    if (role.contains('bendahara_pd') ||
        role.contains('bendaharapd') ||
        role == 'pd') {
      return AppRoutes.dashboard;
    }
    if (role.contains('anggota') || role == 'anggota') {
      return AppRoutes.anggota;
    }
    return AppRoutes.dashboard;
  }

  Future<void> _handleCekNpa() async {
    final npa = _npaController.text.trim();
    if (npa.isEmpty) {
      _snackbar('NPA tidak boleh kosong', isError: true);
      return;
    }

    setState(() {
      _isCheckingNpa = true;
      _npaNotFound = false;
    });

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/users/check-npa/$npa'),
            headers: {'ngrok-skip-browser-warning': 'true'},
          )
          .timeout(const Duration(seconds: 8));

      setState(() => _isCheckingNpa = false);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => IsiDataScreen(npa: npa)),
        );
      } else {
        final msg = body['message'] ?? 'NPA tidak ditemukan';
        if (msg.toLowerCase().contains('sudah')) {
          _snackbar('NPA sudah aktif. Silakan login langsung.',
              isError: true);
          _tabController.animateTo(0);
        } else {
          setState(() => _npaNotFound = true);
        }
      }
    } catch (e) {
      setState(() => _isCheckingNpa = false);
      _snackbar('Tidak dapat terhubung ke server', isError: true);
    }
  }

  void _hubungiAdmin() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hubungi Admin',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _contactRow(
                Icons.email_outlined, 'Email', 'admin@persis.id'),
            const SizedBox(height: 12),
            _contactRow(Icons.phone_outlined, 'WhatsApp',
                '+62 812-3456-7890'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup',
                style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
              color: lightGreen, shape: BoxShape.circle),
          child: Icon(icon, color: primaryGreen, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: greyText)),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: darkText),
            ),
          ],
        ),
      ],
    );
  }

  void _snackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}