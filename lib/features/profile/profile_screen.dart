import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/theme/app_colors.dart';
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
      final userId = await AuthHelper.getUserId();
      final token = await AuthHelper.getAccessToken();

      debugPrint('=== PROFILE DEBUG ===');
      debugPrint('userId: $userId');
      debugPrint('token: ${token != null ? "ADA" : "NULL"}');
      debugPrint('role: $role');

      if (userId == null || token == null) {
        debugPrint('userId atau token null, skip fetch');
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      debugPrint('Profile response status: ${response.statusCode}');
      debugPrint('Profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          _userData = body['data'] ?? body['user'] ?? body;
          _role =
              role?.toUpperCase() ??
              _userData?['role']?.toUpperCase() ??
              'ANGGOTA';
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat profil: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: primaryGreen)),
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
            child: const Text(
              'Keluar',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBendahara = _role.contains('BENDAHARA');
    final fullname = (_userData?['fullname'] ?? _userData?['name'] ?? 'Pengguna InfaQu').toString();
final npa = (_userData?['npa'] ?? '-').toString();
final email = (_userData?['email'] ?? '-').toString();
final noHp = (_userData?['no_hp'] ?? _userData?['phone'] ?? '-').toString();

// region_id adalah string ID, bukan object — jadi tidak bisa ambil ['name']
final cabang = _userData?['region_id'] is Map
    ? (_userData?['region_id']?['name'] ?? '-').toString()
    : '-'; // tampilkan - dulu, karena backend tidak populate region

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: darkText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : RefreshIndicator(
              color: primaryGreen,
              onRefresh: _loadProfileData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Avatar
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryGreen, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundColor: lightGreen,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nama
                  Center(
                    child: Text(
                      fullname,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Badge role
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _role,
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Informasi Pribadi
                  _buildSectionHeader('Informasi Pribadi'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    children: [
                      _buildInfoRow(Icons.badge_outlined, 'NPA', npa),
                      _buildDivider(),
                      _buildInfoRow(Icons.email_outlined, 'Email', email),
                      _buildDivider(),
                      _buildInfoRow(Icons.phone_outlined, 'No. Telepon', noHp),
                      if (!isBendahara) ...[
                        _buildDivider(),
                        _buildInfoRow(
                          Icons.location_city_outlined,
                          'Cabang',
                          cabang,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Menu Lainnya
                  _buildSectionHeader('Lainnya'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    children: [
                      _buildMenuItem(
                        Icons.privacy_tip_outlined,
                        'Kebijakan Privasi',
                        () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        Icons.logout,
                        'Keluar',
                        _handleLogout,
                        isLogout: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: greyText,
      letterSpacing: 0.5,
    ),
  );

  Widget _buildInfoCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _buildDivider() => const Divider(
    height: 1,
    thickness: 1,
    color: Color(0xFFF5F5F5),
    indent: 56,
  );

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryGreen, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: greyText),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isLogout ? const Color(0xFFFFF3F3) : lightGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isLogout ? Colors.red : primaryGreen,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isLogout ? Colors.red : darkText,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: greyText),
          ],
        ),
      ),
    );
  }
}
