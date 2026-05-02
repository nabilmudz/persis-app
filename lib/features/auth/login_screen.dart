import 'package:flutter/material.dart';

// ─── Dummy Data ────────────────────────────────────────────────────────────────
const Map<String, Map<String, String>> _npaDatabase = {
  '26150403': {'nama': 'Ahmad Fauzi', 'cabang': 'Bandung Timur'},
  '26150404': {'nama': 'Siti Rahma', 'cabang': 'Bandung Barat'},
  '26150405': {'nama': 'Rizky Maulana', 'cabang': 'Bandung Selatan'},
};

final Map<String, String> _activeAccounts = {
  'admin@persis.id': 'admin123',
  'nashwa@persis.id': 'nashwa123',
  '26150400': 'anggota123',
  '26150401': 'anggota456',
  '26150402': 'anggota789',
};

// ─── Colors ────────────────────────────────────────────────────────────────────
const Color primaryGreen = Color(0xFF1A7A4A);
const Color lightGreen = Color(0xFFE8F5EE);
const Color accentGreen = Color(0xFF2ECC71);
const Color darkText = Color(0xFF1C1C1C);
const Color greyText = Color(0xFF9E9E9E);
const Color inputBorder = Color(0xFFE0E0E0);
const Color inputFill = Color(0xFFF7F7F7);

// ══════════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════
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
          ? Row(children: [
              Expanded(flex: 4, child: _buildLeftPanel()),
              Expanded(flex: 5, child: _buildLoginForm()),
            ])
          : _buildLoginForm(),
    );
  }

  // ─── Left Panel ───────────────────────────────────────────────────────────
  Widget _buildLeftPanel() {
    return Container(
      color: lightGreen,
      child: Stack(children: [
        Positioned(top: -60, left: -60, child: _circle(200, primaryGreen.withOpacity(0.08))),
        Positioned(bottom: 80, right: -40, child: _circle(160, primaryGreen.withOpacity(0.06))),
        Positioned(top: 120, right: 20, child: _circle(80, accentGreen.withOpacity(0.15))),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity, height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.5),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      size: 100, color: primaryGreen),
                ),
                const SizedBox(height: 32),
                const Text('Aman & Terpercaya',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
                const SizedBox(height: 12),
                const Text(
                  'Pembayaran dan rekapitulasi iuran anggota. Pantau aliran dana dengan akurat dan terpercaya.',
                  style: TextStyle(fontSize: 14, color: greyText, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  // ─── Login Form ───────────────────────────────────────────────────────────
  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: lightGreen, shape: BoxShape.circle),
            child: const Icon(Icons.shield_rounded, color: primaryGreen, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('PersisPay',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                  color: darkText, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Sistem Manajemen Iuran Terpusat',
              style: TextStyle(fontSize: 13, color: greyText)),
          const SizedBox(height: 32),
          // Tab Bar
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: darkText,
              unselectedLabelColor: greyText,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: 'Masuk'), Tab(text: 'Aktivasi Akun')],
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

  // ─── Tab Masuk ────────────────────────────────────────────────────────────
  Widget _buildMasukTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Email / NPA'),
        const SizedBox(height: 8),
        _textField(controller: _emailController,
            hint: 'Masukkan Email atau NPA', icon: Icons.person_outline_rounded),
        const SizedBox(height: 18),
        _label('Password'),
        const SizedBox(height: 8),
        _passwordField(
          controller: _passwordController,
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              SizedBox(width: 20, height: 20,
                child: Checkbox(
                  value: _rememberMe, activeColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: const BorderSide(color: inputBorder, width: 1.5),
                  onChanged: (v) => setState(() => _rememberMe = v!),
                )),
              const SizedBox(width: 8),
              const Text('Ingat Saya', style: TextStyle(fontSize: 13, color: greyText)),
            ]),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(padding: EdgeInsets.zero,
                  minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Lupa password?',
                  style: TextStyle(fontSize: 13, color: primaryGreen, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Masuk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ─── Tab Aktivasi ─────────────────────────────────────────────────────────
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
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() => _npaNotFound = false),
        ),

        // Pesan error NPA tidak ditemukan
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
                Row(children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 6),
                  Text('NPA Tidak Terdaftar',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: Colors.red.shade600)),
                ]),
                const SizedBox(height: 6),
                Text('NPA tidak ditemukan di database. Silakan hubungi admin untuk informasi lebih lanjut.',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade500, height: 1.4)),
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
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Icon(Icons.headset_mic_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Hubungi Admin', style: TextStyle(fontSize: 13,
                          color: Colors.white, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),
        ElevatedButton(
          onPressed: _handleCekNpa,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Daftar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText));

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
      style: TextStyle(fontSize: 14, color: readOnly ? greyText : darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: greyText, fontSize: 14),
        prefixIcon: Icon(icon, color: greyText, size: 20),
        suffixIcon: readOnly
            ? const Icon(Icons.lock_outline_rounded, color: greyText, size: 16)
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: readOnly ? const Color(0xFFEEEEEE) : inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: readOnly ? const Color(0xFFEEEEEE) : primaryGreen, width: 1.5),
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
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: greyText, size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: greyText, size: 20),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        filled: true, fillColor: Colors.white,
      ),
    );
  }

  // ─── Logic ────────────────────────────────────────────────────────────────
  void _handleLogin() {
    final input = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (input.isEmpty || password.isEmpty) {
      _snackbar('Email/NPA dan Password tidak boleh kosong', isError: true);
      return;
    }
    if (_npaDatabase.containsKey(input)) {
      _snackbar('Akun belum diaktivasi. Silakan aktivasi dulu.', isError: true);
      _tabController.animateTo(1);
      return;
    }
    final correct = _activeAccounts[input];
    if (correct == null) { _snackbar('Akun tidak ditemukan', isError: true); return; }
    if (correct != password) { _snackbar('Password salah', isError: true); return; }
    _snackbar('Login berhasil! Selamat datang 👋');
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    });
  }

  void _handleCekNpa() {
    final npa = _npaController.text.trim();
    if (npa.isEmpty) { _snackbar('NPA tidak boleh kosong', isError: true); return; }
    if (_activeAccounts.containsKey(npa)) {
      _snackbar('NPA ini sudah aktif. Silakan login langsung.', isError: true);
      _tabController.animateTo(0);
      return;
    }
    if (_npaDatabase.containsKey(npa)) {
      final data = _npaDatabase[npa]!;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => IsiDataScreen(npa: npa, cabang: data['cabang']!),
      ));
      return;
    }
    setState(() => _npaNotFound = true);
  }

  void _hubungiAdmin() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hubungi Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _contactRow(Icons.email_outlined, 'Email', 'admin@persis.id'),
          const SizedBox(height: 12),
          _contactRow(Icons.phone_outlined, 'WhatsApp', '+62 812-3456-7890'),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(color: lightGreen, shape: BoxShape.circle),
        child: Icon(icon, color: primaryGreen, size: 18),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: greyText)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText)),
      ]),
    ]);
  }

  void _snackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ISI DATA SCREEN (Email, No Telp — NPA & Cabang readonly)
// ══════════════════════════════════════════════════════════════════════════════
class IsiDataScreen extends StatefulWidget {
  final String npa;
  final String cabang;
  const IsiDataScreen({super.key, required this.npa, required this.cabang});
  @override
  State<IsiDataScreen> createState() => _IsiDataScreenState();
}

class _IsiDataScreenState extends State<IsiDataScreen> {
  final _emailController = TextEditingController();
  final _noTelpController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _noTelpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Aktivasi Akun',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkText)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Nomor Pokok Anggota (NPA) Anda. Sistem akan memvalidasi data ke database eksternal pusat.',
              style: TextStyle(fontSize: 13, color: greyText, height: 1.5),
            ),
            const SizedBox(height: 24),

            // NPA (readonly)
            _label('NPA'),
            const SizedBox(height: 8),
            _readonlyField(widget.npa, Icons.badge_outlined),
            const SizedBox(height: 16),

            // Email
            _label('Email'),
            const SizedBox(height: 8),
            _inputField(
              controller: _emailController,
              hint: 'Masukkan email aktif',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // No Telp
            _label('Nomor Telepon'),
            const SizedBox(height: 8),
            _inputField(
              controller: _noTelpController,
              hint: 'Contoh: 08123456789',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Cabang (readonly)
            _label('Cabang'),
            const SizedBox(height: 8),
            _readonlyField(widget.cabang, Icons.location_city_outlined),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleDaftar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Daftar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText));

  Widget _readonlyField(String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
      ),
      child: Row(children: [
        Icon(icon, color: greyText, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: greyText))),
        const Icon(Icons.lock_outline_rounded, color: greyText, size: 16),
      ]),
    );
  }

  Widget _inputField({
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        filled: true, fillColor: Colors.white,
      ),
    );
  }

  void _handleDaftar() {
    final email = _emailController.text.trim();
    final noTelp = _noTelpController.text.trim();
    if (email.isEmpty || noTelp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Email dan No Telepon wajib diisi'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Format email tidak valid'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    // Navigasi ke OTP screen
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => OtpScreen(npa: widget.npa, email: email),
    ));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// OTP SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class OtpScreen extends StatefulWidget {
  final String npa;
  final String email;
  const OtpScreen({super.key, required this.npa, required this.email});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<String> _otp = ['', '', '', ''];
  // Kode OTP dummy (simulasi dikirim via email)
  static const String _dummyOtp = '1234';
  int _resendSeconds = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
        }
      });
      return _resendSeconds > 0;
    });
  }

  String get _otpString => _otp.join();

  void _inputDigit(String digit) {
    final idx = _otp.indexOf('');
    if (idx == -1) return;
    setState(() => _otp[idx] = digit);
  }

  void _deleteDigit() {
    for (int i = 3; i >= 0; i--) {
      if (_otp[i] != '') {
        setState(() => _otp[i] = '');
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Aktivasi Akun',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkText)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Aktivasi Akun',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
            const SizedBox(height: 8),
            RichText(text: TextSpan(
              style: const TextStyle(fontSize: 13, color: greyText, height: 1.5),
              children: [
                const TextSpan(text: 'Masukkan kode OTP yang dikirimkan ke '),
                TextSpan(text: widget.email,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: darkText)),
              ],
            )),
            const SizedBox(height: 8),
            // Hint untuk demo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: lightGreen, borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: primaryGreen, size: 14),
                const SizedBox(width: 6),
                Text('Demo: kode OTP adalah $_dummyOtp',
                    style: const TextStyle(fontSize: 12, color: primaryGreen, fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 32),

            // 4 kotak OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                width: 64, height: 64,
                margin: EdgeInsets.only(right: i < 3 ? 16 : 0),
                decoration: BoxDecoration(
                  color: _otp[i].isNotEmpty ? lightGreen : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _otp[i].isNotEmpty ? primaryGreen : inputBorder,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(_otp[i],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                          color: primaryGreen)),
                ),
              )),
            ),
            const SizedBox(height: 16),

            // Kirim ulang
            Center(
              child: _canResend
                  ? TextButton(
                      onPressed: () {
                        setState(() { _resendSeconds = 30; _canResend = false; });
                        _startResendTimer();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Kode OTP telah dikirim ulang'),
                          backgroundColor: primaryGreen,
                        ));
                      },
                      child: const Text('Kirim Ulang',
                          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
                    )
                  : Text('Tidak menerima kode? Kirim ulang dalam ${_resendSeconds}s',
                      style: const TextStyle(fontSize: 12, color: greyText)),
            ),
            const SizedBox(height: 24),

            // Tombol verifikasi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _otpString.length == 4 ? _handleVerifikasi : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen, foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFBDBDBD),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Verifikasi OTP',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),

            // Numpad custom
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _numpadRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _numpadRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _numpadRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 80),
                      _numpadButton('0'),
                      SizedBox(
                        width: 80, height: 56,
                        child: TextButton(
                          onPressed: _deleteDigit,
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Icon(Icons.backspace_outlined, color: darkText, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numpadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_numpadButton).toList(),
    );
  }

  Widget _numpadButton(String digit) {
    return SizedBox(
      width: 80, height: 56,
      child: TextButton(
        onPressed: () => _inputDigit(digit),
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(digit,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: darkText)),
      ),
    );
  }

  void _handleVerifikasi() {
    if (_otpString != _dummyOtp) {
      setState(() { for (int i = 0; i < 4; i++) _otp[i] = ''; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Kode OTP salah. Silakan coba lagi.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BuatPasswordScreen(npa: widget.npa),
    ));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BUAT PASSWORD SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class BuatPasswordScreen extends StatefulWidget {
  final String npa;
  const BuatPasswordScreen({super.key, required this.npa});
  @override
  State<BuatPasswordScreen> createState() => _BuatPasswordScreenState();
}

class _BuatPasswordScreenState extends State<BuatPasswordScreen> {
  final _passwordController = TextEditingController();
  final _konfirmasiController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Aktivasi Akun',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkText)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Aktivasi Akun',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
            const SizedBox(height: 8),
            const Text('Buat password baru untuk akun PersisPay Anda.',
                style: TextStyle(fontSize: 13, color: greyText, height: 1.5)),
            const SizedBox(height: 32),

            _label('Password'),
            const SizedBox(height: 8),
            _passwordField(
              controller: _passwordController,
              obscure: _obscurePassword,
              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            const SizedBox(height: 8),
            _strengthIndicator(),
            const SizedBox(height: 20),

            _label('Konfirmasi Password'),
            const SizedBox(height: 8),
            _passwordField(
              controller: _konfirmasiController,
              hint: 'Minimal 8 Karakter',
              obscure: _obscureKonfirmasi,
              onToggle: () => setState(() => _obscureKonfirmasi = !_obscureKonfirmasi),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSelesai,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Selesai',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText));

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    String hint = 'Minimal 8 Karakter',
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14, color: darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: greyText, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: greyText, size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: greyText, size: 20),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        filled: true, fillColor: Colors.white,
      ),
    );
  }

  Widget _strengthIndicator() {
    final pass = _passwordController.text;
    if (pass.isEmpty) return const SizedBox.shrink();
    int s = 0;
    if (pass.length >= 8) s++;
    if (pass.contains(RegExp(r'[A-Z]'))) s++;
    if (pass.contains(RegExp(r'[0-9]'))) s++;
    if (pass.contains(RegExp(r'[!@#\$&*~]'))) s++;
    final labels = ['Lemah', 'Cukup', 'Kuat', 'Sangat Kuat'];
    final colors = [Colors.red, Colors.orange, Colors.blue, primaryGreen];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: List.generate(4, (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: i < s ? colors[s - 1] : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ))),
        const SizedBox(height: 4),
        if (s > 0)
          Text(labels[s - 1],
              style: TextStyle(fontSize: 11, color: colors[s - 1], fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _handleSelesai() async {
    final pass = _passwordController.text.trim();
    final konfirmasi = _konfirmasiController.text.trim();
    if (pass.isEmpty || konfirmasi.isEmpty) {
      _snackbar('Password tidak boleh kosong', isError: true); return;
    }
    if (pass.length < 8) {
      _snackbar('Password minimal 8 karakter', isError: true); return;
    }
    if (pass != konfirmasi) {
      _snackbar('Password dan konfirmasi tidak sama', isError: true); return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    _activeAccounts[widget.npa] = pass;
    _npaDatabase.remove(widget.npa);
    setState(() => _isLoading = false);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: lightGreen, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: primaryGreen, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Akun Berhasil Diaktivasi!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkText)),
          const SizedBox(height: 8),
          const Text('Silakan login dengan NPA dan password yang baru kamu buat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: greyText, height: 1.5)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Masuk Sekarang',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  void _snackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }
}