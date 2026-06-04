import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:persis_app/features/bendahara_pj/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/bendahara_pj/data/models/transaction_model.dart';
import 'package:persis_app/features/bendahara_pj/presentation/controller/pj_controller.dart';
import 'package:persis_app/features/bendahara_pj/presentation/controller/pj_laporan_controller.dart';
import 'package:persis_app/core/helpers/auth_helper.dart';

class PjLogTransaksiView extends StatefulWidget {
  final PjController controller;

  const PjLogTransaksiView({super.key, required this.controller});

  @override
  State<PjLogTransaksiView> createState() => _PjLogTransaksiViewState();
}

class _PjLogTransaksiViewState extends State<PjLogTransaksiView> {
  DateTime _selectedMonth = DateTime.now();
  bool _filterByMonth = false;
  bool _isLoading = true;

  List<TransactionModel> _allTransactions = [];
  late final PjLaporanController _laporanController;

  static const _statusLunas = {
    'paid',
    'lunas',
    'selesai',
    'success',
    'completed',
  };

  static const _monthNames = [
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

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _laporanController = PjLaporanController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _laporanController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final dataSource = TransactionRemoteDataSource();
      final monthParam = _filterByMonth ? _selectedMonth.month : 0;
      final yearParam = _selectedMonth.year;

      final creatorId = await AuthHelper.getUserId() ?? '';
      final regionId = await AuthHelper.getRegionId() ?? '';

      final txList = await dataSource.getLogTransactions(
        creatorId: creatorId,
        year: yearParam,
        regionId: regionId,
        month: monthParam,
      );

      if (mounted) {
        setState(() {
          _allTransactions = txList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[PjLogTransaksi] Error: $e');
      if (mounted) {
        setState(() {
          _allTransactions = [];
          _isLoading = false;
        });
      }
    }
  }

  bool _isLunas(TransactionModel tx) {
    final status = (tx.status ?? '').trim().toLowerCase();
    final accStatus = (tx.accStatus ?? '').trim().toLowerCase();
    return _statusLunas.any((s) => status.contains(s)) ||
        accStatus == 'acc_pj' ||
        accStatus == 'approved';
  }

  bool _matchesSelectedMonth(TransactionModel tx) {
    if (tx.createdAt == null) return false;
    try {
      final date = DateTime.parse(tx.createdAt!).toLocal();
      return date.year == _selectedMonth.year &&
          date.month == _selectedMonth.month;
    } catch (_) {
      return false;
    }
  }

  List<TransactionModel> get _filteredTransactions {
    return _allTransactions.where((tx) {
      if (!_isLunas(tx)) return false;
      if (_filterByMonth) return _matchesSelectedMonth(tx);
      return true;
    }).toList()..sort((a, b) {
      final aDate = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1900);
      final bDate = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1900);
      return bDate.compareTo(aDate);
    });
  }

  String _getMemberName(TransactionModel tx) {
    if (tx.memberName?.trim().isNotEmpty == true) {
      return tx.memberName!.trim();
    }
    final items = tx.items ?? [];
    if (items.isNotEmpty && items.first.memberName?.trim().isNotEmpty == true) {
      return items.first.memberName!.trim();
    }
    return '-';
  }

  String _getNpa(TransactionModel tx) {
    if (tx.npa?.trim().isNotEmpty == true) {
      return tx.npa!.trim();
    }
    final items = tx.items ?? [];
    if (items.isNotEmpty && items.first.npa?.trim().isNotEmpty == true) {
      return items.first.npa!.trim();
    }
    return '';
  }

  List<String> _getPaidMonths(TransactionModel tx) {
    final items = tx.items ?? [];
    final result = <_PeriodEntry>[];

    for (final item in items) {
      final pid = (item.periodId ?? '').trim();
      if (pid.isEmpty) continue;
      final parts = pid.split('-');
      if (parts.length >= 2) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y != null && m != null && m >= 1 && m <= 12) {
          result.add(_PeriodEntry(year: y, month: m));
        }
      }
    }

    if (result.isEmpty) {
      if (tx.createdAt != null) {
        try {
          final date = DateTime.parse(tx.createdAt!).toLocal();
          return ['${_monthNames[date.month - 1]} ${date.year}'];
        } catch (_) {}
      }
      return ['-'];
    }

    result.sort((a, b) {
      if (a.year != b.year) return a.year.compareTo(b.year);
      return a.month.compareTo(b.month);
    });

    return result.map((e) => '${_monthNames[e.month - 1]} ${e.year}').toList();
  }

  String _formatCurrency(int? amount) {
    if (amount == null) return 'Rp 0';
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return '-';
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'PILIH BULAN TRANSAKSI',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF073D4D),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _filterByMonth = true;
      });
      _loadData();
    }
  }

  int get _totalAmount =>
      _filteredTransactions.fold(0, (s, tx) => s + (tx.totalAmount ?? 0));

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text(
          'Log Transaksi PJ',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF073D4D),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          if (!_isLoading && filtered.isNotEmpty) _buildSummaryCard(filtered),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B367)),
                  )
                : filtered.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: const Color(0xFF10B367),
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        return _TransaksiCard(
                          transaction: tx,
                          memberName: _getMemberName(tx),
                          npa: _getNpa(tx),
                          paidMonths: _getPaidMonths(tx),
                          formatCurrency: _formatCurrency,
                          formatDate: _formatDate,
                          controller: widget.controller,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final monthLabel = _filterByMonth
        ? DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth)
        : 'Pilih Bulan';

    return Container(
      color: const Color(0xFF073D4D),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _ChipButton(
            label: 'Semua',
            isSelected: !_filterByMonth,
            onTap: () {
              if (_filterByMonth) {
                setState(() {
                  _filterByMonth = false;
                  _selectedMonth = DateTime.now();
                });
                _loadData();
              }
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _pickMonth,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _filterByMonth
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _filterByMonth
                      ? const Color(0xFF10B367)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 14,
                    color: _filterByMonth
                        ? const Color(0xFF073D4D)
                        : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    monthLabel,
                    style: TextStyle(
                      color: _filterByMonth
                          ? const Color(0xFF073D4D)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            _filterByMonth ? 'Tgl dibuat transaksi' : 'Semua transaksi',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              fontFamily: 'Poppins',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<TransactionModel> txs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B367), Color(0xFF0C844C), Color(0xFF074D2C)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3315803D),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.white70,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _filterByMonth
                      ? 'Dibayar ${DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth)}'
                      : 'Total Semua Transaksi Lunas',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(_totalAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${txs.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              const Text(
                'Transaksi',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: const Color(0xFF073D4D).withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            _filterByMonth
                ? 'Tidak ada transaksi\npada ${DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth)}'
                : 'Belum ada transaksi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF073D4D).withValues(alpha: 0.5),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transaksi yang sudah dibayar\nakan muncul di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.withValues(alpha: 0.7),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodEntry {
  const _PeriodEntry({required this.year, required this.month});
  final int year;
  final int month;
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B367)
                : Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF073D4D) : Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TransaksiCard extends StatelessWidget {
  const _TransaksiCard({
    required this.transaction,
    required this.memberName,
    required this.npa,
    required this.paidMonths,
    required this.formatCurrency,
    required this.formatDate,
    required this.controller,
  });

  final TransactionModel transaction;
  final String memberName;
  final String npa;
  final List<String> paidMonths;
  final String Function(int?) formatCurrency;
  final String Function(String?) formatDate;
  final PjController controller;

  Color get _statusColor {
    final s = (transaction.status ?? '').toLowerCase();
    final a = (transaction.accStatus ?? '').toLowerCase();
    if (s == 'completed' ||
        s == 'paid' ||
        s == 'lunas' ||
        a == 'acc_pj' ||
        a == 'approved') {
      return const Color(0xFF10B367);
    }
    return Colors.orange;
  }

  String get _statusLabel {
    final s = (transaction.status ?? '').toLowerCase();
    final a = (transaction.accStatus ?? '').toLowerCase();
    if (s == 'completed' || a == 'acc_pj') return 'Lunas';
    if (s == 'paid') return 'Dibayar';
    return 'Selesai';
  }

  @override
  Widget build(BuildContext context) {
    final amount = transaction.totalAmount ?? 0;
    final tanggalBayar = formatDate(transaction.createdAt);
    final hasMultiMonth = paidMonths.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Text(
                    _initials(memberName),
                    style: const TextStyle(
                      color: Color(0xFF073D4D),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memberName,
                        style: const TextStyle(
                          color: Color(0xFF073D4D),
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (npa.isNotEmpty)
                        Text(
                          'NPA: $npa',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                            fontFamily: 'Poppins',
                          ),
                        ),
                    ],
                  ),
                ),
                _StatusBadge(label: _statusLabel, color: _statusColor),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 13,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Text(
                  'Tanggal transaksi: ',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  tanggalBayar,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 13,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Di ACC oleh: ',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  controller.lookupMemberName(
                    transaction.accBy ?? transaction.verifiedBy,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasMultiMonth
                          ? 'Membayar iuran (${paidMonths.length} bulan):'
                          : 'Membayar iuran:',
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: paidMonths
                      .map(
                        (m) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: Text(
                            m,
                            style: const TextStyle(
                              color: Color(0xFF1E40AF),
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B367).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Dibayarkan',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formatCurrency(amount),
                    style: const TextStyle(
                      color: Color(0xFF074D2C),
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty || name == '-') return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
