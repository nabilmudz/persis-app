import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/theme/app_colors.dart';

final String _baseUrl = AppConfig.baseUrl;

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
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Aktivasi Akun',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
            const SizedBox(height: 8),
            const Text(
              'Buat password baru untuk akun InfaQu Anda.',
              style: TextStyle(fontSize: 13, color: greyText, height: 1.5),
            ),
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
              hint: 'Ulangi password',
              obscure: _obscureKonfirmasi,
              onToggle: () => setState(() => _obscureKonfirmasi = !_obscureKonfirmasi),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSelesai,
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
                    : const Text('Selesai',
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
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: greyText,
            size: 20,
          ),
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
        filled: true,
        fillColor: Colors.white,
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
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i < s ? colors[s - 1] : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (s > 0)
          Text(
            labels[s - 1],
            style: TextStyle(fontSize: 11, color: colors[s - 1], fontWeight: FontWeight.w600),
          ),
      ],
    );
  }

  Future<void> _handleSelesai() async {
    final pass = _passwordController.text.trim();
    final konfirmasi = _konfirmasiController.text.trim();

    if (pass.isEmpty || konfirmasi.isEmpty) {
      _snackbar('Password tidak boleh kosong', isError: true);
      return;
    }
    if (pass.length < 8) {
      _snackbar('Password minimal 8 karakter', isError: true);
      return;
    }
    if (pass != konfirmasi) {
      _snackbar('Password dan konfirmasi tidak sama', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/set-password'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'npa': widget.npa, 'password': pass}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final body = jsonDecode(response.body);
        _snackbar(body['message'] ?? 'Gagal menyimpan password', isError: true);
        return;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _snackbar('Tidak dapat terhubung ke server', isError: true);
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: lightGreen, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: primaryGreen, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Akun Berhasil Diaktivasi!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan login dengan NPA dan password yang baru kamu buat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: greyText, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Masuk Sekarang',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
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