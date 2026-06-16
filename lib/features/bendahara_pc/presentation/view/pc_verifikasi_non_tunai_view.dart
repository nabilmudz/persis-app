import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persis_app/app/routes.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';
import 'package:persis_app/features/bendahara_pj/data/models/transaction_model.dart';
import '../controller/pc_controller.dart';
import 'pc_verifikasi_non_tunai_detail_view.dart';

class PcVerifikasiNonTunaiView extends StatefulWidget {
  final PcController controller;

  const PcVerifikasiNonTunaiView({super.key, required this.controller});

  @override
  State<PcVerifikasiNonTunaiView> createState() =>
      _PcVerifikasiNonTunaiViewState();
}

class _PcVerifikasiNonTunaiViewState extends State<PcVerifikasiNonTunaiView> {
  String _accStatusLabel(String? accStatus) {
    final s = (accStatus ?? '').toLowerCase().trim();
    switch (s) {
      case 'acc_pc':
        return 'Disetujui PC';
      case 'acc_pd':
        return 'Disetujui PD';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
      case 'acc_pj':
        return 'Menunggu ACC';
      default:
        return s.isNotEmpty ? s : '-';
    }
  }

  Color _accStatusColor(String? accStatus) {
    final s = (accStatus ?? '').toLowerCase().trim();
    switch (s) {
      case 'acc_pc':
      case 'acc_pd':
      case 'approved':
        return const Color(0xFF10B367);
      case 'rejected':
        return const Color(0xFFE53935);
      case 'pending':
      case 'acc_pj':
        return const Color(0xFFF57F17);
      default:
        return const Color(0xFF6A6A6A);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF363636)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verifikasi Pembayaran',
          style: TextStyle(
            color: Color(0xFF363636),
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final items = widget.controller.allNonTunaiTransactions;

          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada transaksi yang perlu diverifikasi.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF6A6A6A),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => widget.controller.loadTransactions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final tx = items[index];
                final name = tx.memberName ?? tx.creatorId ?? '-';
                final date = tx.createdAt != null
                    ? DateFormat('dd MMM yyyy').format(
                        DateTime.parse(tx.createdAt!),
                      )
                    : '-';
                final amount = tx.totalAmount ?? 0;
                final method = tx.bankName ?? 'Non-Tunai';
                final statusLabel = _accStatusLabel(tx.accStatus);
                final statusColor = _accStatusColor(tx.accStatus);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PcVerifikasiNonTunaiDetailView(
                            transaction: tx,
                            controller: widget.controller,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        widget.controller.loadTransactions();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF363636),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$method • $date',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Color(0xFF6A6A6A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatCurrency.format(amount),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF0C844C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const RoleBottomNavigationBar(
        currentRoute: AppRoutes.bendaharaPC,
        homeRoute: AppRoutes.bendaharaPC,
      ),
    );
  }
}
