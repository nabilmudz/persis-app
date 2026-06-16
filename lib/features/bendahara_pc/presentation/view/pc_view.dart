import 'package:flutter/material.dart';
import 'package:persis_app/app/routes.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';
import '../../../bendahara_pj/presentation/widgets/bendahara_shared_cards.dart';
import '../controller/pc_controller.dart';
import 'pc_laporan_view.dart';
import 'pc_riwayat_pembayaran_view.dart';
import 'pc_bank_account_view.dart';
import 'pc_verifikasi_non_tunai_view.dart';

class PcViewPage extends StatefulWidget {
  const PcViewPage({super.key});

  @override
  State<PcViewPage> createState() => _PcViewPageState();
}

class _PcViewPageState extends State<PcViewPage> {
  late final PcController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PcController();
    _controller.loadTransactions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Dashboard PC',
          style: TextStyle(
            color: Color(0xFF363636),
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              size: 30,
              color: Color(0xFF363636),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Datang\nBendahara PC',
              style: TextStyle(
                color: Color(0xFF073D4D),
                fontSize: 20,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            BendaharaSaldoCard(
              role: 'pc',
              badgeText: 'Porsi PC (20%)',
              title: 'Saldo Terkumpul ${DateTime.now().year}',
            ),
            const SizedBox(height: 24),

            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final pendingCount =
                    _controller.pendingNonTunaiTransactions.length;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.25,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PcRiwayatPembayaranViewPage(
                                  controller: _controller,
                                ),
                          ),
                        );
                      },
                      child: _buildMenuCard(
                        context,
                        'Riwayat Pembayaran',
                        Icons.history,
                        const Color(0xFFFFFBEA),
                        const Color(0xFFF57F17),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PcBankAccountPage(),
                          ),
                        );
                      },
                      child: _buildMenuCard(
                        context,
                        'Kelola Rekening',
                        Icons.account_balance,
                        const Color(0xFFE8F5E9),
                        const Color(0xFF0C844C),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PcLaporanViewPage(controller: _controller),
                          ),
                        );
                      },
                      child: _buildMenuCard(
                        context,
                        'Laporan Keuangan',
                        Icons.bar_chart,
                        const Color(0xFFE3F2FD),
                        const Color(0xFF1565C0),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PcVerifikasiNonTunaiView(
                                  controller: _controller,
                                ),
                          ),
                        );
                      },
                      child: _buildMenuCard(
                        context,
                        'Verifikasi Pembayaran',
                        Icons.verified_user,
                        const Color(0xFFFFF3E0),
                        const Color(0xFFE65100),
                        badge: pendingCount > 0
                            ? '$pendingCount'
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RoleBottomNavigationBar(
        currentRoute: AppRoutes.bendaharaPC,
        activeRoute: AppRoutes.bendaharaPC,
        homeRoute: AppRoutes.bendaharaPC,
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor, {
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF073D4D),
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
