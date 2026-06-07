import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../controller/pc_controller.dart';
import '../controller/pc_laporan_controller.dart';
import '../../../BendaharaPJ/data/models/transaction_model.dart';
import 'pc_recap_detail_view.dart';

class PcLaporanViewPage extends StatefulWidget {
  final PcController controller;

  const PcLaporanViewPage({super.key, required this.controller});

  @override
  State<PcLaporanViewPage> createState() => _PcLaporanViewPageState();
}

class _PcLaporanViewPageState extends State<PcLaporanViewPage> {
  DateTime _selectedMonth = DateTime.now();
  late final PcLaporanController _laporanController;
  List<TransactionModel> _monthlyTransactions = [];
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    widget.controller.addListener(_onControllerChanged);
    _laporanController = PcLaporanController();
    _laporanController.addListener(_onLaporanChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMonthlyData();
    });
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

  Future<void> _fetchMonthlyData() async {
    setState(() {
      _isInitialLoading = _monthlyTransactions.isEmpty;
    });

    try {
      final result = await _laporanController.exportLaporan(
        month: _selectedMonth.month,
        year: _selectedMonth.year,
      );

      if (result != null && result['data'] != null) {
        final List rawData = result['data'];
        if (mounted) {
          setState(() {
            _monthlyTransactions = rawData
                .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
                .map((t) {
                  // Hitung ulang amount hanya untuk bulan yang dipilih
                  final monthAmount = _calculateAmountForMonth(
                    t,
                    _selectedMonth.month,
                    _selectedMonth.year,
                  );
                  return t.copyWith(totalAmount: monthAmount);
                })
                .toList();
            _isInitialLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('⚠ API Error: $e. Using local fallback.');
    }

    if (mounted) {
      final List<TransactionModel> localTransactions = [];
      for (final t in widget.controller.allTransactions) {
        final items = t.items ?? [];
        if (items.isNotEmpty) {
          for (final item in items) {
            final periodStr = item.periodId ?? '';
            final parts = periodStr.split('-');
            bool matches = false;
            if (parts.length >= 2) {
              final y = int.tryParse(parts[0]);
              final m = int.tryParse(parts[1]);
              if (y == _selectedMonth.year && m == _selectedMonth.month) {
                matches = true;
              }
            } else {
              if (t.createdAt != null) {
                try {
                  final date = DateTime.parse(t.createdAt!);
                  if (date.year == _selectedMonth.year && date.month == _selectedMonth.month) {
                    matches = true;
                  }
                } catch (_) {}
              }
            }

            if (matches) {
              localTransactions.add(t.copyWith(
                totalAmount: item.amount ?? 20000,
              ));
            }
          }
        } else {
          if (t.createdAt != null) {
            try {
              final date = DateTime.parse(t.createdAt!);
              if (date.year == _selectedMonth.year && date.month == _selectedMonth.month) {
                localTransactions.add(t.copyWith(
                  totalAmount: 20000,
                ));
              }
            } catch (_) {}
          }
        }
      }

      setState(() {
        _monthlyTransactions = localTransactions;
        _isInitialLoading = false;
      });

      if (_laporanController.errorMessage != null || _monthlyTransactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Koneksi server terputus. Menampilkan data lokal (mungkin tidak lengkap).'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<TransactionModel> _filterTransactionsByMonth(List<TransactionModel> transactions) {
    return transactions.where((transaction) {
      final isApproved = (transaction.accStatus == 'acc_pj' || transaction.accStatus == 'approved') ||
          transaction.status == 'completed';
      return isApproved;
    }).toList();
  }

  Future<void> _selectMonth() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'PILIH BULAN LAPORAN',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedMonth = pickedDate;
      });
      _fetchMonthlyData();
    }
  }

  String _formatCurrency(int? amount) {
    if (amount == null) return 'Rp 0';
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  /// Menghitung total amount untuk bulan tertentu dari items transaksi.
  /// Jika transaksi memiliki items dengan periodId, hitung hanya item yang
  /// periodenya sesuai bulan/tahun yang dipilih. Jika tidak ada items atau
  /// tidak ada yang match, gunakan totalAmount asli (sudah difilter API).
  int _calculateAmountForMonth(TransactionModel t, int month, int year) {
    final items = t.items ?? [];
    if (items.isEmpty) return t.totalAmount ?? 0;

    int matchedAmount = 0;
    bool anyMatched = false;
    for (final item in items) {
      final periodStr = item.periodId ?? '';
      final parts = periodStr.split('-');
      bool matches = false;
      if (parts.length >= 2) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y == year && m == month) matches = true;
      }
      if (matches) {
        matchedAmount += item.amount ?? 0;
        anyMatched = true;
      }
    }
    // Jika tidak ada item yang match period, kembalikan totalAmount asli
    return anyMatched ? matchedAmount : (t.totalAmount ?? 0);
  }

  String _getMemberName(TransactionModel transaction) {
    if (transaction.memberName != null && transaction.memberName!.isNotEmpty) {
      return transaction.memberName!;
    }
    return transaction.creatorId ?? 'Member';
  }

  void _exportExcel() async {
    try {
      final result = await _laporanController.exportLaporan(
        month: _selectedMonth.month,
        year: _selectedMonth.year,
      );

      if (_laporanController.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_laporanController.errorMessage!), backgroundColor: Colors.red),
          );
        }
        return;
      }

      List<TransactionModel> exportData = [];
      if (result != null && result['data'] != null) {
        final List rawData = result['data'];
        exportData = rawData
            .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
            .map((t) {
              // Hitung ulang amount hanya untuk bulan yang dipilih
              final monthAmount = _calculateAmountForMonth(
                t,
                _selectedMonth.month,
                _selectedMonth.year,
              );
              return t.copyWith(totalAmount: monthAmount);
            })
            .toList();
      } else {
        final List<TransactionModel> fallbackList = [];
        for (final t in widget.controller.allTransactions) {
          final items = t.items ?? [];
          if (items.isNotEmpty) {
            for (final item in items) {
              final periodStr = item.periodId ?? '';
              final parts = periodStr.split('-');
              bool matches = false;
              if (parts.length >= 2) {
                final y = int.tryParse(parts[0]);
                final m = int.tryParse(parts[1]);
                if (y == _selectedMonth.year && m == _selectedMonth.month) {
                  matches = true;
                }
              } else {
                if (t.createdAt != null) {
                  try {
                    final date = DateTime.parse(t.createdAt!);
                    if (date.year == _selectedMonth.year && date.month == _selectedMonth.month) {
                      matches = true;
                    }
                  } catch (_) {}
                }
              }

              if (matches) {
                fallbackList.add(t.copyWith(
                  totalAmount: item.amount ?? 20000,
                ));
              }
            }
          } else {
            if (t.createdAt != null) {
              try {
                final date = DateTime.parse(t.createdAt!);
                if (date.year == _selectedMonth.year && date.month == _selectedMonth.month) {
                  fallbackList.add(t.copyWith(
                    totalAmount: 20000,
                  ));
                }
              } catch (_) {}
            }
          }
        }
        exportData = fallbackList;
      }

      if (exportData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada transaksi untuk periode ini'), duration: Duration(seconds: 2)),
          );
        }
        return;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Transaksi pada Bulan'];
      excel.delete('Sheet1');

      final headers = ['Hari, Tanggal', 'Nama Anggota', 'Dari Bulan', 'Hingga Bulan', 'Total Bayar', 'Di ACC oleh', 'PJ', 'PC', 'PW', 'PD', 'PP'];
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      final monthLabel = DateFormat('MMMM', 'id_ID').format(_selectedMonth);

      for (int i = 0; i < exportData.length; i++) {
        final t = exportData[i];
        final amount = t.totalAmount ?? 0;
        final dateFormatted = t.createdAt != null
            ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(DateTime.parse(t.createdAt!))
            : '-';
        final memberName = t.memberName ?? _getMemberName(t);
        final pj = (amount * 30) ~/ 100;
        final pc = (amount * 20) ~/ 100;
        final pw = (amount * 15) ~/ 100;
        final pd = (amount * 20) ~/ 100;
        final pp = (amount * 15) ~/ 100;

        sheet.appendRow([
          TextCellValue(dateFormatted),
          TextCellValue(memberName),
          TextCellValue(monthLabel),
          TextCellValue(monthLabel),
          IntCellValue(amount),
          TextCellValue(t.verifiedBy ?? '-'),
          IntCellValue(pj),
          IntCellValue(pc),
          IntCellValue(pw),
          IntCellValue(pd),
          IntCellValue(pp),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) return;

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/Laporan_PC_$monthLabel.xlsx');
      await file.writeAsBytes(bytes);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Laporan PC $monthLabel telah dibuat',
          subject: 'Laporan PC $monthLabel',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat file Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filterTransactionsByMonth(_monthlyTransactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Pembayaran',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF074D2C),
        foregroundColor: Colors.white,
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0C844C)))
          : RefreshIndicator(
              onRefresh: _fetchMonthlyData,
              color: const Color(0xFF0C844C),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _buildOverviewCard(filteredTransactions),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _buildDistributionCard(filteredTransactions),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: const Color(0xFFF5F5F5),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectMonth,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFD0D0D0)),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF073D4D),
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF073D4D)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _exportExcel,
                            icon: const Icon(Icons.table_chart),
                            label: const Text('Excel (.xlsx)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E6F42),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C844C)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (filteredTransactions.isEmpty)
                      _buildEmptyState()
                    else
                      Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Rincian Pembayaran',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF073D4D),
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

                              final totalAmount = transactions.fold<int>(0, (sum, t) => sum + (t.totalAmount ?? 0));
                              final latestTransaction = transactions.first;

                              final recapTransaction = TransactionModel(
                                type: type,
                                totalAmount: totalAmount,
                                code: 'REKAP-${type.toUpperCase()}',
                                createdAt: latestTransaction.createdAt,
                                accStatus: 'acc_pc',
                                verifiedBy: 'Sistem',
                              );

                              return _PaymentDataCard(
                                transaction: recapTransaction,
                                isRecap: true,
                                memberName: '-',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PcRecapDetailViewPage(
                                        title: type,
                                        transactions: transactions,
                                        monthLabel: DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
                                        getMemberName: _getMemberName,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
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
            Icon(Icons.receipt_long_outlined, size: 64, color: const Color(0xFF073D4D).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Data Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF073D4D).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada pembayaran yang selesai pada bulan yang dipilih',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF4B5563).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overview Card: gradient seperti PJ ──
  Widget _buildOverviewCard(List<TransactionModel> transactions) {
    final totalAmount = transactions.fold<int>(0, (sum, t) => sum + (t.totalAmount ?? 0));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.03, 0.21),
          end: Alignment(1.55, 1.16),
          colors: [Color(0xFF4CAF50), Color(0xFF0C844C), Color(0xFF074D2C)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Color(0x4C15803D), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0x77D9D9D9),
              borderRadius: BorderRadius.all(Radius.circular(80)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'TOTAL KAS PC',
                style: TextStyle(
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
          _OverviewStatItem(label: 'Total Dana Masuk', amount: totalAmount),
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
            Text(label, style: const TextStyle(color: Color(0xFF073D4D), fontSize: 11, fontWeight: FontWeight.w600)),
            Text(formatAmount(amount), style: const TextStyle(color: Color(0xFF073D4D), fontSize: 11, fontWeight: FontWeight.w600)),
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
    final totalAmount = transactions.fold<int>(0, (sum, t) => sum + (t.totalAmount ?? 0));
    String fmt(int amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

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
          const Text('Distribusi Iuran (%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF073D4D))),
          const SizedBox(height: 14),
          _buildDistributionItemWidget(label: 'PJ (30%)', percentage: 30, amount: (totalAmount * 30) ~/ 100, color: const Color(0xFF10B367), formatAmount: fmt),
          const SizedBox(height: 10),
          _buildDistributionItemWidget(label: 'PC (20%)', percentage: 20, amount: (totalAmount * 20) ~/ 100, color: const Color(0xFF007AFF), formatAmount: fmt),
          const SizedBox(height: 10),
          _buildDistributionItemWidget(label: 'PD (20%)', percentage: 20, amount: (totalAmount * 20) ~/ 100, color: const Color(0xFFFFA500), formatAmount: fmt),
          const SizedBox(height: 10),
          _buildDistributionItemWidget(label: 'PW (15%)', percentage: 15, amount: (totalAmount * 15) ~/ 100, color: const Color(0xFF8B5CF6), formatAmount: fmt),
          const SizedBox(height: 10),
          _buildDistributionItemWidget(label: 'PP (15%)', percentage: 15, amount: (totalAmount * 15) ~/ 100, color: const Color(0xFFEC4899), formatAmount: fmt),
        ],
      ),
    );
  }

  Map<String, List<TransactionModel>> _groupTransactionsByType(List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in transactions) {
      String type = t.type ?? 'Tunai';
      if (t.paymentMethodId == '69ee266797af79f7ef06e559' || type.toLowerCase() == 'tunai') type = 'Rekap Tunai';
      grouped.putIfAbsent(type, () => []).add(t);
    }
    return grouped;
  }
}

// ── Overview Stat Item ──
class _OverviewStatItem extends StatelessWidget {
  final String label;
  final int amount;

  const _OverviewStatItem({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Payment Data Card: distribusi lengkap seperti PJ ──
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

  String _formatCurrency(int? amount) {
    if (amount == null) return 'Rp 0';
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
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
      case 'rekap tunai':
        return 'Rekap Tunai';
      case 'non-tunai':
      case 'transfer':
        return 'Transfer Bank';
      case 'e-wallet':
        return 'E-Wallet';
      default:
        return type ?? 'Pembayaran';
    }
  }

  Color _getStatusColor() {
    if (isRecap) return const Color(0xFF0C844C);
    if (transaction.accStatus == 'acc_pj' || transaction.accStatus == 'acc_pc' || transaction.accStatus == 'approved') {
      return const Color(0xFF0C844C);
    } else if (transaction.accStatus == 'rejected') {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFFFFA500);
  }

  Widget _buildDistribution() {
    final amount = transaction.totalAmount ?? 0;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'DISTRIBUSI',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.5),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(4)),
              child: const Text(
                'PC saja',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1976D2)),
              ),
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final amount = transaction.totalAmount ?? 0;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final displayMemberName = (memberName.isNotEmpty && memberName != '-')
        ? memberName
        : (transaction.memberName ?? '-');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPaymentTypeLabel(transaction.type),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF073D4D)),
                      ),
                      if (!isRecap) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Nama: $displayMemberName',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0C844C)),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Kode: ${(transaction.code != null && transaction.code!.isNotEmpty) ? transaction.code : (transaction.id != null && transaction.id!.isNotEmpty ? (transaction.id!.length > 8 ? transaction.id!.substring(transaction.id!.length - 8).toUpperCase() : transaction.id!.toUpperCase()) : '-')}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isRecap ? 'Group' : (transaction.accStatus == 'acc_pj' || transaction.accStatus == 'acc_pc' || transaction.accStatus == 'approved' ? 'approved' : 'pending'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getStatusColor()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              fmt.format(amount),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0C844C)),
            ),
            if (!isRecap) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tanggal', style: TextStyle(fontSize: 12, color: const Color(0xFF6B7280).withValues(alpha: 0.7))),
                        const SizedBox(height: 4),
                        Text(_formatDate(transaction.createdAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF073D4D))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Diverifikasi Oleh', style: TextStyle(fontSize: 12, color: const Color(0xFF6B7280).withValues(alpha: 0.7))),
                        const SizedBox(height: 4),
                        Text(
                          transaction.verifiedBy ?? '-',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF073D4D)),
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
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E5E5)),
            const SizedBox(height: 10),
            _buildDistribution(),
          ],
        ),
      ),
    );
  }
}
