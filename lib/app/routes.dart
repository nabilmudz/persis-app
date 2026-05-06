import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:persis_app/features/BendaharaPC/presentation/view/pc_view.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/non-tunai/pj_verif_non_tunai_view.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/pj_view.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/auth/login_controller.dart';
import 'package:persis_app/features/anggota/presentation/view/anggota_view.dart';
import 'package:persis_app/features/anggota/presentation/controller/anggota_controller.dart';
import 'package:persis_app/features/anggota/data/repositories/anggota_repository.dart';

import '../core/widgets/offline_warning_banner.dart';
import '../features/auth/login_screen.dart';
import '../core/config/config.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String testBases = '/test-bases';
  static const String bendaharaPC = '/bendahara-pc';
  static const String bendaharaPJ = '/bendahara-pj';
  static const String verifikasiPC = '/verifikasi-pc';
  static const String anggota = '/anggota';
  static const String _baseUrl = 'https://avert-casually-plating.ngrok-free.dev/api';
  static const String verifikasiNonTunai = '/verifikasi-non-tunai';

  static Map<String, WidgetBuilder> get routes {
    return {
      initial: (_) => ChangeNotifierProvider(
        create: (_) =>
            LoginController(remoteDataSource: UserRemoteDataSource(_baseUrl)),
        child: const LoginScreen(),
      ),
      login: (_) => ChangeNotifierProvider(
        create: (_) =>
            LoginController(remoteDataSource: UserRemoteDataSource(_baseUrl)),
        child: const LoginScreen(),
      ),
      dashboard: (_) => const DashboardPage(),
      testBases: (_) => const TestBasesPage(),
      bendaharaPC: (_) => const PcViewPage(),
      bendaharaPJ: (_) => const PjViewPage(),
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

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Utama')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.anggota),
                child: const Text('Buka Halaman Anggota (PersisPay)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.testBases),
                child: const Text('Buka Test Bases'),
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
                child: const Text('Buka Bendahara PJ (Teman)'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                child: const Text('Keluar / Ke Login Screen'),
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
