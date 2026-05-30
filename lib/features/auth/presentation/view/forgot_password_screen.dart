import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/theme/app_colors.dart';

String get _baseUrl => AppConfig.baseUrl;

bool _isEmailIdentifier(String value) => value.contains('@');

Map<String, dynamic> _identifierPayload(String identifier) {
  final trimmed = identifier.trim();
  return _isEmailIdentifier(trimmed) ? {'email': trimmed} : {'npa': trimmed};
}

String? _readString(Map<String, dynamic> data, String key) {
  final text = data[key]?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialIdentifier;
  const ForgotPasswordScreen({super.key, this.initialIdentifier});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _inputController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: widget.initialIdentifier);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _kirimOtp() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      _snackbar('Email atau NPA tidak boleh kosong', isError: true);
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
        body: jsonEncode(_identifierPayload(input)),
      );

      setState(() => _isLoading = false);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final otpEmail = _readString(body, 'email') ?? input;
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ForgotPasswordOtpScreen(identifier: input, otpEmail: otpEmail),
          ),
        );
      } else {
        final msg = body['message'] ?? 'Pengguna tidak ditemukan';
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: darkText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lupa Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan Email atau NPA untuk menerima kode OTP reset password.',
              style: TextStyle(color: greyText, height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _inputController,
              style: const TextStyle(fontSize: 14, color: darkText),
              decoration: InputDecoration(
                hintText: 'Email atau NPA',
                hintStyle: const TextStyle(color: greyText, fontSize: 14),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: greyText,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _kirimOtp,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Kirim OTP',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
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

class ForgotPasswordOtpScreen extends StatefulWidget {
  final String identifier;
  final String otpEmail;
  const ForgotPasswordOtpScreen({
    super.key,
    required this.identifier,
    required this.otpEmail,
  });
  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final List<String> _otp = ['', '', '', ''];
  late String _otpEmail;
  int _resendSeconds = 30;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _otpEmail = widget.otpEmail;
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 30;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      var shouldContinue = false;
      setState(() {
        if (_resendSeconds > 1) {
          _resendSeconds--;
          shouldContinue = true;
        } else {
          _resendSeconds = 0;
          _canResend = true;
        }
      });
      return shouldContinue;
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: darkText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lupa Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Verifikasi OTP',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: greyText,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Masukkan kode OTP yang dikirimkan ke '),
                  TextSpan(
                    text: _otpEmail,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Container(
                  width: 64,
                  height: 64,
                  margin: EdgeInsets.only(right: i < 3 ? 16 : 0),
                  decoration: BoxDecoration(
                    color: _otp[i].isNotEmpty
                        ? lightGreen
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _otp[i].isNotEmpty ? primaryGreen : inputBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _otp[i],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: _canResend
                  ? TextButton(
                      onPressed: _handleResend,
                      child: const Text(
                        'Kirim Ulang',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Text(
                      'Tidak menerima kode? Kirim ulang dalam ${_resendSeconds}s',
                      style: const TextStyle(fontSize: 12, color: greyText),
                    ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_otpString.length == 4 && !_isVerifying)
                    ? _handleVerifikasi
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFBDBDBD),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verifikasi OTP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),

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
                        width: 80,
                        height: 56,
                        child: TextButton(
                          onPressed: _deleteDigit,
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(
                            Icons.backspace_outlined,
                            color: darkText,
                            size: 22,
                          ),
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

  Widget _numpadRow(List<String> digits) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: digits.map(_numpadButton).toList(),
  );

  Widget _numpadButton(String digit) => SizedBox(
    width: 80,
    height: 56,
    child: TextButton(
      onPressed: () => _inputDigit(digit),
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
      ),
    ),
  );

  Future<void> _handleVerifikasi() async {
    setState(() => _isVerifying = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          ..._identifierPayload(widget.identifier),
          'otp': _otpString,
        }),
      );

      setState(() => _isVerifying = false);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              identifier: widget.identifier,
              otp: _otpString,
            ),
          ),
        );
      } else {
        setState(() {
          for (int i = 0; i < 4; i++) {
            _otp[i] = '';
          }
        });
        final msg = body['message'] ?? 'Kode OTP salah. Silakan coba lagi.';
        _snackbar(msg, isError: true);
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        for (int i = 0; i < 4; i++) {
          _otp[i] = '';
        }
      });
      _snackbar('Tidak dapat terhubung ke server.', isError: true);
    }
  }

  Future<void> _handleResend() async {
    _startResendTimer();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/activate'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(_identifierPayload(widget.identifier)),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final email = _readString(body, 'email');
        if (email != null && mounted) {
          setState(() => _otpEmail = email);
        }
        _snackbar('Kode OTP telah dikirim ulang ke ${email ?? _otpEmail}');
      } else {
        _snackbar('Gagal kirim ulang OTP', isError: true);
      }
    } catch (_) {
      _snackbar('Gagal kirim ulang OTP', isError: true);
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

class ResetPasswordScreen extends StatefulWidget {
  final String identifier, otp;
  const ResetPasswordScreen({
    super.key,
    required this.identifier,
    required this.otp,
  });
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
        Uri.parse('$_baseUrl/users/set-password'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          ..._identifierPayload(widget.identifier),
          'password': _passController.text,
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: darkText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lupa Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Buat Password Baru',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Password baru harus minimal 8 karakter.',
              style: TextStyle(color: greyText, height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 32),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
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
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: greyText,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: greyText,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
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
