import 'package:flutter/material.dart';
import '../../data/datasources/iuran_local_datasources.dart';
import '../../data/models/iuran_model.dart';
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
      message: 'Yakin ingin meng-ACC pembayaran ${item.idAnggota.nama}?',
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
      message: 'Pembayaran ${item.idAnggota.nama} berhasil di-ACC.',
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
                _buildSaldoCard(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildMenuCard(
                        title: 'Data Tunggakan',
                        icon: Icons.assignment_late_outlined,
                        iconBackgroundColor: const Color(0xFFE9EDFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMenuCard(
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
                        location: 'PJ ${item.idAnggota.lokasiPj.nama}',
                        name: item.idAnggota.nama,
                        idNumber: item.idAnggota.noAnggota,
                        paymentMethod: _paymentMethodText(item),
                        price: _formatCurrency(item.nominal),
                        onAccPressed: () async => _handleAccPressed(item),
                        onLihatBuktiPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Menampilkan bukti ${item.idAnggota.nama}',
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

  Widget _buildSaldoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.03, 0.21),
          end: Alignment(1.55, 1.16),
          colors: [Color(0xFF10B367), Color(0xFF0C844C), Color(0xFF074D2C)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4C15803D),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0x77D9D9D9),
              borderRadius: BorderRadius.all(Radius.circular(80)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Porsi pc (20%)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Saldo Terkumpul',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Rp 1.450.000',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '320 Anggota Lunas Bulan Agustus',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color iconBackgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF074D2C), size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF074D2C),
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
