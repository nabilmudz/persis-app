import 'package:flutter/material.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/laporan/pj_payment_data_view.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/anggota/riwayat_view.dart';

import '../controller/pj_controller.dart';
import 'anggota/pj_anggota_view.dart';
import 'tunai/pj_anggota_view.dart' as tunai_anggota;
import 'tunai/pending_transaction_view.dart';
import 'non-tunai/pj_verif_non_tunai_view.dart';
import '../widgets/bendahara_shared_cards.dart';

class PjViewPage extends StatefulWidget {
  const PjViewPage({super.key});

  @override
  State<PjViewPage> createState() => _PjViewPageState();
}

class _PjViewPageState extends State<PjViewPage> {
  // 1. Inisialisasi controller
  late final PjController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PjController();
    _controller.loadInitialData();
  }

  @override
  void dispose() {
    // 2. Wajib membuang controller saat pindah/menutup halaman agar tidak bocor memori (memory leak)
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PJ View (Native)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFF073D4D)),
            tooltip: 'Pending Transaction',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PendingTransactionViewPage(controller: _controller),
                ),
              );
            },
          ),
          // === TAMBAHAN TOMBOL PROFIL DI SINI ===
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              size: 30,
              color: Color(0xFF073D4D),
            ),
            tooltip: 'Profil',
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang\nBendahara PJ',
                  style: TextStyle(
                    color: Color(0xFF073D4D),
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                BendaharaSaldoCard(
                  role: 'pj',
                  badgeText: 'Porsi PJ (30%)',
                  title: 'Saldo Terkumpul ${DateTime.now().year}',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: BendaharaMenuCard(
                        title: 'Data Anggota',
                        icon: Icons.people_outline,
                        iconBackgroundColor: const Color(0xFFFFFBEA),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PjAnggotaViewPage(controller: _controller),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BendaharaMenuCard(
                        title: 'Bayar Iuran',
                        icon: Icons.paid_outlined,
                        iconBackgroundColor: const Color(0xFFFFFBEA),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PjVerifNonTunaiViewPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: BendaharaMenuCard(
                        title: 'Riwayat Pembayaran',
                        icon: Icons.history,
                        iconBackgroundColor: const Color(0xFFE9EDFF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PjRiwayatView(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BendaharaMenuCard(
                        title: 'Laporan Keuangan',
                        icon: Icons.bar_chart_outlined,
                        iconBackgroundColor: const Color(0xFFE9EDFF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PjPaymentDataViewPage(
                                controller: _controller,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}
