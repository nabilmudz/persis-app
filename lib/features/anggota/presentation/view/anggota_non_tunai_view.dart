import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/features/anggota/presentation/controller/anggota_transaction_controller.dart';
import 'package:persis_app/features/anggota/presentation/view/anggota_invoice_detail_view.dart';
import 'package:persis_app/features/bendahara_pc/data/datasources/payment_method_remote_datasources.dart';
import 'package:persis_app/features/bendahara_pc/data/models/payment_method_model.dart';
import 'package:persis_app/features/bendahara_pj/data/models/transaction_model.dart';

class AnggotaNonTunaiView extends StatefulWidget {
  const AnggotaNonTunaiView({super.key});

  @override
  State<AnggotaNonTunaiView> createState() => _AnggotaNonTunaiViewState();
}

class _AnggotaNonTunaiViewState extends State<AnggotaNonTunaiView> {
  late final AnggotaTransactionController _controller;
  int _selectedYear = DateTime.now().year;
  final List<PaymentMethodModel> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _controller = AnggotaTransactionController();
    _controller.fetchNonTunaiTransactions(year: _selectedYear);
    _fetchPaymentMethods();
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final ds = PaymentMethodRemoteDataSource(AppConfig.baseUrl);
      final methods = await ds.getAllPaymentMethods();
      if (mounted)
        setState(
          () => _paymentMethods
            ..clear()
            ..addAll(methods),
        );
    } catch (_) {}
  }

  String _resolvePaymentMethod(String? id) {
    if (id == null || id.isEmpty) return '-';
    final match = _paymentMethods.where((pm) => pm.id == id);
    if (match.isNotEmpty) {
      final code = match.first.code?.trim();
      if (code != null && code.isNotEmpty) return code;
    }
    return id;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _monthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day} ${_monthNames[dt.month]} ${dt.year}';
  }

  String _transactionTitle(TransactionModel tx) {
    final items = tx.items;
    if (items != null && items.isNotEmpty) {
      final months = <int>[];
      int? year;
      for (final item in items) {
        final resolved = _resolveMonthYear(item);
        if (resolved.$1 > 0) {
          months.add(resolved.$1);
          year ??= resolved.$2;
        }
      }
      if (months.isNotEmpty) {
        months.sort();
        year ??= DateTime.now().year;
        final monthLabel = months.map((m) => _monthNames[m]).join(', ');
        return 'Iuran $monthLabel $year';
      }
    }
    final dt = DateTime.tryParse(tx.createdAt ?? '');
    if (dt != null) {
      return 'Iuran ${_monthNames[dt.month]} ${dt.year}';
    }
    return 'Iuran';
  }

  (int, int?) _resolveMonthYear(dynamic item) {
    if (item == null) return (0, null);
    final pm = item.periodMonth;
    final py = item.periodYear;
    if (pm is int && pm >= 1 && pm <= 12 && py is int) {
      return (pm, py);
    }

    final desc = (item.description ?? '').toString().trim();
    if (desc.isNotEmpty) {
      for (int i = 1; i < _monthNames.length; i++) {
        if (desc.toLowerCase().contains(_monthNames[i].toLowerCase())) {
          final yearMatch = RegExp(r'(19|20)\d{2}').firstMatch(desc);
          return (
            i,
            yearMatch != null ? int.tryParse(yearMatch.group(0)!) : null,
          );
        }
      }
    }

    final periodId = (item.periodId ?? item.duesPeriodId ?? '')
        .toString()
        .trim();
    if (periodId.isNotEmpty) {
      final match = RegExp(r'(\d{4})[-_/](\d{1,2})').firstMatch(periodId);
      if (match != null) {
        final y = int.tryParse(match.group(1)!);
        final m = int.tryParse(match.group(2)!);
        if (y != null && m != null && m >= 1 && m <= 12) return (m, y);
      }
    }

    return (0, null);
  }

  String _paymentMethodLabel(TransactionModel tx) {
    return _resolvePaymentMethod(tx.paymentMethodId);
  }

  String _accStatusLabel(String? accStatus, {String? rejectionReason}) {
    final s = (accStatus ?? '').toLowerCase().trim();
    switch (s) {
      case 'acc_pc':
        return 'Disetujui PC';
      case 'acc_pd':
        return 'Disetujui PD';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        final reason = rejectionReason ?? '';
        return reason.isNotEmpty ? 'Ditolak — $reason' : 'Ditolak';
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

  IconData _accStatusIcon(String? accStatus) {
    final s = (accStatus ?? '').toLowerCase().trim();
    switch (s) {
      case 'acc_pc':
      case 'acc_pd':
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      case 'acc_pj':
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
  }

  List<int> _availableYears() {
    final currentYear = DateTime.now().year;
    return List.generate(5, (i) => currentYear - i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transaksi Non-Tunai',
          style: TextStyle(
            color: Color(0xFF363636),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFD0D0D0), height: 1.0),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading &&
              _controller.nonTunaiTransactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null &&
              _controller.nonTunaiTransactions.isEmpty) {
            return _ErrorState(
              message: _controller.errorMessage!,
              onRetry: () =>
                  _controller.fetchNonTunaiTransactions(year: _selectedYear),
            );
          }

          final transactions = _controller.nonTunaiTransactions;

          return RefreshIndicator(
            color: const Color(0xFF189D4A),
            onRefresh: () =>
                _controller.fetchNonTunaiTransactions(year: _selectedYear),
            child: Column(
              children: [
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: _availableYears().map((year) {
                      final isSelected = _selectedYear == year;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedYear = year);
                            _controller.fetchNonTunaiTransactions(year: year);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF189D4A)
                                  : const Color(0xFFEDEDED),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              '$year',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF7F7F7F),
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: transactions.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) => _TransactionCard(
                            tx: transactions[index],
                            txTitle: _transactionTitle(transactions[index]),
                            formatDate: _formatDate,
                            paymentMethodLabel: _paymentMethodLabel,
                            accStatusLabel: _accStatusLabel,
                            accStatusColor: _accStatusColor,
                            accStatusIcon: _accStatusIcon,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel tx;
  final String txTitle;
  final String Function(String?) formatDate;
  final String Function(TransactionModel) paymentMethodLabel;
  final String Function(String?, {String? rejectionReason}) accStatusLabel;
  final Color Function(String?) accStatusColor;
  final IconData Function(String?) accStatusIcon;

  const _TransactionCard({
    required this.tx,
    required this.txTitle,
    required this.formatDate,
    required this.paymentMethodLabel,
    required this.accStatusLabel,
    required this.accStatusColor,
    required this.accStatusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(tx.totalAmount ?? 0);
    final statusColor = accStatusColor(tx.accStatus);
    final pay = paymentMethodLabel(tx);
    final subtitle = '${formatDate(tx.createdAt)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnggotaInvoiceDetailView(transaction: tx),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                accStatusIcon(tx.accStatus),
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txTitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF363636),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
                  formatted,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF363636),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    accStatusLabel(
                      tx.accStatus,
                      rejectionReason: tx.rejectionReason,
                    ),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: statusColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada transaksi non-tunai.',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF189D4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
