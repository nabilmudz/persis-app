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

  // ─── EDIT PROFIL ────────────────────────────────────────────────────────────

  void _showEditBottomSheet() {
    final emailCtrl = TextEditingController(
      text: (_userData?['email'] ?? '').toString(),
    );
    final noHpCtrl = TextEditingController(
      text: (_userData?['no_hp'] ?? _userData?['phone'] ?? '').toString(),
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileSheet(
        formKey: formKey,
        emailCtrl: emailCtrl,
        noHpCtrl: noHpCtrl,
        onSave: () async {
          if (!formKey.currentState!.validate()) return;
          Navigator.pop(ctx); // tutup sheet dulu
          await _updateProfile(
            email: emailCtrl.text.trim(),
            noHp: noHpCtrl.text.trim(),
          );
        },
      ),
    );
  }

  Future<void> _updateProfile({
    required String email,
    required String noHp,
  }) async {
    setState(() => _isLoading = true);
    try {
      final userId = await AuthHelper.getUserId();
      final token = await AuthHelper.getAccessToken();

      if (userId == null || token == null) {
        _showSnackBar('Sesi tidak valid, silakan login ulang.', isError: true);
        return;
      }

      final response = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'email': email, 'no_hp': noHp}),
      );

      debugPrint('Update profile status: ${response.statusCode}');
      debugPrint('Update profile body: ${response.body}');

      if (response.statusCode == 200) {
        // Perbarui data lokal tanpa perlu fetch ulang
        setState(() {
          _userData = {
            ...?_userData,
            'email': email,
            'no_hp': noHp,
          };
        });
        _showSnackBar('Profil berhasil diperbarui!');
      } else {
        final body = jsonDecode(response.body);
        final msg = body['message'] ?? 'Gagal memperbarui profil.';
        _showSnackBar(msg, isError: true);
      }
    } catch (e) {
      debugPrint('Error update profil: $e');
      _showSnackBar('Terjadi kesalahan. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── LOGOUT ─────────────────────────────────────────────────────────────────

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

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isBendahara = _role.contains('BENDAHARA');
    final fullname =
        (_userData?['fullname'] ?? _userData?['name'] ?? 'Pengguna InfaQu')
            .toString();
    final npa = (_userData?['npa'] ?? '-').toString();
    final email = (_userData?['email'] ?? '-').toString();
    final noHp =
        (_userData?['no_hp'] ?? _userData?['phone'] ?? '-').toString();
    final cabang = _userData?['region_id'] is Map
        ? (_userData?['region_id']?['name'] ?? '-').toString()
        : '-';

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
        // ── Tombol Edit di AppBar ──────────────────────────────────────────
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _showEditBottomSheet,
              icon: const Icon(Icons.edit_outlined, size: 16, color: primaryGreen),
              label: const Text(
                'Edit',
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
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
                      _buildInfoRow(Icons.badge_outlined, 'NPA', npa,
                          isReadonly: true),
                      _buildDivider(),
                      _buildInfoRow(Icons.email_outlined, 'Email', email),
                      _buildDivider(),
                      _buildInfoRow(
                          Icons.phone_outlined, 'No. Telepon', noHp),
                      if (!isBendahara) ...[
                        _buildDivider(),
                        _buildInfoRow(
                          Icons.location_city_outlined,
                          'Cabang',
                          cabang,
                          isReadonly: true,
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

  // ─── HELPER WIDGETS ─────────────────────────────────────────────────────────

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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isReadonly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isReadonly ? const Color(0xFFF5F5F5) : lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isReadonly ? greyText : primaryGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style:
                          const TextStyle(fontSize: 11, color: greyText),
                    ),
                    if (isReadonly) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Tidak bisa diubah',
                          style:
                              TextStyle(fontSize: 9, color: greyText),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isReadonly ? greyText : darkText,
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

// ═══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET: Edit Profil
// ═══════════════════════════════════════════════════════════════════════════════

class _EditProfileSheet extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController noHpCtrl;
  final VoidCallback onSave;

  const _EditProfileSheet({
    required this.formKey,
    required this.emailCtrl,
    required this.noHpCtrl,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  bool _isSaving = false;

  Future<void> _handleSave() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    // onSave akan menutup sheet; set _isSaving false sebagai fallback
    try {
      widget.onSave();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Profil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    Text(
                      'Perbarui email dan nomor telepon Anda',
                      style: TextStyle(fontSize: 12, color: greyText),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Field: Email
            _buildLabel('Email'),
            const SizedBox(height: 6),
            TextFormField(
              controller: widget.emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14, color: darkText),
              decoration: _inputDecoration(
                hint: 'Masukkan email Anda',
                icon: Icons.email_outlined,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                if (!emailRegex.hasMatch(val.trim())) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Field: No. Telepon
            _buildLabel('No. Telepon'),
            const SizedBox(height: 6),
            TextFormField(
              controller: widget.noHpCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 14, color: darkText),
              decoration: _inputDecoration(
                hint: 'Masukkan nomor telepon Anda',
                icon: Icons.phone_outlined,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'No. telepon tidak boleh kosong';
                }
                if (val.trim().length < 9) {
                  return 'No. telepon minimal 9 digit';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // Tombol Simpan & Batal
            Row(
              children: [
                // Batal
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: greyText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Simpan
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      disabledBackgroundColor: primaryGreen.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_outlined,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Simpan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: greyText, fontSize: 13),
      prefixIcon: Icon(icon, color: greyText, size: 18),
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}