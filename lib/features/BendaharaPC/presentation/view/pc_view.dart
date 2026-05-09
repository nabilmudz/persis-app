import 'package:flutter/material.dart';
import '../../../BendaharaPJ/presentation/widgets/bendahara_shared_cards.dart';
import '../controller/pc_controller.dart';
import 'pc_bank_account_view.dart';
import '../widgets/verifikasi_card.dart';

class PcViewPage extends StatefulWidget {
  const PcViewPage({super.key});

  @override
  State<PcViewPage> createState() => _PcViewPageState();
}

class _PcViewPageState extends State<PcViewPage> {
  late final PcController _controller;

  Future<void> _loadTransactions() async {
    await _controller.loadTransactions();

    if (!mounted) return;

    final error = _controller.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = PcController();
    _loadTransactions();
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
            icon: const Icon(Icons.account_circle, size: 30),
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
          if (_controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0C844C)),
            );
          }

          return SingleChildScrollView(
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
                const BendaharaSaldoCard(
                  badgeText: 'Porsi pc (20%)',
                  title: 'Saldo Terkumpul',
                  saldo: 'Rp 1.450.000',
                  subtitle: '320 Anggota Lunas Bulan Agustus',
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: BendaharaMenuCard(
                        title: 'Data Tunggakan',
                        icon: Icons.assignment_late_outlined,
                        iconBackgroundColor: const Color(0xFFE9EDFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PcBankAccountPage(),
                            ),
                          );
                        },
                        child: BendaharaMenuCard(
                          title: 'Kelola Rekening',
                          icon: Icons.account_balance_wallet_outlined,
                          iconBackgroundColor: const Color(0xFFFFFBEA),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TEKS HEADER UDAH DIGANTI JADI PERLU DIVERIFIKASI
                    const Text(
                      'Perlu Diverifikasi',
                      style: TextStyle(
                        color: Color(0xFF074D2C),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/verifikasi-pc');
                      },
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: Color(0xFF0C844C),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_controller.previewTransactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Semua data sudah diverifikasi.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ..._controller.previewTransactions.map((tx) {
                    final item = _controller.toVerifikasiItem(tx);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: VerifikasiCard(
                        name: item.name,
                        date: item.date,
                        location: item.location,
                        idNumber: item.transaction.creatorId ?? item.idNumber,
                        paymentMethod: item.paymentMethod,
                        price: item.price,
                        status: item.category,
                      ),
                    );
                  }).toList(),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
