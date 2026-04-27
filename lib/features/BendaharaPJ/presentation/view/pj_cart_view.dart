import 'package:flutter/material.dart';

import '../controller/pj_controller.dart';

class PjCartViewPage extends StatelessWidget {
  final PjController controller;

  const PjCartViewPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Keranjang Transaksi PJ')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final items = controller.cartItems;
          final groupedItems = _groupByMember(items);

          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Keranjang masih kosong. Tambahkan item dari kartu iuran anggota.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  itemCount: groupedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final group = groupedItems[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.anggotaNama,
                                  style: const TextStyle(
                                    color: Color(0xFF073D4D),
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${group.totalMonths} bulan • ${group.periodsLabel}',
                                  style: const TextStyle(
                                    color: Color(0xFF4B5563),
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatCurrency(group.totalNominal),
                                  style: const TextStyle(
                                    color: Color(0xFF0B6A3B),
                                    fontSize: 13,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Hapus semua item anggota ini',
                            onPressed: () {
                              controller.removeMemberFromCart(group.anggotaId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Item ${group.anggotaNama} dihapus dari keranjang.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFB31012),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total ${controller.cartItemCount} item • ${_formatCurrency(controller.cartTotalNominal)}',
                      style: const TextStyle(
                        color: Color(0xFF073D4D),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              controller.clearCart();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Keranjang dikosongkan.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB31012),
                              side: const BorderSide(color: Color(0xFFB31012)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Kosongkan'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await controller.submitCart(
                                paymentMethodId: 'bank_transfer',
                              );

                              if (result == null) {
                                if (!context.mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Gagal membuat transaksi. Coba lagi.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Transaksi ${result.transactionId} dibuat: ${result.totalItems} item.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C844C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Submit Transaksi'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
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

  String _monthLabel(int month) {
    const names = [
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

    return names[month - 1];
  }

  List<_MemberCartGroup> _groupByMember(List<PjPaymentCartItem> items) {
    final Map<String, List<PjPaymentCartItem>> grouped = {};

    for (final item in items) {
      grouped
          .putIfAbsent(item.anggotaId, () => <PjPaymentCartItem>[])
          .add(item);
    }

    final result = <_MemberCartGroup>[];

    grouped.forEach((anggotaId, memberItems) {
      memberItems.sort((a, b) {
        final yearCompare = a.year.compareTo(b.year);
        if (yearCompare != 0) {
          return yearCompare;
        }
        return a.month.compareTo(b.month);
      });

      final totalNominal = memberItems.fold<double>(
        0,
        (sum, item) => sum + item.nominal,
      );
      final periods = memberItems
          .map((item) => '${_monthLabel(item.month)} ${item.year}')
          .join(', ');

      result.add(
        _MemberCartGroup(
          anggotaId: anggotaId,
          anggotaNama: memberItems.first.anggotaNama,
          totalMonths: memberItems.length,
          totalNominal: totalNominal,
          periodsLabel: periods,
        ),
      );
    });

    result.sort((a, b) => a.anggotaNama.compareTo(b.anggotaNama));
    return result;
  }
}

class _MemberCartGroup {
  final String anggotaId;
  final String anggotaNama;
  final int totalMonths;
  final double totalNominal;
  final String periodsLabel;

  const _MemberCartGroup({
    required this.anggotaId,
    required this.anggotaNama,
    required this.totalMonths,
    required this.totalNominal,
    required this.periodsLabel,
  });
}
