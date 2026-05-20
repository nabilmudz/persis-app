import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persis_app/app/routes.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_controller.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_hive_controller.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_invoice_controller.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/widgets/sweet_alert_dialog.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/pj_invoice.view.dart';

class PendingTransactionViewPage extends StatefulWidget {
  final PjController controller;
  final PjInvoiceData? lastInvoiceData;

  const PendingTransactionViewPage({
    super.key,
    required this.controller,
    this.lastInvoiceData,
  });

  @override
  State<PendingTransactionViewPage> createState() =>
      _PendingTransactionViewPageState();
}

class _PendingTransactionViewPageState
    extends State<PendingTransactionViewPage> {
  final PjHiveController _hiveController = PjHiveController();

  PjInvoiceData? _lastInvoiceData;

  @override
  void initState() {
    super.initState();
    _lastInvoiceData = widget.lastInvoiceData;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hiveController.syncPendingTransactions();
    });
  }

  Future<void> _syncPendingTransactions() async {
    await _hiveController.syncPendingTransactions();
  }

  Future<void> _deletePendingTransaction(
    dynamic key,
    Map<String, dynamic> transactionData,
  ) async {
    final paymentMethod =
        transactionData['paymentMethodId'] ??
        transactionData['tipe'] ??
        'Tunai';

    final shouldDelete = await SweetAlertDialog.showConfirmation(
      context: context,
      title: 'Hapus transaksi?',
      message:
          'Transaksi $paymentMethod akan dihapus dari penyimpanan lokal Hive.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
    );

    if (!shouldDelete || !mounted) {
      return;
    }

    await _hiveController.removeSyncedTransaction(key);

    if (!mounted) {
      return;
    }

    await SweetAlertDialog.showSuccess(
      context: context,
      title: 'Berhasil',
      message: 'Data transaksi lokal berhasil dihapus.',
    );
  }

  void _openLastInvoice() {
    if (_lastInvoiceData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PjInvoiceViewPage(invoiceData: _lastInvoiceData!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingBox = Hive.box('pj_pending_transactions');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Pending (Lokal)'),
        actions: [
          if (_lastInvoiceData != null)
            IconButton(
              tooltip: 'Lihat Invoice Terakhir',
              icon: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF0C844C),
              ),
              onPressed: _openLastInvoice,
            ),
          IconButton(
            tooltip: 'Sync sekarang',
            icon: const Icon(Icons.sync),
            onPressed: _syncPendingTransactions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _syncPendingTransactions,
        child: ValueListenableBuilder<Box>(
          valueListenable: pendingBox.listenable(),
          builder: (context, box, child) {
            final pendingTransactions = _hiveController
                .getPendingTransactions();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (_lastInvoiceData != null) ..._buildInvoiceBanner(context),
                if (pendingTransactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        'Tidak ada transaksi pending (lokal) saat ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  ...List.generate(pendingTransactions.length, (index) {
                    final transactionKey = pendingTransactions[index]['key'];
                    final transactionMap =
                        pendingTransactions[index]['data']
                            as Map<String, dynamic>;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < pendingTransactions.length - 1 ? 12 : 0,
                      ),
                      child: _PendingTransactionCard(
                        transactionData: transactionMap,
                        onDelete: () => _deletePendingTransaction(
                          transactionKey,
                          transactionMap,
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const RoleBottomNavigationBar(
        currentRoute: AppRoutes.bendaharaPJ,
        homeRoute: AppRoutes.bendaharaPJ,
      ),
    );
  }

  List<Widget> _buildInvoiceBanner(BuildContext context) {
    final invoice = _lastInvoiceData!;
    return [
      GestureDetector(
        onTap: _openLastInvoice,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF073D4D), Color(0xFF0C844C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220C844C),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Terakhir',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${invoice.memberName} · ${invoice.totalFormatted}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        invoice.syncedToBackend
                            ? 'Terkirim ke Server'
                            : 'Tersimpan Lokal (Pending)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

class _PendingTransactionCard extends StatelessWidget {
  final Map<String, dynamic> transactionData;
  final VoidCallback onDelete;

  const _PendingTransactionCard({
    required this.transactionData,
    required this.onDelete,
  });

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp. 0';
    final number = amount.toString();
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

  int _extractTotalAmount(Map<String, dynamic> data) {
    final directTotal = data['total_amount'] ?? data['totalAmount'];
    if (directTotal is num) {
      return directTotal.toInt();
    }
    if (directTotal is String) {
      return int.tryParse(directTotal.replaceAll('.', '')) ?? 0;
    }

    final items = data['items'];
    if (items is List) {
      return items.fold<int>(0, (sum, item) {
        if (item is Map) {
          final amount = item['amount'];
          if (amount is num) {
            return sum + amount.toInt();
          }
          if (amount is String) {
            return sum + (int.tryParse(amount) ?? 0);
          }
        }
        return sum;
      });
    }

    final nominal = data['nominal'];
    if (nominal is num) {
      return nominal.toInt();
    }
    if (nominal is String) {
      return int.tryParse(nominal.replaceAll('.', '')) ?? 0;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final status =
        transactionData['status'] ?? transactionData['accStatus'] ?? 'pending';
    final timestamp =
        transactionData['local_timestamp'] ?? transactionData['createdAt'];
    final createdAt = timestamp != null
        ? DateTime.tryParse(timestamp.toString())
        : null;
    final dateLabel = createdAt != null
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
        : 'Tanggal tidak tersedia';

    final paymentMethod =
        transactionData['paymentMethodId'] ??
        transactionData['tipe'] ??
        'Tunai';
    final totalAmount = _extractTotalAmount(transactionData);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Transaksi $paymentMethod',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Hapus transaksi',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Total: ${_formatCurrency(totalAmount)}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0B6A3B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Status: ${status.toString().toUpperCase()}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFB31012),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dibuat: $dateLabel',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
