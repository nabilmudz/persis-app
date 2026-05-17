import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Sesuaikan import model ke lokasi aslinya
import '../../../BendaharaPJ/data/models/transaction_model.dart';
import 'pc_transfer_detail_view.dart';

class PcRecapDetailViewPage extends StatelessWidget {
  final String title;
  final List<TransactionModel> transactions;
  final String monthLabel;
  final String Function(TransactionModel) getMemberName;

  const PcRecapDetailViewPage({
    super.key,
    required this.title,
    required this.transactions,
    required this.monthLabel,
    required this.getMemberName,
  });

  String _formatCurrency(int? amount) {
    if (amount == null) return 'Rp 0';
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = transactions.fold<int>(0, (sum, t) => sum + (t.totalAmount ?? 0));
    final pc = (totalAmount * 20) ~/ 100;

    return Scaffold(
      appBar: AppBar(
        title: Text('Rincian $title - $monthLabel', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16)),
        elevation: 0,
        backgroundColor: const Color(0xFF074D2C),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E5E5))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Hak PC (20%)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF073D4D))),
                    const SizedBox(height: 12),
                    Text(_formatCurrency(pc), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0C844C))),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Daftar Transaksi Masuk ($title)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF073D4D))),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PcTransferDetailPage(transaction: transaction, memberName: getMemberName(transaction))));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E5E5))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(transaction.id?.substring(0, 8).toUpperCase() ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF073D4D))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                              child: const Text('approved', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0C844C))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Nama: ${getMemberName(transaction)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0C844C))),
                        const SizedBox(height: 12),
                        Text(_formatCurrency(transaction.totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0C844C))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
