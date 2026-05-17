import 'package:flutter/material.dart';
import 'package:persis_app/app/routes.dart';
import 'package:intl/intl.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';

class TransferDetailPage extends StatelessWidget {
  final TransactionModel transaction;
  final String memberName;

  const TransferDetailPage({
    super.key,
    required this.transaction,
    required this.memberName,
  });

  String _formatCurrency(int? amount) {
    if (amount == null) return 'Rp 0';
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
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
    final pj = (amount * 30) ~/ 100;
    final pc = (amount * 20) ~/ 100;
    final pd = (amount * 20) ~/ 100;
    final pw = (amount * 15) ~/ 100;
    final pp = (amount * 15) ~/ 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembayaran Tunai'),
        elevation: 0,
        backgroundColor: const Color(0xFF073D4D),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status Banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B367),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pembayaran Disetujui',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        transaction.accStatus ?? 'approved',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Info Transaksi ──
            _SectionCard(
              title: 'Informasi Transaksi',
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Kode',
                    value:
                        (transaction.code != null &&
                            transaction.code!.isNotEmpty)
                        ? transaction.code!
                        : (transaction.id != null && transaction.id!.isNotEmpty
                              ? (transaction.id!.length > 8
                                    ? transaction.id!
                                          .substring(transaction.id!.length - 8)
                                          .toUpperCase()
                                    : transaction.id!.toUpperCase())
                              : '-'),
                  ),
                  _InfoRow(label: 'Nama Member', value: memberName),
                  _InfoRow(label: 'Jenis', value: 'Pembayaran Tunai'),
                  _InfoRow(
                    label: 'Tanggal',
                    value: _formatDate(transaction.createdAt),
                  ),
                  _InfoRow(
                    label: 'Diverifikasi Oleh',
                    value: transaction.verifiedBy ?? '-',
                  ),
                  _InfoRow(
                    label: 'Total',
                    value: _formatCurrency(transaction.totalAmount),
                    valueStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B367),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Info Bank ──
            if (transaction.bankName != null ||
                transaction.bankAccountName != null)
              _SectionCard(
                title: 'Info Rekening',
                child: Column(
                  children: [
                    if (transaction.bankName != null)
                      _InfoRow(label: 'Bank', value: transaction.bankName!),
                    if (transaction.bankAccountName != null)
                      _InfoRow(
                        label: 'Atas Nama',
                        value: transaction.bankAccountName!,
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            // ── Rincian Item ──
            if (transaction.items != null && transaction.items!.isNotEmpty)
              _SectionCard(
                title: 'Rincian Item',
                child: Column(
                  children: transaction.items!.map((item) {
                    return _InfoRow(
                      label: item.description ?? 'Iuran',
                      value: _formatCurrency(item.amount),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 12),

            // ── Distribusi Breakdown ──
            _SectionCard(
              title: 'Distribusi Iuran',
              child: Column(
                children: [
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
                        'Total',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF073D4D),
                        ),
                      ),
                      Text(
                        _formatCurrency(amount),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF073D4D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
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

// ── Section Card ──
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF073D4D),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Info Row ──
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style:
                  valueStyle ??
                  const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF073D4D),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Distribution Bar ──
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
