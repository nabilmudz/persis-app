import 'package:flutter/material.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import '../../controller/pj_controller.dart';
import '../../controller/pj_verif_tunai_transaction_controller.dart';

class PjVerifTunaiViewPage extends StatefulWidget {
  final PjController controller;
  final UserModel member;

  const PjVerifTunaiViewPage({
    super.key,
    required this.controller,
    required this.member,
  });

  @override
  State<PjVerifTunaiViewPage> createState() => _PjVerifTunaiViewPageState();
}

class _PjVerifTunaiViewPageState extends State<PjVerifTunaiViewPage> {
  int _selectedYear = 2026;
  final Set<int> _selectedMonths = <int>{};
  late PjVerifTunaiTransactionController _transactionController;

  static const List<String> _monthNames = [
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
    _transactionController = PjVerifTunaiTransactionController();

    final userId = widget.member.id;
    if (userId != null && userId.isNotEmpty) {
      _transactionController.loadTransactions(userId);
    }
  }

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  void _handleMonthTap(int month) {
    final anggotaId = widget.member.id;
    if (anggotaId == null || anggotaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID anggota tidak tersedia.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      if (_selectedMonths.contains(month)) {
        _selectedMonths.remove(month);
      } else {
        _selectedMonths.add(month);
      }
    });
  }

  Future<void> _handleConfirmTransaction() async {
    final anggotaId = widget.member.id;
    if (anggotaId == null || anggotaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID anggota tidak tersedia.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu bulan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Membuat transaksi...',
                  style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final success = await _transactionController
          .createTransactionForSelectedMonths(
            anggotaId: anggotaId,
            memberId: widget.member.id ?? '',
            selectedMonths: _selectedMonths,
            year: _selectedYear,
            getNominal: (month, year) {
              return widget.controller.getNominalForMemberMonth(
                anggotaId: anggotaId,
                month: month,
                year: year,
              );
            },
          );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (success) {
        await widget.controller.loadInitialData();
        final refreshedUserId = widget.member.id;
        if (refreshedUserId != null && refreshedUserId.isNotEmpty) {
          await _transactionController.loadTransactions(refreshedUserId);
        }

        // Reset selected months
        setState(() {
          _selectedMonths.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dibuat'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF28A745),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _transactionController.errorMessage ?? 'Gagal membuat transaksi',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFFB31012),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFB31012),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final anggotaId = widget.member.id;
    final memberName = widget.controller.memberDisplayName(widget.member);
    final totalTunggakan = widget.controller.tunggakanNominalByMember(
      anggotaId ?? '',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Kartu Iuran',
          style: TextStyle(
            color: Color(0xFF073D4D),
            fontSize: 20,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD0D0D0)),
        ),
        actions: [],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          return ListenableBuilder(
            listenable: _transactionController,
            builder: (context, child) {
              if (_transactionController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName,
                      style: const TextStyle(
                        color: Color(0xFF073D4D),
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF2C8C8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Tunggakan',
                            style: TextStyle(
                              color: Color(0xFFA50A0C),
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatCurrency(totalTunggakan),
                            style: const TextStyle(
                              color: Color(0xFFB31012),
                              fontSize: 32,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        border: Border.all(color: const Color(0xFFB4B4B4)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          style: const TextStyle(
                            color: Color(0xFF6C6C6C),
                            fontSize: 18,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                          ),
                          items: const [2025, 2026, 2027]
                              .map(
                                (year) => DropdownMenuItem<int>(
                                  value: year,
                                  child: Text('$year'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedYear = value;
                              _selectedMonths.clear();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _monthNames.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.05,
                          ),
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final monthName = _monthNames[index];
                        final status = widget.controller.getMonthStatus(
                          anggotaId: anggotaId ?? '',
                          month: month,
                          year: _selectedYear,
                        );

                        return _MonthCard(
                          name: monthName,
                          status: status,
                          isSelected: _selectedMonths.contains(month),
                          onTap: () => _handleMonthTap(month),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_transactionController.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4F4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF2C8C8)),
                          ),
                          child: Text(
                            _transactionController.errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFB31012),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    if (_transactionController.uncompleted.isNotEmpty ||
                        _transactionController.completed.isNotEmpty ||
                        _transactionController.tunggakan.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daftar Transaksi',
                            style: TextStyle(
                              color: Color(0xFF073D4D),
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._transactionController.uncompleted.map((tx) {
                            final periodLabel = _transactionController
                                .getPeriodLabel(tx);
                            final amount = tx.items?.isNotEmpty == true
                                ? (tx.items!.first.amount ?? 0).toString()
                                : '0';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TransactionCard(
                                label: periodLabel,
                                status: 'uncompleted',
                                nominal: amount,
                              ),
                            );
                          }).toList(),
                          ..._transactionController.completed.map((tx) {
                            final periodLabel = _transactionController
                                .getPeriodLabel(tx);
                            final amount = tx.items?.isNotEmpty == true
                                ? (tx.items!.first.amount ?? 0).toString()
                                : '0';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TransactionCard(
                                label: periodLabel,
                                status: 'paid',
                                nominal: amount,
                              ),
                            );
                          }).toList(),
                          ..._transactionController.tunggakan.map((tx) {
                            final periodLabel = _transactionController
                                .getPeriodLabel(tx);
                            final amount = tx.items?.isNotEmpty == true
                                ? (tx.items!.first.amount ?? 0).toString()
                                : '0';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TransactionCard(
                                label: periodLabel,
                                status: 'tunggakan',
                                nominal: amount,
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleConfirmTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF073D4D),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Konfirmasi Pencatatan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.name,
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final PjMonthStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLunas = status == PjMonthStatus.lunas;
    final isTunggakan = status == PjMonthStatus.tunggakan;

    final Decoration decoration;
    final Color textColor;
    final IconData? iconData;

    if (isSelected) {
      decoration = BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFAFAFAF)),
      );
      textColor = Colors.white;
      iconData = Icons.check;
    } else if (isLunas) {
      decoration = BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF43F04E), Color(0xFF268A2D)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFAFAFAF)),
      );
      textColor = Colors.white;
      iconData = Icons.check_circle;
    } else if (isTunggakan) {
      decoration = BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF8A8A), Color(0xFFB31012)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFAFAFAF)),
      );
      textColor = Colors.white;
      iconData = Icons.warning_amber_rounded;
    } else {
      decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFAFAFAF)),
      );
      textColor = const Color(0xFF7D7D7D);
      iconData = null;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Ink(
          decoration: decoration,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (iconData != null) ...[
                const SizedBox(height: 8),
                Icon(iconData, color: Colors.white, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final String label;
  final String status;
  final String nominal;

  const _TransactionCard({
    required this.label,
    required this.status,
    required this.nominal,
  });

  @override
  Widget build(BuildContext context) {
    late Color backgroundColor;
    late Color borderColor;
    late Color textColor;
    bool isClickable = true;

    if (status == 'paid') {
      backgroundColor = const Color(0xFFD4EDDA);
      borderColor = const Color(0xFF28A745);
      textColor = const Color(0xFF155724);
      isClickable = false;
    } else if (status == 'tunggakan') {
      backgroundColor = const Color(0xFFFFF4F4);
      borderColor = const Color(0xFFF2C8C8);
      textColor = const Color(0xFFA50A0C);
    } else {
      backgroundColor = const Color(0xFFF8F9FA);
      borderColor = const Color(0xFFDEE2E6);
      textColor = const Color(0xFF6C757D);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp. $nominal',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status == 'paid'
                  ? 'Lunas'
                  : status == 'tunggakan'
                  ? 'Tunggakan'
                  : 'Belum Bayar',
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isClickable)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.lock, size: 18, color: Color(0xFF28A745)),
            ),
        ],
      ),
    );
  }
}
