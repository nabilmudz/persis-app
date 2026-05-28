import 'package:flutter/material.dart';
import 'package:persis_app/app/routes.dart';
import 'package:intl/intl.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_controller.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/laporan/pj_transfer_detail_view.dart';

class PjRecapDetailViewPage extends StatelessWidget {
  final String title;
  final List<TransactionModel> transactions;
  final int month;
  final int year;
  final String monthLabel;
  final String Function(TransactionModel) getMemberName;
  final PjController controller;

  const PjRecapDetailViewPage({
    super.key,
    required this.title,
    required this.transactions,
    required this.month,
    required this.year,
    required this.monthLabel,
    required this.getMemberName,
    required this.controller,
  });

  String _formatCurrency(int? amount) {
    if (amount == null) return 'Rp 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = transactions.fold<int>(
      0,
      (sum, t) => sum + (t.totalAmount ?? 0),
    );
    final pj = (totalAmount * 30) ~/ 100;
    final pc = (totalAmount * 20) ~/ 100;
    final pd = (totalAmount * 20) ~/ 100;
    final pw = (totalAmount * 15) ~/ 100;
    final pp = (totalAmount * 15) ~/ 100;

    return Scaffold(
      appBar: AppBar(
        title: Text('Rincian $title - $monthLabel $year'),
        elevation: 0,
        backgroundColor: const Color(0xFF073D4D),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Distribution Summary Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Distribusi (Total)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF073D4D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFE5E5E5)),
                    const SizedBox(height: 16),
                    _DistributionBar(
                      label: 'PJ',
                      percentage: 30,
                      amount: _formatCurrency(pj),
                      color: const Color(0xFF10B367),
                    ),
                    const SizedBox(height: 14),
                    _DistributionBar(
                      label: 'PC',
                      percentage: 20,
                      amount: _formatCurrency(pc),
                      color: const Color(0xFF007AFF),
                    ),
                    const SizedBox(height: 14),
                    _DistributionBar(
                      label: 'PD',
                      percentage: 20,
                      amount: _formatCurrency(pd),
                      color: const Color(0xFFFFA500),
                    ),
                    const SizedBox(height: 14),
                    _DistributionBar(
                      label: 'PW',
                      percentage: 15,
                      amount: _formatCurrency(pw),
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(height: 14),
                    _DistributionBar(
                      label: 'PP',
                      percentage: 15,
                      amount: _formatCurrency(pp),
                      color: const Color(0xFFEC4899),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Terkumpul',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF073D4D),
                          ),
                        ),
                        Text(
                          _formatCurrency(totalAmount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B367),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Transaksi ($title)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF073D4D),
                      ),
                    ),
                    Text(
                      'Periode: $monthLabel $year',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF6B7280).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
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
                final memberName = getMemberName(transaction);
                return _DetailedTransactionCard(
                  transaction: transaction,
                  memberName: memberName,
                  controller: controller,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransferDetailPage(
                          transaction: transaction,
                          memberName: memberName,
                          controller: controller,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RoleBottomNavigationBar(
        currentRoute: AppRoutes.bendaharaPJ,
        homeRoute: AppRoutes.bendaharaPJ,
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final String label;
  final int percentage;
  final String amount;
  final Color color;

  const _DistributionBar({
    required this.label,
    required this.percentage,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$label ($percentage%)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF073D4D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _DetailedTransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final String memberName;
  final VoidCallback onTap;
  final PjController controller;

  const _DetailedTransactionCard({
    required this.transaction,
    required this.memberName,
    required this.onTap,
    required this.controller,
  });

  String _formatCurrency(int? amount) {
    if (amount == null) return 'Rp 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (transaction.code != null && transaction.code!.isNotEmpty)
                      ? transaction.code!
                      : (transaction.id != null && transaction.id!.isNotEmpty
                            ? (transaction.id!.length > 8
                                  ? transaction.id!
                                        .substring(transaction.id!.length - 8)
                                        .toUpperCase()
                                  : transaction.id!.toUpperCase())
                            : '-'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF073D4D),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B367).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.accStatus ?? 'approved',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B367),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Nama: $memberName',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B367),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatCurrency(transaction.totalAmount),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B367),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(transaction.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Diverifikasi Oleh',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.lookupMemberName(transaction.accBy ?? transaction.verifiedBy),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
