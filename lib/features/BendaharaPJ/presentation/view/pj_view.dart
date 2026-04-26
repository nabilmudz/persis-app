import 'package:flutter/material.dart';
import 'package:persis_app/features/BendaharaPC/data/models/iuran_model.dart';
import '../controller/pj_controller.dart';
import 'pj_anggota_view.dart';
import 'pj_cart_view.dart';
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
  }

  Future<void> _handleSubmitCart() async {
    if (_controller.cartItemCount == 0) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang kosong. Tambahkan item terlebih dahulu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = _controller.submitCart(
      metodePembayaran: MetodePembayaran.transferBank,
    );

    if (result == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Transaksi ${result.transactionId} dibuat: ${result.totalItems} item • ${_formatCurrency(result.totalNominal)}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              return IconButton(
                tooltip: 'Lihat keranjang',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PjCartViewPage(controller: _controller),
                    ),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (_controller.cartItemCount > 0)
                      Positioned(
                        right: -6,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB31012),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _controller.cartItemCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
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
                        title: 'Data Anggota',
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
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBEE7CC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keranjang Transaksi PJ',
                        style: TextStyle(
                          color: Color(0xFF0B6A3B),
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_controller.cartItemCount} item terpilih • Total ${_formatCurrency(_controller.cartTotalNominal)}',
                        style: const TextStyle(
                          color: Color(0xFF0B6A3B),
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleSubmitCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C844C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Submit Satu Transaksi Gabungan'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatCurrency(double amount) {
    final number = amount.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < number.length; i++) {
      final reverseIndex = number.length - i;
      buffer.write(number[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp. ${buffer.toString()}';
  }
}
