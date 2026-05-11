import 'package:flutter/material.dart';
import '../../helpers/auth_helper.dart'; // <-- Alamatnya udah aku ganti jadi pendek!

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _role = 'ANGGOTA'; // Default

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  // Ambil role dari memori
  Future<void> _loadRole() async {
    final role = await AuthHelper.getRole();
    setState(() {
      _role = role?.toUpperCase() ?? 'ANGGOTA';
    });
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin keluar dari akun ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              await AuthHelper.clearSession();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah dia Bendahara (PD, PC, atau PJ)
    bool isBendahara = _role.contains('BENDAHARA');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Profil Singkat
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFE8F5EE),
              child: Icon(Icons.person, size: 50, color: Color(0xFF1A7A4A)),
            ),
          ),
          const SizedBox(height: 30),

          // MENU KHUSUS ANGGOTA (Kalau bukan bendahara, munculin menu tambahan)
          if (!isBendahara) ...[
            _buildMenuItem(Icons.person_outline, "Informasi Pribadi", () {}),
            const Divider(),
          ],

          // MENU UNTUK SEMUA ROLE (Termasuk Bendahara)
          _buildMenuItem(Icons.lock_outline, "Keamanan & Privasi", () {}),
          const Divider(),

          // TOMBOL LOGOUT
          _buildMenuItem(Icons.logout, "Keluar", _handleLogout, isLogout: true),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : const Color(0xFF1A7A4A),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black,
          fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
