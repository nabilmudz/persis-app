import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:persis_app/core/config/config.dart';

const Color primaryGreen = Color(0xFF1A7A4A);
const Color greyText = Color(0xFF9E9E9E);
const Color darkText = Color(0xFF1C1C1C);
const Color inputBorder = Color(0xFFE0E0E0);

// ==========================================
// SCREEN 1: INPUT EMAIL / NPA
// ==========================================
class LupaPasswordScreen extends StatefulWidget {
  const LupaPasswordScreen({super.key});
  @override
  State<LupaPasswordScreen> createState() => _LupaPasswordScreenState();
}

class _LupaPasswordScreenState extends State<LupaPasswordScreen> {
  final _inputController = TextEditingController();
  bool _isLoading = false;

  Future<void> _kirimOtp() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email/NPA tidak boleh kosong'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/forgot-password'),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({'identifier': input}),
      );

      setState(() => _isLoading = false);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => LupaPasswordOtpScreen(identifier: input)));
      } else {
        final msg = jsonDecode(response.body)['message'] ?? 'Pengguna tidak ditemukan';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal terhubung ke server'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lupa Password', style: TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: darkText, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reset Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
            const SizedBox(height: 8),
            const Text('Masukkan Email atau NPA untuk menerima kode OTP reset password.', style: TextStyle(color: greyText, height: 1.5)),
            const SizedBox(height: 24),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'Email / NPA',
                prefixIcon: const Icon(Icons.person_outline, color: greyText),
                filled: true, fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: inputBorder, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isLoading ? null : _kirimOtp,
                child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Kirim OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 2: VERIFIKASI OTP
// ==========================================
class LupaPasswordOtpScreen extends StatefulWidget {
  final String identifier;
  const LupaPasswordOtpScreen({super.key, required this.identifier});
  @override
  State<LupaPasswordOtpScreen> createState() => _LupaPasswordOtpScreenState();
}

class _LupaPasswordOtpScreenState extends State<LupaPasswordOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifikasiOtp() async {
    if (_otpController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/verify-reset-otp'),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({'identifier': widget.identifier, 'otp': _otpController.text}),
      );

      setState(() => _isLoading = false);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(identifier: widget.identifier, otp: _otpController.text)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Salah atau Kadaluarsa'), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal terhubung ke server'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verifikasi OTP', style: TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: darkText, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan Kode OTP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
            const SizedBox(height: 8),
            Text('Kode OTP telah dikirimkan ke ${widget.identifier}', style: const TextStyle(color: greyText, height: 1.5)),
            const SizedBox(height: 24),
            TextField(
              controller: _otpController, 
              keyboardType: TextInputType.number, 
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Kode OTP',
                prefixIcon: const Icon(Icons.security, color: greyText),
                filled: true, fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: inputBorder, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
              )
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, 
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                onPressed: _isLoading ? null : _verifikasiOtp, 
                child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Verifikasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))
              )
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 3: BUAT PASSWORD BARU
// ==========================================
class ResetPasswordScreen extends StatefulWidget {
  final String identifier, otp;
  const ResetPasswordScreen({super.key, required this.identifier, required this.otp});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  Future<void> _resetPassword() async {
    if (_passController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password dan Konfirmasi tidak cocok!'), backgroundColor: Colors.red));
      return;
    }
    if (_passController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 8 karakter!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/reset-password'),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({'identifier': widget.identifier, 'otp': widget.otp, 'new_password': _passController.text}),
      );
      
      setState(() => _isLoading = false);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah! Silakan Login'), backgroundColor: primaryGreen));
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan password baru'), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal terhubung ke server'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Password Baru', style: TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: darkText, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buat Password Baru', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
            const SizedBox(height: 24),
            _buildPasswordField(_passController, 'Password Baru', _obscurePass, () => setState(() => _obscurePass = !_obscurePass)),
            const SizedBox(height: 16),
            _buildPasswordField(_confirmController, 'Konfirmasi Password', _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, 
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                onPressed: _isLoading ? null : _resetPassword, 
                child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint, bool isObscure, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, color: greyText),
        suffixIcon: IconButton(icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: greyText), onPressed: onToggle),
        filled: true, fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: inputBorder, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
      ),
    );
  }
}