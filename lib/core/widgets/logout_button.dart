import 'package:flutter/material.dart';
import 'package:persis_app/helpers/auth_helper.dart';
import 'package:persis_app/app/routes.dart';

/// Widget tombol logout yang bisa dipasang di mana saja.
/// Contoh pemakaian di AppBar:
///   actions: [const LogoutButton()],
///
/// Contoh pemakaian sebagai ListTile (untuk halaman profile):
///   LogoutButton(asListTile: true)
class LogoutButton extends StatelessWidget {
  final bool asListTile;
  const LogoutButton({super.key, this.asListTile = false});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Akun',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun ini?',
          style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Hapus session
    await AuthHelper.clearSession();

    if (!context.mounted) return;

    // Kembali ke login & hapus semua history
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.initial,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (asListTile) {
      return ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 20),
        ),
        title: Text('Keluar Akun',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade600)),
        onTap: () => _logout(context),
      );
    }

    // Default: icon button untuk AppBar
    return IconButton(
      icon: Icon(Icons.logout_rounded, color: Colors.red.shade400),
      tooltip: 'Keluar',
      onPressed: () => _logout(context),
    );
  }
}