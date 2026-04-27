import 'package:flutter/material.dart';

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

  static const Color primaryGreen = Color(0xFF1A7A4A);
  static const Color lightGreen = Color(0xFFE8F5EE);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color darkText = Color(0xFF1C1C1C);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color inputBorder = Color(0xFFE0E0E0);

  // ─── Dummy Accounts ────────────────────────────────────────────────────────
  static const Map<String, String> _dummyAccounts = {
    'admin@persis.id': 'admin123',
    'nashwa@persis.id': 'nashwa123',
    '26150400': 'anggota123',
    '26150401': 'anggota456',
    '26150402': 'anggota789',
  };

  static const List<String> _validNpa = [
    '26150400',
    '26150401',
    '26150402',
    '26150403',
    '26150404',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            child: _circle(200, primaryGreen.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 80,
            right: -40,
            child: _circle(160, primaryGreen.withOpacity(0.06)),
          ),
          Positioned(
            top: 120,
            right: 20,
            child: _circle(80, accentGreen.withOpacity(0.15)),
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
                      color: Colors.white.withOpacity(0.5),
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
                      fontSize: 14,
                      color: greyText,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Mulai Sekarang',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
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
            child: const Icon(
              Icons.shield_rounded,
              color: primaryGreen,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'PersisPay',
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
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: darkText,
              unselectedLabelColor: greyText,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Masuk'),
                Tab(text: 'Aktivasi Akun'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [_buildMasukTab(), _buildAktivasiTab()],
            ),
          ),
          const SizedBox(height: 24),
          // Info dummy account
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryGreen.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.info_outline_rounded,
                      color: primaryGreen,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Akun Demo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _demoRow('Email', 'admin@persis.id', 'admin123'),
                _demoRow('Email', 'nashwa@persis.id', 'nashwa123'),
                _demoRow('NPA', '26150400', 'anggota123'),
                _demoRow('NPA', '26150401', 'anggota456'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoRow(String type, String user, String pass) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: const TextStyle(
                fontSize: 10,
                color: primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$user  •  $pass',
            style: const TextStyle(fontSize: 12, color: darkText),
          ),
        ],
      ),
    );
  }

  Widget _buildMasukTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('Email / NPA'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          hint: 'Masukkan Email atau NPA',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 18),
        _buildLabel('Password'),
        const SizedBox(height: 8),
        _buildPasswordField(),
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
                    onChanged: (val) => setState(() => _rememberMe = val!),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ingat Saya',
                  style: TextStyle(fontSize: 13, color: greyText),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
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
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Masuk',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
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
        const SizedBox(height: 20),
        _buildLabel('NPA'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _npaController,
          hint: 'Masukkan NPA',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _handleAktivasi,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Daftar',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: darkText,
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: greyText, fontSize: 14),
        prefixIcon: Icon(icon, color: greyText, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: 14, color: darkText),
      decoration: InputDecoration(
        hintText: 'Minimal 8 Karakter',
        hintStyle: const TextStyle(color: greyText, fontSize: 14),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: greyText,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: greyText,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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

  void _handleLogin() {
    final input = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showSnackbar('Email/NPA dan Password tidak boleh kosong', isError: true);
      return;
    }

    final correctPassword = _dummyAccounts[input];
    if (correctPassword == null) {
      _showSnackbar('Akun tidak ditemukan', isError: true);
      return;
    }
    if (correctPassword != password) {
      _showSnackbar('Password salah', isError: true);
      return;
    }

    _showSnackbar('Login berhasil! Selamat datang 👋');
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    });
  }

  void _handleAktivasi() {
    final npa = _npaController.text.trim();
    if (npa.isEmpty) {
      _showSnackbar('NPA tidak boleh kosong', isError: true);
      return;
    }
    if (!_validNpa.contains(npa)) {
      _showSnackbar('NPA tidak ditemukan di database', isError: true);
      return;
    }
    _showSnackbar('NPA valid! Silakan lanjutkan aktivasi 🎉');
    // TODO: navigasi ke halaman OTP / set password
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
