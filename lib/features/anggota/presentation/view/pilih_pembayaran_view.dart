import 'package:flutter/material.dart';
import 'package:persis_app/app/routes.dart';
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';
import 'package:provider/provider.dart';
import 'package:persis_app/features/anggota/data/datasources/payment_remote_datasource.dart';

import '../controller/pembayaran_controller.dart';
import 'transfer_bank_view.dart';
import 'qris_view.dart';

class PilihPembayaranView extends StatelessWidget {
  const PilihPembayaranView({super.key});

  String get _baseUrl => AppConfig.baseUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bayar Sekarang',
          style: TextStyle(
            color: Color(0xFF363636),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFD0D0D0), height: 1.0),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 31),
            child: Text(
              'Non-tunai',
              style: TextStyle(
                color: Color(0xFF074D2C),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Column(
              children: [
                _buildPaymentMethodCard(
                  title: 'Transfer Bank',
                  subtitle: 'BCA, Mandiri, BSI',
                  icon: Icons.account_balance,
                  iconColor: const Color(0xFF5D7FE8),
                  iconBg: const Color(0x335D7FE8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                          create: (_) => PembayaranController(
                            remoteDataSource: PaymentRemoteDataSource(_baseUrl),
                          ),
                          child: const TransferBankView(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildPaymentMethodCard(
                  title: 'QRIS',
                  subtitle: 'Scan via Gopay, OVO, Dana',
                  icon: Icons.qr_code_scanner,
                  iconColor: const Color(0xFFDE8D00),
                  iconBg: const Color(0x33E8DA5D),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                          create: (_) => PembayaranController(
                            remoteDataSource: PaymentRemoteDataSource(_baseUrl),
                          ),
                          child: const QrisView(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const RoleBottomNavigationBar(
        currentRoute: AppRoutes.anggota,
        homeRoute: AppRoutes.anggota,
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF494949),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF949494),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
