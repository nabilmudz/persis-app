import 'package:flutter/material.dart';
import '../controller/pj_controller.dart';
import 'tunai/pj_anggota_view.dart';
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
      appBar: AppBar(title: const Text('PJ View (Native)'), actions: []),
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
                const BendaharaSaldoCard(
                  badgeText: 'Porsi pj (20%)',
                  title: 'Saldo Terkumpul',
                  saldo: 'Rp 1.450.000',
                  subtitle: '320 Anggota Lunas Bulan Agustus',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: BendaharaMenuCard(
                        title: 'Pembayaran Tunai',
                        icon: Icons.assignment_late_outlined,
                        iconBackgroundColor: const Color(0xFFE9EDFF),
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
                        title: 'Pembayaran Non-Tunai',
                        icon: Icons.assignment_late_outlined,
                        iconBackgroundColor: const Color(0xFFE9EDFF),
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
                const SizedBox(height: 20),
                BendaharaMenuCard(
                  title: 'Data Anggota',
                  icon: Icons.people_outline,
                  iconBackgroundColor: const Color(0xFFFFFBEA),
                  onTap: () {
                    // Navigate to member data
                  },
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
