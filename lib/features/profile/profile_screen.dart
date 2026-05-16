import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:persis_app/core/config/config.dart';
import '../../helpers/auth_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _role = 'ANGGOTA';
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final role = await AuthHelper.getRole();
      final token = ""; // Bypass sementara biar aplikasi bisa jalan

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          _userData = body['data'] ?? body['user'];
          _role = role?.toUpperCase() ?? _userData?['role']?.toUpperCase() ?? 'ANGGOTA';
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat profil: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin ingin keluar dari akun ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Color(0xFF1A7A4A))),
          ),
          TextButton(
            onPressed: () async {
              await AuthHelper.clearSession();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isBendahara = _role.contains('BENDAHARA');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A7A4A)))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A7A4A), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFE8F5EE),
                      child: Icon(Icons.person, size: 50, color: Color(0xFF1A7A4A)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _userData?['fullname'] ?? _userData?['name'] ?? 'Pengguna InfaQu',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C)),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5EE), borderRadius: BorderRadius.circular(20)),
                    child: Text(_role, style: const TextStyle(color: Color(0xFF1A7A4A), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),

                const Text("Informasi Pribadi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C))),
                const SizedBox(height: 16),
                
                _buildInfoRow(Icons.badge_outlined, "NPA", _userData?['npa'] ?? '-'),
                _buildInfoRow(Icons.email_outlined, "Email", _userData?['email'] ?? '-'),
                _buildInfoRow(Icons.phone_outlined, "No. Telepon", _userData?['no_hp'] ?? _userData?['phone'] ?? '-'),
                if (!isBendahara) _buildInfoRow(Icons.location_city_outlined, "Cabang", _userData?['cabang']?.toString() ?? '-'),
                
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
                const SizedBox(height: 12),

                _buildMenuItem(Icons.privacy_tip_outlined, "Kebijakan Privasi", () {}),
                _buildMenuItem(Icons.logout, "Keluar", _handleLogout, isLogout: true),
              ],
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1C))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isLogout ? const Color(0xFFFFF3F3) : const Color(0xFFE8F5EE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isLogout ? Colors.red : const Color(0xFF1A7A4A), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: isLogout ? Colors.red : const Color(0xFF1C1C1C), fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF9E9E9E)),
      onTap: onTap,
    );
  }
}