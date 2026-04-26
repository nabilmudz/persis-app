import 'package:flutter/material.dart';
import 'package:persis_app/features/BendaharaPC/presentation/view/pc_view.dart';
import 'package:persis_app/features/BendaharaPC/presentation/view/pc_verif_view.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/pj_view.dart';

import '../core/widgets/offline_warning_banner.dart';
import '../features/auth/login_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String testBases = '/test-bases';
  static const String bendaharaPC = '/bendahara-pc';
  static const String bendaharaPJ = '/bendahara-pj';
  static const String verifikasiPC = '/verifikasi-pc';

  static Map<String, WidgetBuilder> get routes {
    return {
      initial: (_) => const LoginScreen(), // langsung ke login screen
      login: (_) => const LoginScreen(),
      dashboard: (_) => const DashboardPage(),
      testBases: (_) => const TestBasesPage(),
      bendaharaPC: (_) => const PcViewPage(),
      bendaharaPJ: (_) => const PjViewPage(),
      verifikasiPC: (_) => const PcVerifikasiPage(),
    };
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Page')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This is the dashboard page.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              child: const Text('Go to Login'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.testBases),
              child: const Text('Open Test Bases'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.bendaharaPC),
              child: const Text('Open Bendahara PC'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Trigger testable bases below.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 24),
                    const Text(
                      'Other testable bases can be added here as buttons or widgets.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
