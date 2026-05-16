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
    await Future.delayed(const Duration(seconds: 2));

    final bool loggedIn = await AuthHelper.isLoggedIn();
    final String? roleValue = await AuthHelper.getRole();

    if (!mounted) return;

    if (loggedIn) {
      final role = roleValue?.trim().toUpperCase() ?? '';

      if (role == 'BENDAHARA_PJ' || role.contains('PJ')) {
        Navigator.pushReplacementNamed(context, AppRoutes.bendaharaPJ);
      } else if (role == 'BENDAHARA_PC' || role.contains('PC')) {
        Navigator.pushReplacementNamed(context, AppRoutes.bendaharaPC);
      } else if (role == 'BENDAHARA_PD' || role.contains('PD')) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else if (role == 'ANGGOTA' || role.contains('ANGGOTA')) {
        Navigator.pushReplacementNamed(context, AppRoutes.anggota);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A7A4A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shield_rounded, size: 100, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'InfaQu',
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