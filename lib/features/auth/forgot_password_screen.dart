import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/theme/app_colors.dart';

// ==========================================
// SCREEN 1: INPUT EMAIL / NPA
// ==========================================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _inputController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _kirimOtp() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      _snackbar('Email/NPA tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'identifier': input}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ForgotPasswordOtpScreen(identifier: input),
          ),
        );
      } else {
        final msg = jsonDecode(response.body)['message'] ?? 'Pengguna tidak ditemukan';
        _snackbar(msg, isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _snackbar('Gagal terhubung ke server', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Lupa Password',
          style: TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reset Password',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan Email atau NPA untuk menerima kode OTP reset password.',
              style: TextStyle(color: greyText, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'Email / NPA',
                hintStyle: const TextStyle(color: greyText, fontSize: 14),
                prefixIcon: const Icon(Icons.person_outline, color: greyText),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: inputBorder, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _kirimOtp,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Kirim OTP',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
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

// ==========================================
// SCREEN 2: VERIFIKASI OTP
// ==========================================
class ForgotPasswordOtpScreen extends StatefulWidget {
  final String identifier;
  const ForgotPasswordOtpScreen({super.key, required this.identifier});
  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifikasiOtp() async {
    if (_otpController.text.isEmpty) {
      _snackbar('Kode OTP tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/verify-reset-otp'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'identifier': widget.identifier,
          'otp': _otpController.text,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              identifier: widget.identifier,
              otp: _otpController.text,
            ),
          ),
        );
      } else {
        _snackbar('OTP salah atau kadaluarsa', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _snackbar('Gagal terhubung ke server', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Verifikasi OTP',
          style: TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Kode OTP',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText),
            ),
            const SizedBox(height: 8),
            Text(
              'Kode OTP telah dikirimkan ke ${widget.identifier}',
              style: const TextStyle(color: greyText, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Kode OTP',
                hintStyle: const TextStyle(color: greyText, fontSize: 14),
                prefixIcon: const Icon(Icons.security, color: greyText),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: inputBorder, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _verifikasiOtp,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Verifikasi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
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

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_passController.text != _confirmController.text) {
      _snackbar('Password dan konfirmasi tidak cocok', isError: true);
      return;
    }
    if (_passController.text.length < 8) {
      _snackbar('Password minimal 8 karakter', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'identifier': widget.identifier,
          'otp': widget.otp,
          'new_password': _passController.text,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        _snackbar('Password berhasil diubah! Silakan login');
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
        });
      } else {
        _snackbar('Gagal menyimpan password baru', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _snackbar('Gagal terhubung ke server', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Password Baru',
          style: TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buat Password Baru',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Password baru harus minimal 8 karakter.',
              style: TextStyle(color: greyText, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildPasswordField(
              _passController,
              'Password Baru',
              _obscurePass,
              () => setState(() => _obscurePass = !_obscurePass),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              _confirmController,
              'Konfirmasi Password',
              _obscureConfirm,
              () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Simpan Password',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String hint,
    bool isObscure,
    VoidCallback onToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(fontSize: 14, color: darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: greyText, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline, color: greyText),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: greyText,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
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