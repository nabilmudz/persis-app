import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../controller/pj_controller.dart';
import '../../controller/pj_laporan_controller.dart';
import '../../../data/models/transaction_model.dart';
import 'pj_recap_detail_view.dart';

class PjPaymentDataViewPage extends StatefulWidget {
  final PjController controller;

  const PjPaymentDataViewPage({super.key, required this.controller});

  @override
  State<PjPaymentDataViewPage> createState() => _PjPaymentDataViewPageState();
}

class _PjPaymentDataViewPageState extends State<PjPaymentDataViewPage> {
  DateTime _selectedMonth = DateTime.now();
  late final PjLaporanController _laporanController;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    widget.controller.addListener(_onControllerChanged);
    _laporanController = PjLaporanController();
    _laporanController.addListener(_onLaporanChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _laporanController.removeListener(_onLaporanChanged);
    _laporanController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onLaporanChanged() {
    if (mounted) {
      if (_laporanController.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_laporanController.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {});
    }
  }

  List<TransactionModel> _filterTransactionsByMonth(
    List<TransactionModel> transactions,
  ) {
    return transactions.where((transaction) {
      if (transaction.createdAt == null) return false;

      try {
        final transactionDate = DateTime.parse(transaction.createdAt!);
        final isSameMonth =
            transactionDate.year == _selectedMonth.year &&
            transactionDate.month == _selectedMonth.month;
        final isApproved =
            transaction.accStatus == 'approved' ||
            transaction.status == 'completed';

        return isSameMonth && isApproved;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<void> _selectMonth() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedMonth = pickedDate;
      });
    }
  }

  void _exportData() async {
    final filteredTransactions = _filterTransactionsByMonth(
      widget.controller.transactions,
    );

    if (filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk diekspor'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await _laporanController.exportLaporan(
      month: _selectedMonth.month,
      year: _selectedMonth.year,
    );

    if (mounted && _laporanController.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil diekspor'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatCurrency(int? amount) {
    if (amount == null) return 'Rp. 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _getMemberName(TransactionModel transaction) {
    // 1. Coba ambil langsung dari field memberName (member_name) hasil API
    if (transaction.memberName != null && transaction.memberName!.isNotEmpty) {
      return transaction.memberName!;
    }

    // 2. Fallback: Cari dari list members controller jika data item ada
    if (transaction.items == null || transaction.items!.isEmpty) return '-';
    final anggotaId = transaction.items!.first.anggotaId;
    if (anggotaId == null) return '-';

    try {
      final member = widget.controller.members.firstWhere(
        (m) => m.id == anggotaId,
      );
      return widget.controller.memberDisplayName(member);
    } catch (_) {
      return 'Member Tidak Dikenal';
    }
  }

  void _exportExcel() async {
    final filteredTransactions = _filterTransactionsByMonth(
      widget.controller.transactions,
    );

    if (filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk diekspor ke Excel'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // 1. Ambil data dari API Export (lebih lengkap, ada member_name)
      final result = await _laporanController.exportLaporan(
        month: _selectedMonth.month,
        year: _selectedMonth.year,
      );

      List<TransactionModel> exportData = [];
      if (result != null && result['data'] != null) {
        final List rawData = result['data'];
        exportData = rawData.map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } else {
        // Fallback ke data lokal jika API export gagal/tidak ada data
        exportData = filteredTransactions;
      }

      if (exportData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk periode ini')),
        );
        return;
      }

      // 2. Inisialisasi Excel
      final excel = Excel.createExcel();
      final sheet = excel['Laporan_Transaksi'];
      excel.delete('Sheet1');

      final headers = ['No', 'Kode', 'Tanggal', 'Nama Member', 'NPA', 'Jenis', 'Jumlah', 'Status', 'PJ (30%)', 'PC (20%)', 'PD (20%)', 'PW (15%)', 'PP (15%)'];
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // 3. Tambah Data
      for (int i = 0; i < exportData.length; i++) {
        final t = exportData[i];
        final amount = t.totalAmount ?? 0;
        final date = t.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(t.createdAt!)) : '-';
        
        // Ambil member name langsung dari model (hasil API mapping)
        final memberName = t.memberName ?? _getMemberName(t);
        
        // Cari NPA jika ada (dari JSON user ada field "npa")
        // Kita bisa ambil dari map asli jika perlu, tapi kita gunakan TransactionModel dulu
        // Untuk amannya, kita bisa parse manual map aslinya jika ingin field tambahan seperti NPA
        
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(t.code ?? t.id ?? "-"),
          TextCellValue(date),
          TextCellValue(memberName),
          TextCellValue(t.npa ?? "-"),
          TextCellValue(t.type ?? "Pembayaran Tunai"),
          IntCellValue(amount),
          TextCellValue(t.accStatus ?? t.status ?? "pending"),
          IntCellValue((amount * 30) ~/ 100),
          IntCellValue((amount * 20) ~/ 100),
          IntCellValue((amount * 20) ~/ 100),
          IntCellValue((amount * 15) ~/ 100),
          IntCellValue((amount * 15) ~/ 100),
        ]);
      }

      // 4. Simpan ke file .xlsx
      final bytes = excel.encode();
      if (bytes == null) return;

      final directory = await getTemporaryDirectory();
      final monthLabel = DateFormat('MMMM_yyyy', 'id_ID').format(_selectedMonth);
      final file = File('${directory.path}/Laporan_PJ_$monthLabel.xlsx');
      await file.writeAsBytes(bytes);

      // 5. Share file
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Laporan PJ $monthLabel',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat file Excel (.xlsx): $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filterTransactionsByMonth(
      widget.controller.transactions,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pembayaran'),
        elevation: 0,
        backgroundColor: const Color(0xFF073D4D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Overview Card Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildOverviewCard(filteredTransactions),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildDistributionCard(filteredTransactions),
            ),
            // Filter and Export Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF5F5F5),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectMonth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD0D0D0)),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat(
                                'MMMM yyyy',
                                'id_ID',
                              ).format(_selectedMonth),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF073D4D),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Color(0xFF073D4D),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _exportExcel,
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Excel (.xlsx)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6F42), // Excel color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (_laporanController.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF10B367),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Transactions List
            if (filteredTransactions.isEmpty)
              _buildEmptyState()
            else
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rincian Pembayaran',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF073D4D),
                        ),
                      ),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _groupTransactionsByType(filteredTransactions).keys.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final groupedData = _groupTransactionsByType(filteredTransactions);
                      final type = groupedData.keys.elementAt(index);
                      final transactions = groupedData[type]!;
                      
                      // Create a synthetic recap transaction
                      final totalAmount = transactions.fold<int>(0, (sum, t) => sum + (t.totalAmount ?? 0));
                      final latestTransaction = transactions.first; // Use first one for metadata
                      
                      final recapTransaction = TransactionModel(
                        type: type,
                        totalAmount: totalAmount,
                        code: 'REKAP-${type.toUpperCase()}',
                        createdAt: latestTransaction.createdAt,
                        accStatus: 'approved',
                        verifiedBy: 'Sistem',
                      );

                      return _PaymentDataCard(
                        transaction: recapTransaction,
                        isRecap: true,
                        memberName: '-',
                        onTap: (type.toLowerCase() == 'tunai' || 
                                transactions.any((t) => t.paymentMethodId == '69ee266797af79f7ef06e559'))
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PjRecapDetailViewPage(
                                      title: type,
                                      transactions: transactions,
                                      month: _selectedMonth.month,
                                      year: _selectedMonth.year,
                                      monthLabel: DateFormat('MMMM', 'id_ID').format(_selectedMonth),
                                      getMemberName: _getMemberName, // Pass helper
                                    ),
                                  ),
                                );
                              }
                            : null,
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: const Color(0xFF073D4D).withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Data Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF073D4D).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada pembayaran yang selesai pada bulan yang dipilih',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF4B5563).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(List<TransactionModel> transactions) {
    int totalAmount = 0;
    int totalIncome = 0;

    for (final transaction in transactions) {
      final amount = transaction.totalAmount ?? 0;
      totalAmount += amount;
      totalIncome += amount;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.03, 0.21),
          end: Alignment(1.55, 1.16),
          colors: [Color(0xFF10B367), Color(0xFF0C844C), Color(0xFF074D2C)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4C15803D),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0x77D9D9D9),
              borderRadius: BorderRadius.all(Radius.circular(80)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'TOTAL KAS PJ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(totalAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _OverviewStatItem(label: 'Total Dana Masuk', amount: totalIncome),
        ],
      ),
    );
  }

  Widget _buildDistributionItemWidget({
    required String label,
    required int percentage,
    required int amount,
    required Color color,
    required String Function(int) formatAmount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF073D4D),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              formatAmount(amount),
              style: const TextStyle(
                color: Color(0xFF073D4D),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionCard(List<TransactionModel> transactions) {
    int totalAmount = 0;
    for (final t in transactions) {
      totalAmount += t.totalAmount ?? 0;
    }

    String fmt(int amount) => NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

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
          const Text('Distribusi Iuran (%)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF073D4D))),
          const SizedBox(height: 14),
          _buildDistributionItemWidget(
              label: 'PJ (30%)', percentage: 30,
              amount: (totalAmount * 30) ~/ 100,
              color: const Color(0xFF10B367), formatAmount: fmt),
          const SizedBox(height: 10),
          _buildDistributionItemWidget(
              label: 'PC (20%)', percentage: 20,
              amount: (totalAmount * 20) ~/ 100,
              color: const Color(0xFF007AFF), formatAmount: fmt),
          const SizedBox(height: 10),
          _buildDistributionItemWidget(
              label: 'PD (20%)', percentage: 20,
              amount: (totalAmount * 20) ~/ 100,
              color: const Color(0xFFFFA500), formatAmount: fmt),
          const SizedBox(height: 10),
          _buildDistributionItemWidget(
              label: 'PW (15%)', percentage: 15,
              amount: (totalAmount * 15) ~/ 100,
              color: const Color(0xFF8B5CF6), formatAmount: fmt),
          const SizedBox(height: 10),
          _buildDistributionItemWidget(
              label: 'PP (15%)', percentage: 15,
              amount: (totalAmount * 15) ~/ 100,
              color: const Color(0xFFEC4899), formatAmount: fmt),
        ],
      ),
    );
  }

  Map<String, List<TransactionModel>> _groupTransactionsByType(
    List<TransactionModel> transactions,
  ) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in transactions) {
      String type = t.type ?? 'Lainnya';
      
      // Specifically handle the requested payment method ID
      if (t.paymentMethodId == '69ee266797af79f7ef06e559') {
        type = 'Pembayaran Tunai';
      }
      
      grouped.putIfAbsent(type, () => []).add(t);
    }
    return grouped;
  }
}

class _OverviewStatItem extends StatelessWidget {
  final String label;
  final int amount;

  const _OverviewStatItem({required this.label, required this.amount});

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDataCard extends StatelessWidget {
  final TransactionModel transaction;
  final String memberName;
  final VoidCallback? onTap;
  final bool isRecap;

  const _PaymentDataCard({
    required this.transaction,
    required this.memberName,
    this.onTap,
    this.isRecap = false,
  });

  Widget _buildPjDistribution() {
    final amount = transaction.totalAmount ?? 0;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('DISTRIBUSI PJ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.5)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
            child: const Text('PJ saja', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
          ),
        ]),
        const SizedBox(height: 8),
        _distRow('PJ (30%)', fmt.format((amount * 30) ~/ 100)),
        _distRow('PC (20%)', fmt.format((amount * 20) ~/ 100)),
        _distRow('PD (20%)', fmt.format((amount * 20) ~/ 100)),
        _distRow('PW (15%)', fmt.format((amount * 15) ~/ 100)),
        _distRow('PP (15%)', fmt.format((amount * 15) ~/ 100)),
      ],
    );
  }

  Widget _distRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF073D4D))),
      ],
    ),
  );

  String _formatCurrency(int? amount) {
    if (amount == null) return 'Rp. 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
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

  String _getPaymentTypeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'tunai':
        return 'Tunai';
      case 'non-tunai':
      case 'transfer':
        return 'Transfer Bank';
      case 'e-wallet':
        return 'E-Wallet';
      default:
        return type ?? 'Pembayaran';
    }
  }

  Color _getStatusColor(String? status) {
    if (isRecap) return const Color(0xFF10B367);
    switch (status?.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B367);
      case 'pending':
        return const Color(0xFFFFA500);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prefer API-provided member name when available
    final displayMemberName = (memberName.isNotEmpty && memberName != '-')
        ? memberName
        : (transaction.memberName ?? '-');
    return GestureDetector(
      onTap: onTap, // gunakan onTap di sini
      child: Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Type and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPaymentTypeLabel(transaction.type),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF073D4D),
                      ),
                    ),
                    if (!isRecap) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Nama: $displayMemberName',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B367),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Kode: ${((transaction.code != null && transaction.code!.isNotEmpty) ? transaction.code : (transaction.id != null && transaction.id!.isNotEmpty ? (transaction.id!.length > 8 ? transaction.id!.substring(transaction.id!.length - 8).toUpperCase() : transaction.id!.toUpperCase()) : '-'))}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    transaction.accStatus,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isRecap ? 'Group' : (transaction.accStatus ?? 'pending'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(transaction.accStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Amount
          Text(
            _formatCurrency(transaction.totalAmount),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF10B367),
            ),
          ),
          if (!isRecap) ...[
            const SizedBox(height: 12),
            // Date and Details Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF6B7280).withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(transaction.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF073D4D),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diverifikasi Oleh',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF6B7280).withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.verifiedBy ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF073D4D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            const SizedBox(height: 8),
          // Bank Info (if non-tunai)
          if (transaction.type?.toLowerCase() != 'tunai' &&
              (transaction.bankName != null ||
                  transaction.bankAccountName != null))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (transaction.bankName != null)
                        Text(
                          'Bank: ${transaction.bankName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      if (transaction.bankAccountName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Atas Nama: ${transaction.bankAccountName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Di bagian bawah build(), setelah bank info:
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E5E5)),
            const SizedBox(height: 10),
            _buildPjDistribution(),
        ],
      ),
    )
    );
  }
}
