import 'package:flutter/material.dart';
import '../../data/datasources/iuran_local_datasources.dart';
import '../../data/models/iuran_model.dart';
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

  Future<void> _handleAccPressed(IuranModel item) async {
    final shouldContinue = await SweetAlertDialog.showConfirmation(
      context: context,
      title: 'Konfirmasi ACC',
      message: 'Yakin ingin meng-ACC pembayaran PJ ${item.lokasiPjNama}?',
      confirmText: 'Ya, ACC',
      cancelText: 'Batal',
    );

    if (!shouldContinue || !mounted) {
      return;
    }

    setState(() {
      item.status = StatusIuran.diverifikasi;
    });

    await SweetAlertDialog.showSuccess(
      context: context,
      title: 'Berhasil',
      message: 'Pembayaran PJ ${item.lokasiPjNama} berhasil di-ACC.',
      buttonText: 'OK',
    );
  }

  List<IuranModel> _previewIuran() {
    final filtered = dummyDaftarIuran
        .where((item) => item.status != StatusIuran.diverifikasi)
        .toList();

    filtered.sort((a, b) => b.tanggalBayar.compareTo(a.tanggalBayar));
    return filtered.take(2).toList();
  }

  @override
  void initState() {
    super.initState();
    _controller = PcController();
  }

  @override
  void dispose() {
    // 2. Wajib membuang controller saat pindah/menutup halaman agar tidak bocor memori (memory leak)
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewItems = _previewIuran();

    return Scaffold(
      appBar: AppBar(title: const Text('PC View (Native)')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
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
                            builder: (context) => const PcVerifikasiPage(),
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: VerifikasiCard(
                        date: _formatDate(item.tanggalBayar),
                        location: 'PJ ${item.lokasiPjNama}',
                        name: item.lokasiPjNama,
                        idNumber: '-',
                        paymentMethod: _paymentMethodText(item),
                        price: _formatCurrency(item.nominal),
                        onAccPressed: () async => _handleAccPressed(item),
                        onLihatBuktiPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Menampilkan bukti ${item.lokasiPjNama}',
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

  String _paymentMethodText(IuranModel item) {
    switch (item.metodePembayaran) {
      case MetodePembayaran.transferBank:
        return 'Transfer Bank';
      case MetodePembayaran.tunai:
        return 'Tunai';
      case MetodePembayaran.qrisCode:
        return 'QRIS';
      case null:
        return item.buktiTransferUrl == null ? 'Tunai' : 'Transfer';
    }
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = value.day.toString().padLeft(2, '0');
    return '$day ${months[value.month - 1]} ${value.year}';
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
