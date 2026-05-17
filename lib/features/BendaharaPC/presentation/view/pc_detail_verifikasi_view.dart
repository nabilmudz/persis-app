import 'package:flutter/material.dart';
import '../controller/pc_controller.dart';

class PcDetailVerifikasiPage extends StatelessWidget {
  final PcVerifikasiItem item;
  final PcController controller;

  const PcDetailVerifikasiPage({super.key, required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isVerified = controller.isVerified(item.transaction);
    final txId = item.transaction.creatorId ?? 'ID-${item.transaction.hashCode}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF074D2C), // Ijo Gelap
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Verifikasi Transaksi', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isVerified)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: const Color(0xFFFFF6ED), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.error_outline, color: Color(0xFFD35400), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Perlu Persetujuan PC', style: TextStyle(color: Color(0xFFB95E04), fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
                          SizedBox(height: 6),
                          Text('Mohon periksa kecocokan dana yang masuk ke rekening PC sebelum menekan tombol Verifikasi.', style: TextStyle(color: Color(0xFFB95E04), fontFamily: 'Poppins', fontSize: 11)),
                        ],
                      ),
                    )
                  ],
                ),
              ),

            const Text('Rincian Transaksi', style: TextStyle(color: Color(0xFF142B42), fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
                boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildDetailRow('Kode Transaksi', txId),
                  const Divider(height: 32, color: Color(0xFFEEEEEE)),
                  _buildDetailRow('Jenis', 'Setoran Kas PJ', isBold: true),
                  const Divider(height: 32, color: Color(0xFFEEEEEE)),
                  _buildDetailRow('Dari', item.name, isBold: true),
                  const Divider(height: 32, color: Color(0xFFEEEEEE)),
                  _buildDetailRow('Tanggal Transaksi', item.date, isBold: true),
                  const Divider(height: 32, color: Color(0xFFEEEEEE)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Dana (Porsi PC)', style: TextStyle(color: Color(0xFF142B42), fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(item.price, style: const TextStyle(color: Color(0xFF4CAF50), fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isVerified ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await controller.accTransaction(item.transaction);
                    if (result == PcAccResult.success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil Diverifikasi')));
                      Navigator.pop(context, true); 
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  label: const Text('Verifikasi (ACC)', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF7F8C8D), fontFamily: 'Poppins', fontSize: 12)),
        Flexible(
          child: Text(
            value, 
            textAlign: TextAlign.right,
            style: TextStyle(color: const Color(0xFF2C3E50), fontFamily: 'Poppins', fontSize: 12, fontWeight: isBold ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
