import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:persis_app/features/auth/presentation/view/login_screen.dart';
import 'package:persis_app/features/auth/presentation/view/splash_screen.dart';
import 'package:persis_app/features/profile/presentation/profile_screen.dart';
import 'package:persis_app/features/anggota/presentation/view/anggota_view.dart';
import 'package:persis_app/features/bendahara_pc/presentation/view/pc_view.dart';
import 'package:persis_app/features/bendahara_pj/presentation/view/pj_view.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/bendahara_pj/presentation/view/non_tunai/pj_verif_non_tunai_view.dart';
import 'package:persis_app/features/auth/presentation/controller/login_controller.dart';
import 'package:persis_app/features/anggota/presentation/controller/anggota_controller.dart';
import 'package:persis_app/features/anggota/data/repositories/anggota_repository.dart';
import 'package:persis_app/features/bendahara_pc/presentation/view/pc_verifikasi_view.dart';

import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/widgets/offline_warning_banner.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String testBases = '/test-bases';
  static const String bendaharaPC = '/bendahara-pc';
  static const String bendaharaPJ = '/bendahara-pj';
  static const String verifikasiPC = '/verifikasi-pc';
  static const String anggota = '/anggota';
  static const String profile = '/profile';
  static const String verifikasiNonTunai = '/verifikasi-non_tunai';
  static String get _baseUrl => AppConfig.baseUrl;

  static Map<String, WidgetBuilder> get routes {
    return {
      initial: (_) => const SplashScreen(),
      login: (_) => ChangeNotifierProvider(
        create: (_) =>
            LoginController(remoteDataSource: UserRemoteDataSource(_baseUrl)),
        child: const LoginScreen(),
      ),
      dashboard: (_) => const DashboardPage(),
      bendaharaPC: (_) => const PcViewPage(),
      bendaharaPJ: (_) => const PjViewPage(),
      verifikasiNonTunai: (_) => const PjVerifNonTunaiViewPage(),
      anggota: (_) => ChangeNotifierProvider(
        create: (_) => AnggotaController(
          repository: AnggotaRepository(UserRemoteDataSource(_baseUrl)),
        ),
        child: const AnggotaView(),
      ),
      profile: (_) => const ProfileScreen(),
      testBases: (_) => const TestBasesPage(),
      verifikasiPC: (_) => const PcVerifikasiPage(),
    };
  }
}

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
