import 'package:flutter/material.dart';
import 'package:persis_app/helpers/auth_helper.dart';
import 'package:persis_app/app/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Jeda 2 detik biar loading-nya estetik
    await Future.delayed(const Duration(seconds: 2));

    // Menggunakan SecureStorageService lewat AuthHelper milikmu
    final bool loggedIn = await AuthHelper.isLoggedIn();
    final String? roleValue = await AuthHelper.getRole();

    // Muncul di Debug Console VS Code untuk memantau status
    debugPrint("--- CEK AUTO LOGIN ---");
    debugPrint("Status: ${loggedIn ? 'Sudah Login' : 'Belum Login'}");
    debugPrint("Role Terdeteksi: $roleValue");
    debugPrint("-----------------------");

    if (!mounted) return;

    if (loggedIn) {
      final role = roleValue?.trim().toUpperCase() ?? '';
      
      // Logika Routing yang disamakan dengan LoginController (Role Mapping)
      if (role == 'BENDAHARA_PJ' || role.contains('PJ')) {
        Navigator.pushReplacementNamed(context, AppRoutes.bendaharaPJ);
      } else if (role == 'BENDAHARA_PC' || role.contains('PC')) {
        Navigator.pushReplacementNamed(context, AppRoutes.bendaharaPC);
      } else if (role == 'BENDAHARA_PD' || role.contains('PD')) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else if (role == 'ANGGOTA' || role.contains('ANGGOTA')) {
        Navigator.pushReplacementNamed(context, AppRoutes.anggota);
      } else {
        // Fallback jika role tidak spesifik namun token ada
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } else {
      // Belum ada sesi, arahkan ke Login
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Warna hijau identitas PersisPay
      backgroundColor: const Color(0xFF1A7A4A), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            // Gunakan logo shield sementara atau ganti ke Image.asset milikmu
            Icon(
              Icons.shield_rounded, 
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'PersisPay',
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}