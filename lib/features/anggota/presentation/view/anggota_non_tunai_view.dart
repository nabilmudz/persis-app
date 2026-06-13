import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persis_app/features/anggota/presentation/controller/anggota_transaction_controller.dart';
import 'package:persis_app/features/bendahara_pj/data/models/transaction_model.dart';

class AnggotaNonTunaiView extends StatefulWidget {
  const AnggotaNonTunaiView({super.key});

  @override
  State<AnggotaNonTunaiView> createState() => _AnggotaNonTunaiViewState();
}

class _AnggotaNonTunaiViewState extends State<AnggotaNonTunaiView> {
  late final AnggotaTransactionController _controller;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _controller = AnggotaTransactionController();
    _controller.fetchNonTunaiTransactions(year: _selectedYear);
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

  String _paymentMethodLabel(TransactionModel tx) {
    final pm = (tx.paymentMethodId ?? '').toLowerCase().trim();
    switch (pm) {
      case 'transfer_bank':
      case 'transfer bank':
        return 'Transfer Bank';
      case 'qris':
        return 'QRIS';
      default:
        return pm.isNotEmpty ? pm : '-';
    }
  }

  String _statusLabel(String? status) {
    final s = (status ?? '').toLowerCase().trim();
    switch (s) {
      case 'completed':
        return 'Selesai';
      case 'draft':
        return 'Draft';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return s.isNotEmpty ? s : '-';
    }
  }

  Color _statusColor(String? status) {
    final s = (status ?? '').toLowerCase().trim();
    switch (s) {
      case 'completed':
        return const Color(0xFF10B367);
      case 'draft':
        return const Color(0xFFF57F17);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF6A6A6A);
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
                            formatDate: _formatDate,
                            paymentMethodLabel: _paymentMethodLabel,
                            statusLabel: _statusLabel,
                            statusColor: _statusColor,
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
  final String Function(String?) formatDate;
  final String Function(TransactionModel) paymentMethodLabel;
  final String Function(String?) statusLabel;
  final Color Function(String?) statusColor;

  const _TransactionCard({
    required this.tx,
    required this.formatDate,
    required this.paymentMethodLabel,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(tx.totalAmount ?? 0);

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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF2116A3),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paymentMethodLabel(tx),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF363636),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDate(tx.createdAt),
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
                  color: statusColor(tx.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel(tx.status),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: statusColor(tx.status),
                  ),
                ),
              ),
            ],
          ),
        ],
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
