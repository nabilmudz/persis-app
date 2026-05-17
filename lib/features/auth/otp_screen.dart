import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/theme/app_colors.dart';
import 'buat_password_screen.dart';

final String _baseUrl = AppConfig.baseUrl;

class OtpScreen extends StatefulWidget {
  final String npa;
  final String email;
  const OtpScreen({super.key, required this.npa, required this.email});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<String> _otp = ['', '', '', ''];
  int _resendSeconds = 30;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
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
        backgroundColor: Colors.white,
        elevation: 0,
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
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: greyText, height: 1.5),
                children: [
                  const TextSpan(text: 'Masukkan kode OTP yang dikirimkan ke '),
                  TextSpan(
                    text: widget.email,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: darkText),
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
                    color: _otp[i].isNotEmpty ? lightGreen : const Color(0xFFF5F5F5),
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
                          fontSize: 24, fontWeight: FontWeight.bold, color: primaryGreen),
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
                      child: const Text('Kirim Ulang',
                          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
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
                onPressed: (_otpString.length == 4 && !_isVerifying) ? _handleVerifikasi : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFBDBDBD),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Verifikasi OTP',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
                                borderRadius: BorderRadius.circular(12)),
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
          child: Text(digit,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w500, color: darkText)),
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
        body: jsonEncode({'npa': widget.npa, 'otp': _otpString}),
      );

      setState(() => _isVerifying = false);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BuatPasswordScreen(npa: widget.npa)),
        );
      } else {
        setState(() {
          for (int i = 0; i < 4; i++) _otp[i] = '';
        });
        final msg = body['message'] ?? 'Kode OTP salah. Silakan coba lagi.';
        _snackbar(msg, isError: true);
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        for (int i = 0; i < 4; i++) _otp[i] = '';
      });
      _snackbar('Tidak dapat terhubung ke server.', isError: true);
    }
  }

  Future<void> _handleResend() async {
    _startResendTimer();
    try {
      await http.post(
        Uri.parse('$_baseUrl/users/activate'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'npa': widget.npa,
          'email': widget.email,
          'no_hp': '',
          'cabang': 1,
        }),
      );
      _snackbar('Kode OTP telah dikirim ulang ke ${widget.email}');
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