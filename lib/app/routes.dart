import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import Views & Screens
import 'package:persis_app/features/auth/login_screen.dart';
import 'package:persis_app/features/auth/splash_screen.dart'; // Import SplashScreen baru
import 'package:persis_app/features/profile/profile_screen.dart';
import 'package:persis_app/features/anggota/presentation/view/anggota_view.dart';
import 'package:persis_app/features/BendaharaPC/presentation/view/pc_view.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/pj_view.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/non-tunai/pj_verif_non_tunai_view.dart';

// Import Controllers & Data Sources
import 'package:persis_app/features/auth/login_controller.dart';
import 'package:persis_app/features/anggota/presentation/controller/anggota_controller.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/anggota/data/repositories/anggota_repository.dart';
import 'package:persis_app/features/BendaharaPC/presentation/view/pc_verifikasi_view.dart';

// Import Core & Config
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/widgets/offline_warning_banner.dart';

class AppRoutes {
  // Nama-nama jalan (Route Names)
  static const String initial = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String testBases = '/test-bases';
  static const String bendaharaPC = '/bendahara-pc';
  static const String bendaharaPJ = '/bendahara-pj';
  static const String verifikasiPC = '/verifikasi-pc';
  static const String anggota = '/anggota';
  static const String profile = '/profile';
  static const String verifikasiNonTunai = '/verifikasi-non-tunai';
  static final String _baseUrl = AppConfig.baseUrl;

  static Map<String, WidgetBuilder> get routes {
    return {
      // 1. Gerbang Utama: SplashScreen (Cek Auto-Login)
      initial: (_) => const SplashScreen(),

      // 2. Halaman Login
      login: (_) => ChangeNotifierProvider(
        create: (_) =>
            LoginController(remoteDataSource: UserRemoteDataSource(_baseUrl)),
        child: const LoginScreen(),
      ),

      // 3. Dashboard Default/Admin
      dashboard: (_) => const DashboardPage(),

      // 4. Role Bendahara PC
      bendaharaPC: (_) => const PcViewPage(),

      // 5. Role Bendahara PJ
      bendaharaPJ: (_) => const PjViewPage(),

      // 6. Verifikasi Non-Tunai (Fitur Bendahara)
      verifikasiNonTunai: (_) => const PjVerifNonTunaiViewPage(),

      // 7. Role Anggota (InfaQu)
      anggota: (_) => ChangeNotifierProvider(
        create: (_) => AnggotaController(
          repository: AnggotaRepository(UserRemoteDataSource(_baseUrl)),
        ),
        child: const AnggotaView(),
      ),

      // 8. Halaman Profile (Untuk Semua Role)
      profile: (_) => const ProfileScreen(),

      // 9. Halaman Testing
      testBases: (_) => const TestBasesPage(),
      verifikasiPC: (_) => const PcVerifikasiPage(),

      // INI YANG FIX (UserRemoteDataSource dimasukin ke AnggotaRepository)
      anggota: (_) => ChangeNotifierProvider(
        create: (_) => AnggotaController(
          repository: AnggotaRepository(UserRemoteDataSource(_baseUrl)),
        ),
        child: const AnggotaView(),
      ),
      verifikasiNonTunai: (_) => const PjVerifNonTunaiViewPage(),
    };
  }
}

// === WIDGET DUMMY DASHBOARD (Jika diperlukan) ===
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Utama'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.anggota),
                child: const Text('Buka Halaman Anggota'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.bendaharaPC),
                child: const Text('Buka Bendahara PC'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.bendaharaPJ),
                child: const Text('Buka Bendahara PJ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === WIDGET TESTING BASES ===
class TestBasesPage extends StatefulWidget {
  const TestBasesPage({super.key});
  @override
  State<TestBasesPage> createState() => _TestBasesPageState();
}

class _TestBasesPageState extends State<TestBasesPage> {
  bool showOfflineBanner = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Bases')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OfflineWarningBanner(isOffline: showOfflineBanner),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showOfflineBanner = !showOfflineBanner;
                      });
                    },
                    child: Text(
                      showOfflineBanner
                          ? 'Hide Offline Warning'
                          : 'Show Offline Warning',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
