import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/theme/app_colors.dart';
import 'otp_screen.dart';

final String _baseUrl = AppConfig.baseUrl;

class IsiDataScreen extends StatefulWidget {
  final String npa;
  const IsiDataScreen({super.key, required this.npa});
  @override
  State<IsiDataScreen> createState() => _IsiDataScreenState();
}

class _IsiDataScreenState extends State<IsiDataScreen> {
  final _emailController = TextEditingController();
  final _noTelpController = TextEditingController();
  bool _isLoading = false;

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
        backgroundColor: Colors.white,
        elevation: 0,
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
            _label('NPA'),
            const SizedBox(height: 8),
            _readonlyField(widget.npa, Icons.badge_outlined),
            const SizedBox(height: 16),
            _label('Email'),
            const SizedBox(height: 8),
            _inputField(
              controller: _emailController,
              hint: 'Masukkan email aktif',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _label('Nomor Telepon'),
            const SizedBox(height: 8),
            _inputField(
              controller: _noTelpController,
              hint: 'Contoh: 08123456789',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _label('Cabang'),
            const SizedBox(height: 8),
            _readonlyField('1', Icons.location_city_outlined),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleDaftar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Daftar',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText),
      );

  Widget _readonlyField(String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: greyText, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: greyText))),
          const Icon(Icons.lock_outline_rounded, color: greyText, size: 16),
        ],
      ),
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
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Future<void> _handleDaftar() async {
    final email = _emailController.text.trim();
    final noTelp = _noTelpController.text.trim();

    if (email.isEmpty || noTelp.isEmpty) {
      _snackbar('Email dan No Telepon wajib diisi', isError: true);
      return;
    }
    if (!email.contains('@')) {
      _snackbar('Format email tidak valid', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/activate'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'npa': widget.npa,
          'email': email,
          'no_hp': noTelp,
          'cabang': 1,
        }),
      );

      setState(() => _isLoading = false);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(npa: widget.npa, email: email),
          ),
        );
      } else {
        final msg = body['message'] ?? 'Terjadi kesalahan. Coba lagi.';
        _snackbar(msg, isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _snackbar('Tidak dapat terhubung ke server. Periksa koneksi internet.', isError: true);
    }
  }

  void _snackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}