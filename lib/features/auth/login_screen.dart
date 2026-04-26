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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

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

  // ─── Left Illustration Panel ───────────────────────────────────────────────

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
                  // Ganti dengan: Image.asset('assets/images/persis_illustration.png')
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
                    'Pembayaran dan rekapitulasi iuran anggota. '
                    'Pantau aliran dana dengan akurat dan terpercaya.',
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

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // ─── Login Form Panel ──────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Logo
          // Ganti dengan: Image.asset('assets/images/logo.png', width: 64)
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

          // Tab bar
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

          // Tab content
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [_buildMasukTab(), _buildAktivasiTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab: Masuk ────────────────────────────────────────────────────────────

  Widget _buildMasukTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('Email/NPA'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          hint: 'Masukkan Email/NPA',
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
              onPressed: () {
                // TODO: navigate to forgot password
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

        // Tombol Masuk
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
        const SizedBox(height: 16),

        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: inputBorder, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'atau',
                style: TextStyle(color: greyText, fontSize: 13),
              ),
            ),
            Expanded(child: Divider(color: inputBorder, thickness: 1)),
          ],
        ),
        const SizedBox(height: 16),

        // Google
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Google sign in
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: inputBorder, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            foregroundColor: darkText,
          ),
          icon: const Icon(
            Icons.g_mobiledata_rounded,
            color: Color(0xFF4285F4),
            size: 24,
          ),
          label: const Text(
            'Masuk dengan Google',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ─── Tab: Aktivasi Akun ────────────────────────────────────────────────────

  Widget _buildAktivasiTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Masukkan Nomor Pokok Anggota (NPA) Anda. Sistem akan '
          'memvalidasi data ke database eksternal pusat.',
          style: TextStyle(fontSize: 13, color: greyText, height: 1.5),
        ),
        const SizedBox(height: 20),
        _buildLabel('NPA'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _npaController,
          hint: 'Masukkan NPA',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            // TODO: validasi NPA & navigasi ke OTP
          },
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

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
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
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email/NPA dan Password tidak boleh kosong'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // TODO: hubungkan ke API / auth service
    // Setelah login sukses, navigasi ke dashboard:
    Navigator.pushReplacementNamed(context, '/dashboard');
  }
}
