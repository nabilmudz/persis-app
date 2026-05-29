import 'package:flutter/material.dart';
import 'package:persis_app/app/routes.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_controller.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_invoice_controller.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_transaction_item_controller.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_verif_tunai_transaction_controller.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/tunai/pending_transaction_view.dart';
import 'package:persis_app/helpers/auth_helper.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/pj_invoice.view.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/widgets/sweet_alert_dialog.dart';

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
  late PjTransactionItemController _itemController;

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
    _itemController = PjTransactionItemController();

    final userId = widget.member.id;
    if (userId != null && userId.isNotEmpty) {
      _transactionController.loadTransactions(userId);
      _itemController.loadByUser(userId, year: _selectedYear);
    }
  }

  @override
  void dispose() {
    _transactionController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  void _handleMonthTap(int month) {
    final status = _itemController.getMonthStatus(month, _selectedYear);
    if (status == PjMonthStatus.paid) {
      return;
    }

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

    if (_selectedMonths.contains(month)) {
      bool hasLaterSelected = _selectedMonths.any((m) => m > month);
      if (hasLaterSelected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membatalkan pilihan bulan ini karena bulan setelahnya masih terpilih.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() {
        _selectedMonths.remove(month);
      });
    } else {
      bool isDisabled = false;
      for (int i = 1; i < month; i++) {
        final s = _itemController.getMonthStatus(i, _selectedYear);
        if (s != PjMonthStatus.paid && !_selectedMonths.contains(i)) {
          isDisabled = true;
          break;
        }
      }
      if (isDisabled) return;

      setState(() {
        _selectedMonths.add(month);
      });
    }
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

    double totalAmount = 0;
    for (final m in _selectedMonths) {
      final cachedAmount = _itemController.getMonthAmount(m, _selectedYear);
      if (cachedAmount > 0) {
        totalAmount += cachedAmount;
      } else {
        totalAmount += widget.controller.getNominalForMemberMonth(
          anggotaId: anggotaId,
          month: m,
          year: _selectedYear,
        );
      }
    }

    final formattedTotal = _formatCurrency(totalAmount);
    final sortedMonths = _selectedMonths.toList()..sort();
    final monthLabels = sortedMonths.map((m) => _monthNames[m - 1]).join(', ');
    final memberName = widget.controller.memberDisplayName(widget.member);

    final shouldProceed = await SweetAlertDialog.showConfirmation(
      context: context,
      title: 'Konfirmasi Pembayaran',
      message: 'Apakah anda yakin membayar bulan $monthLabels sebesar $formattedTotal untuk anggota $memberName?',
      confirmText: 'Ya, Bayar',
      cancelText: 'Batal',
    );

    if (!shouldProceed) return;
    if (!mounted) return;

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
                  'Memproses pembayaran...',
                  style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final currentUserId = await AuthHelper.getUserId();

      final invoiceResult = await _transactionController
          .createTransactionForSelectedMonths(
            anggotaId: anggotaId,
            memberId: widget.member.id ?? '',
            accById: currentUserId,
            selectedMonths: _selectedMonths,
            year: _selectedYear,
            getNominal: (month, year) {
              final cachedAmount = _itemController.getMonthAmount(month, year);
              if (cachedAmount > 0) {
                return cachedAmount.toDouble();
              }

              return widget.controller.getNominalForMemberMonth(
                anggotaId: anggotaId,
                month: month,
                year: year,
              );
            },
            getPeriodId: (month, year) {
              return _itemController.getMonthPeriodId(month, year);
            },
          );

      if (invoiceResult != null) {
        await _itemController.markMonthsPaidLocally(
          anggotaId: anggotaId,
          months: invoiceResult.selectedMonths,
          year: invoiceResult.year,
          getNominal: (month, year) {
            final cachedAmount = _itemController.getMonthAmount(month, year);
            if (cachedAmount > 0) {
              return cachedAmount;
            }

            return widget.controller
                .getNominalForMemberMonth(
                  anggotaId: anggotaId,
                  month: month,
                  year: year,
                )
                .round();
          },
          getPeriodId: (month, year) {
            return _itemController.getMonthPeriodId(month, year) ??
                PjTransactionItemController.localPeriodKey(month, year);
          },
        );

        // Tambahkan transaksi ke controller agar card "Invoice Terakhir"
        // langsung update tanpa menunggu loadInitialData selesai.
        widget.controller.addTransaction(invoiceResult.transaction);

        await widget.controller.loadInitialData();
        final refreshedUserId = widget.member.id;
        if (refreshedUserId != null && refreshedUserId.isNotEmpty) {
          await _transactionController.loadTransactions(refreshedUserId);
          await _itemController.loadByUser(
            refreshedUserId,
            year: _selectedYear,
          );
        }

        UserModel completeMember = widget.member;
        if ((completeMember.noHp == null || completeMember.noHp!.isEmpty) &&
            completeMember.id != null) {
          try {
            final userRemote = UserRemoteDataSource(ApiClient.baseUrl);
            final fetchedUser = await userRemote.getOneUsers(
              completeMember.id!,
            );
            if (fetchedUser.noHp != null && fetchedUser.noHp!.isNotEmpty) {
              completeMember = fetchedUser;
            }
          } catch (_) {}
        }

        final invoiceData = PjInvoiceData.fromCreationResult(
          member: completeMember,
          result: invoiceResult,
          accByName: widget.controller.lookupMemberName(invoiceResult.transaction.accBy ?? invoiceResult.transaction.verifiedBy),
        );

        setState(() {
          _selectedMonths.clear();
        });

        if (!mounted) return;
        Navigator.pop(context);

        if (!invoiceResult.syncedToBackend) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PendingTransactionViewPage(
                controller: widget.controller,
                lastInvoiceData: invoiceData,
              ),
            ),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PjInvoiceViewPage(invoiceData: invoiceData),
            ),
          );
        }
      } else {
        if (!mounted) return;
        Navigator.pop(context);
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
      Navigator.pop(context);

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
    final memberName = widget.controller.memberDisplayName(widget.member);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFF073D4D)),
            tooltip: 'Pending Transaction',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PendingTransactionViewPage(controller: widget.controller),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          return ListenableBuilder(
            listenable: _itemController,
            builder: (context, child) {
              return ListenableBuilder(
                listenable: _transactionController,
                builder: (context, child) {
                  final anggotaId = widget.member.id ?? '';
                  final totalTunggakan = anggotaId.isEmpty
                      ? 0.0
                      : _itemController.totalTunggakan.toDouble();

                  if (_transactionController.isLoading ||
                      _itemController.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  bool isAllPaid = true;
                  for (int i = 1; i <= 12; i++) {
                    if (_itemController.getMonthStatus(i, _selectedYear) != PjMonthStatus.paid) {
                      isAllPaid = false;
                      break;
                    }
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
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
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
                                final userId = widget.member.id;
                                if (userId != null && userId.isNotEmpty) {
                                  widget.controller
                                      .loadPaymentStatusSnapshot(year: value)
                                      .then((_) {
                                        if (!mounted) return;
                                        _itemController.loadByUser(
                                          userId,
                                          year: value,
                                        );
                                      });
                                }
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
                            final status = _itemController.getMonthStatus(
                              month,
                              _selectedYear,
                            );

                            bool isDisabled = false;
                            for (int i = 1; i < month; i++) {
                              final s = _itemController.getMonthStatus(i, _selectedYear);
                              if (s != PjMonthStatus.paid && !_selectedMonths.contains(i)) {
                                isDisabled = true;
                                break;
                              }
                            }

                            return _MonthCard(
                              name: monthName,
                              status: status,
                              isSelected: _selectedMonths.contains(month),
                              isDisabled: isDisabled,
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
                                border: Border.all(
                                  color: const Color(0xFFF2C8C8),
                                ),
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

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isAllPaid ? null : _handleConfirmTransaction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF073D4D),
                              disabledBackgroundColor: const Color(0xFFEBEBEB),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              isAllPaid ? 'Pembayaran sudah lunas' : 'Konfirmasi Pembayaran',
                              style: TextStyle(
                                color: isAllPaid ? const Color(0xFFA1A1A1) : Colors.white,
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
          );
        },
      ),
      bottomNavigationBar: const RoleBottomNavigationBar(
        currentRoute: AppRoutes.bendaharaPJ,
        homeRoute: AppRoutes.bendaharaPJ,
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
    required this.isDisabled,
    required this.onTap,
  });

  final String name;
  final PjMonthStatus status;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLunas = status == PjMonthStatus.paid;
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
    } else if (isDisabled) {
      decoration = BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6D6D6)),
      );
      textColor = const Color(0xFFA1A1A1);
      iconData = Icons.lock_outline;
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
        onTap: (isLunas || isDisabled) ? null : onTap,
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
                Icon(iconData, color: isDisabled ? const Color(0xFFA1A1A1) : Colors.white, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
