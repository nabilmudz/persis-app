import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/anggota_card.dart';
import '../controller/anggota_controller.dart';
import 'riwayat_view.dart';
import 'pilih_pembayaran_view.dart';

class AnggotaView extends StatefulWidget {
  const AnggotaView({Key? key}) : super(key: key);

  @override
  State<AnggotaView> createState() => _AnggotaViewState();
}

class _AnggotaViewState extends State<AnggotaView> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    // FIX: Wait for the widget to build before fetching data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    // Hardcode for UI testing
    final userId = '123';
    final userName = 'Nashwa';

    setState(() {
      _userName = userName;
    });

    if (userId.isNotEmpty) {
      if (mounted) {
        //context.read<AnggotaController>().fetchRiwayatTransaksi(userId: userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AnggotaController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B367)),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 220,
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF074D2C), Color(0xFF10B367)],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assalamualaikum,',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                              ),
                              Text(
                                _userName,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Color(0xFF074D2C), size: 30),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 140, left: 24, right: 24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tagihan Anda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                            const SizedBox(height: 4),
                            Text(
                              controller.totalTagihan > 0 ? 'Tunggakan Belum Dibayar' : 'Tidak ada tagihan',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF6A6A6A), fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              formatCurrency.format(controller.totalTagihan),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: controller.totalTagihan == 0
                                        ? [const Color(0xFFAAAAAA), const Color(0xFFCCCCCC)]
                                        : [const Color(0xFF074D2C), const Color(0xFF10B367)],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ElevatedButton(
                                  onPressed: controller.totalTagihan == 0
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (c) => ChangeNotifierProvider.value(
                                                value: context.read<AnggotaController>(),
                                                child: const PilihPembayaranView(), 
                                              ),
                                            ),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                  child: const Text('Bayar Sekarang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMenuIcon(
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFFDE8D00),
                      bgColor: const Color(0xFFFFFAE9),
                      label: 'Bayar',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => ChangeNotifierProvider.value(
                              value: context.read<AnggotaController>(),
                              child: const PilihPembayaranView(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 48),
                    _buildMenuIcon(
                      icon: Icons.history,
                      color: const Color(0xFF2116A3),
                      bgColor: const Color(0xFFE9EDFF),
                      label: 'Riwayat',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => ChangeNotifierProvider.value(
                              value: context.read<AnggotaController>(),
                              child: const RiwayatView(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Riwayat Terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF074D2C), fontFamily: 'Poppins')),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => ChangeNotifierProvider.value(
                                value: context.read<AnggotaController>(),
                                child: const RiwayatView(),
                              ),
                            ),
                          );
                        },
                        child: const Text('Lihat Semua', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF10B367), fontFamily: 'Poppins')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: controller.riwayatTerakhir.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('Belum ada riwayat transaksi', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.riwayatTerakhir.length,
                          itemBuilder: (context, index) {
                            return AnggotaCard(transaction: controller.riwayatTerakhir[index]);
                          },
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuIcon({required IconData icon, required Color color, required Color bgColor, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: color, width: 1)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF535353), fontFamily: 'Poppins', letterSpacing: 0.65)),
        ],
      ),
    );
  }
}
