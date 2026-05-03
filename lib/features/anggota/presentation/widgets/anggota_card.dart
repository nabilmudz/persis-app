import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_item_model.dart';

class AnggotaCard extends StatelessWidget {
  final TransactionItemModel transaction;

  const AnggotaCard({Key? key, required this.transaction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
    final isLunas = transaction.status != 'pending' && transaction.status != 'tunggakan';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isLunas ? const Color(0xFFE9FFE9) : const Color(0xFFFFE9E9),
              border: Border.all(color: isLunas ? const Color(0xFF074D2C) : Colors.red, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLunas ? Icons.check_circle : Icons.warning_rounded, 
              color: isLunas ? const Color(0xFF10B367) : Colors.red, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? 'Iuran', 
                  style: const TextStyle(color: Color(0xFF074D2C), fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sistem PersisPay',
                  style: TextStyle(color: Color(0xFF6A6A6A), fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isLunas ? 'Lunas' : 'Belum Lunas',
                style: TextStyle(
                  color: isLunas ? const Color(0xFF10B367) : Colors.red, 
                  fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency.format(transaction.amount ?? 0),
                style: const TextStyle(color: Color(0xFF6A6A6A), fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
