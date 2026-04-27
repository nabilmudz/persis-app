import 'package:flutter/material.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';

import '../../../BendaharaPJ/presentation/widgets/bendahara_shared_cards.dart';
import '../controller/pc_controller.dart';
import 'pc_verif_view.dart';
import '../widgets/sweet_alert_dialog.dart';
import '../widgets/verifikasi_card.dart';

class PcViewPage extends StatefulWidget {
  const PcViewPage({super.key});

  @override
  State<PcViewPage> createState() => _PcViewPageState();
}

class _PcViewPageState extends State<PcViewPage> {
  // 1. Inisialisasi controller
  late final PcController _controller;

  Future<void> _loadTransactions() async {
    await _controller.loadTransactions();

    if (!mounted) {
      return;
    }

    final error = _controller.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _handleAccPressed(TransactionModel item) async {
    final nominalText = _controller.formatCurrency(item.totalAmount ?? 0);
    final shouldContinue = await SweetAlertDialog.showConfirmation(
      context: context,
      title: 'Konfirmasi ACC',
      message: 'Yakin ingin meng-ACC transaksi dengan nominal $nominalText?',
      confirmText: 'Ya, ACC',
      cancelText: 'Batal',
    );

    if (!shouldContinue || !mounted) {
      return;
    }

    final result = await _controller.accTransaction(item);

    if (!mounted) {
      return;
    }

    if (result == PcAccResult.alreadyVerified) {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Sudah Diverifikasi',
        message: 'Transaksi ini sudah pernah di-ACC sebelumnya.',
      );
      return;
    }

    if (result == PcAccResult.notFound) {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Data Tidak Ditemukan',
        message: 'Data transaksi gagal diperbarui. Coba lagi.',
      );
      return;
    }

    await SweetAlertDialog.showSuccess(
      context: context,
      title: 'Berhasil',
      message: 'Transaksi berhasil di-ACC.',
      buttonText: 'OK',
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = PcController();
    _loadTransactions();
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
      appBar: AppBar(title: const Text('PC View (Native)')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          final previewItems = _controller.previewTransactions;

          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
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
                      child: BendaharaMenuCard(
                        title: 'Kelola Rekening',
                        icon: Icons.account_balance_wallet_outlined,
                        iconBackgroundColor: const Color(0xFFFFFBEA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PcVerifikasiPage(controller: _controller),
                          ),
                        );
                      },
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: Color(0xFF10B367),
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (previewItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Belum ada data verifikasi',
                        style: TextStyle(color: Color(0xFF6A6A6A)),
                      ),
                    ),
                  )
                else
                  ...previewItems.map((item) {
                    final viewItem = _controller.toVerifikasiItem(item);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: VerifikasiCard(
                        date: viewItem.date,
                        location: viewItem.location,
                        name: viewItem.name,
                        idNumber: viewItem.idNumber,
                        paymentMethod: viewItem.paymentMethod,
                        price: viewItem.price,
                        onAccPressed: () async => _handleAccPressed(item),
                        onLihatBuktiPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Menampilkan detail transaksi dari ${viewItem.name}',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
