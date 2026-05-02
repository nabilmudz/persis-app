import 'package:flutter/material.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import '../../controller/pj_controller.dart';

class PendingTransactionViewPage extends StatelessWidget {
  final PjController controller;

  const PendingTransactionViewPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final pendingTransactions = controller.transactions.where((tx) {
      final status = (tx.status ?? '').toLowerCase();
      final accStatus = (tx.accStatus ?? '').toLowerCase();
      return status == 'pending' || accStatus == 'pending';
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Transaction'),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          if (controller.isLoading && controller.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (pendingTransactions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tidak ada transaksi pending saat ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: pendingTransactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final transaction = pendingTransactions[index];
              return _PendingTransactionCard(transaction: transaction);
            },
          );
        },
      ),
    );
  }
}

class _PendingTransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const _PendingTransactionCard({required this.transaction});

  String _formatCurrency(int? amount) {
    final value = amount ?? 0;
    final number = value.toString();
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

  @override
  Widget build(BuildContext context) {
    final status = transaction.status ?? transaction.accStatus ?? 'unknown';
    final createdAt = transaction.createdAt != null
        ? DateTime.tryParse(transaction.createdAt!)
        : null;
    final dateLabel = createdAt != null
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
        : 'Tanggal tidak tersedia';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaksi ${transaction.paymentMethodId ?? 'N/A'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total: ${_formatCurrency(transaction.totalAmount)}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0B6A3B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Status: ${status.toUpperCase()}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFB31012),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dibuat: $dateLabel',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
