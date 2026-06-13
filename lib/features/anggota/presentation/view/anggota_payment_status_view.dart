import 'package:flutter/material.dart';
import 'package:persis_app/features/anggota/presentation/controller/anggota_transaction_controller.dart';

class AnggotaPaymentStatusView extends StatefulWidget {
  const AnggotaPaymentStatusView({super.key});

  @override
  State<AnggotaPaymentStatusView> createState() =>
      _AnggotaPaymentStatusViewState();
}

class _AnggotaPaymentStatusViewState extends State<AnggotaPaymentStatusView> {
  late final AnggotaTransactionController _controller;
  int _selectedYear = DateTime.now().year;

  static const _monthHeaders = [
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

  @override
  void initState() {
    super.initState();
    _controller = AnggotaTransactionController();
    _controller.fetchPaymentStatus(year: _selectedYear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<int> _availableYears() {
    final currentYear = DateTime.now().year;
    return List.generate(5, (i) => currentYear - i);
  }

  Color _cellBackground(String status) {
    switch (status) {
      case 'paid':
      case 'completed':
      case 'lunas':
        return const Color(0xFFD4EDDA);
      case 'partial':
        return const Color(0xFFFFF3CD);
      case 'unpaid':
        return const Color(0xFFF8D7DA);
      default:
        return const Color(0xFFEDEDED);
    }
  }

  Color _cellTextColor(String status) {
    switch (status) {
      case 'paid':
      case 'completed':
      case 'lunas':
        return const Color(0xFF155724);
      case 'partial':
        return const Color(0xFF856404);
      case 'unpaid':
        return const Color(0xFF721C24);
      default:
        return const Color(0xFF6A6A6A);
    }
  }

  String _cellLabel(String status) {
    switch (status) {
      case 'paid':
      case 'completed':
      case 'lunas':
        return '✓';
      case 'partial':
        return '~';
      case 'unpaid':
        return '✗';
      default:
        return '-';
    }
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
          'Status Pembayaran',
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
          if (_controller.isLoadingStatus) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.statusError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _controller.statusError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          _controller.fetchPaymentStatus(year: _selectedYear),
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
                ),
              ),
            );
          }

          final members = _controller.members;

          return RefreshIndicator(
            color: const Color(0xFF189D4A),
            onRefresh: () =>
                _controller.fetchPaymentStatus(year: _selectedYear),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Text(
                        'Tahun:',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: _selectedYear,
                        items: _availableYears().map((y) {
                          return DropdownMenuItem<int>(
                            value: y,
                            child: Text(
                              '$y',
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedYear = val);
                            _controller.fetchPaymentStatus(year: val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _LegendChip(
                        color: const Color(0xFFD4EDDA),
                        textColor: const Color(0xFF155724),
                        label: 'Lunas',
                      ),
                      const SizedBox(width: 12),
                      _LegendChip(
                        color: const Color(0xFFFFF3CD),
                        textColor: const Color(0xFF856404),
                        label: 'Sebagian',
                      ),
                      const SizedBox(width: 12),
                      _LegendChip(
                        color: const Color(0xFFF8D7DA),
                        textColor: const Color(0xFF721C24),
                        label: 'Belum',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                Expanded(
                  child: members.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada data anggota.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFF8F9FA),
                              ),
                              columnSpacing: 8,
                              headingTextStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Color(0xFF363636),
                              ),
                              dataTextStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Color(0xFF363636),
                              ),
                              columns: [
                                const DataColumn(label: Text('Nama')),
                                ..._monthHeaders.map(
                                  (m) => DataColumn(label: Text(m)),
                                ),
                              ],
                              rows: members.map((member) {
                                final memberId =
                                    (member['_id'] ?? member['id'])
                                        ?.toString() ??
                                    '';
                                final name =
                                    (member['fullname'] ??
                                            member['name'] ??
                                            '-')
                                        .toString();

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 140,
                                        ),
                                        child: Text(
                                          name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    ...List.generate(12, (monthIdx) {
                                      final month = monthIdx + 1;
                                      final status = _controller
                                          .paymentStatusFor(memberId, month);
                                      return DataCell(
                                        Center(
                                          child: Container(
                                            width: 32,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: _cellBackground(status),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _cellLabel(status),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: _cellTextColor(status),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }).toList(),
                            ),
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

class _LegendChip extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String label;

  const _LegendChip({
    required this.color,
    required this.textColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
