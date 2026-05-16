import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Sesuaikan import model ke lokasi aslinya
import '../../../BendaharaPJ/data/models/transaction_model.dart';

class PcTransferDetailPage extends StatelessWidget {
  final TransactionModel transaction;
  final String memberName;

  const PcTransferDetailPage({super.key, required this.transaction, required this.memberName});

  String _formatCurrency(int? amount) {
    if (amount == null) return 'Rp 0';
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = transaction.totalAmount ?? 0;
    final pc = (amount * 20) ~/ 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
        elevation: 0,
        backgroundColor: const Color(0xFF074D2C),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E5E5))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rincian', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF073D4D))),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE5E5E5)),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Kode Trx', value: transaction.id?.substring(0, 8).toUpperCase() ?? '-'),
                  _InfoRow(label: 'Dari', value: memberName),
                  _InfoRow(label: 'Tanggal', value: _formatDate(transaction.createdAt)),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE5E5E5)),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Nominal Masuk', value: _formatCurrency(amount)),
                  _InfoRow(
                    label: 'Porsi Hak PC (20%)', 
                    value: _formatCurrency(pc), 
                    valueStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0C844C))
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          Text(value, style: valueStyle ?? const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF073D4D))),
        ],
      ),
    );
  }
}
