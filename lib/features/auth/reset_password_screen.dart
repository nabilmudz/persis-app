import 'package:flutter/material.dart';
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String identifier;
  const ResetPasswordScreen({super.key, required this.identifier});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  Future<void> _submit() async {
    if (_passController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password minimal 8 karakter!")));
      return;
    }
    if (_passController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password dan Konfirmasi tidak cocok!")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = UserRemoteDataSource(AppConfig.baseUrl);
      // Panggil API set-password
      await api.setPassword(widget.identifier, _passController.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password berhasil diubah! Silakan Login.")));
        // Kembali ke halaman Login
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Password Baru", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _passController, 
              obscureText: _obscurePass, 
              decoration: InputDecoration(
                labelText: "Password Baru", 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                )
              )
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController, 
              obscureText: _obscureConfirm, 
              decoration: InputDecoration(
                labelText: "Konfirmasi Password", 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                )
              )
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A7A4A), 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text("Simpan Password Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}