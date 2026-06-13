import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:persis_app/app/routes.dart';
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/helpers/auth_helper.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';
import 'package:persis_app/features/anggota/data/datasources/payment_remote_datasource.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/anggota/presentation/view/riwayat_view.dart';

import '../controller/pembayaran_controller.dart';

class KartuIuranView extends StatefulWidget {
  const KartuIuranView({super.key});

  @override
  State<KartuIuranView> createState() => _KartuIuranViewState();
}

class _KartuIuranViewState extends State<KartuIuranView> {
  late final PembayaranController _controller;
  final ImagePicker _picker = ImagePicker();
  String _selfUserId = '';

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
    _controller = PembayaranController(
      remoteDataSource: PaymentRemoteDataSource(AppConfig.baseUrl),
      userRemoteDataSource: UserRemoteDataSource(AppConfig.baseUrl),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLoad();
    });
  }

  Future<void> _initLoad() async {
    final userId = await AuthHelper.getUserId();
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID anggota tidak tersedia.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    _selfUserId = userId;
    await _controller.loadSelfTransactionItems(
      userId,
      year: _controller.selectedYear,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleMonthTap(int month) {
    final status = _controller.getMonthStatus(month);
    if (status == AnggotaMonthStatus.paid) return;

    if (_controller.selectedMonths.contains(month)) {
      bool hasLaterSelected = _controller.selectedMonths.any((m) => m > month);
      if (hasLaterSelected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak dapat membatalkan pilihan bulan ini karena bulan setelahnya masih terpilih.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else {
      bool isDisabled = false;
      for (int i = 1; i < month; i++) {
        final s = _controller.getMonthStatus(i);
        if (s != AnggotaMonthStatus.paid &&
            !_controller.selectedMonths.contains(i)) {
          isDisabled = true;
          break;
        }
      }
      if (isDisabled) return;
    }

    setState(() {
      _controller.handleMonthTap(month);
    });
  }

  void _handleYearChange(int year) {
    setState(() {
      _controller.setSelectedYear(year);
    });
    if (_selfUserId.isNotEmpty) {
      _controller.loadSelfTransactionItems(_selfUserId, year: year);
    }
  }

  Future<void> _handleKonfirmasi() async {
    if (_controller.selectedMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu bulan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final sorted = _controller.selectedMonths.toList()..sort();
    final monthLabels = sorted.map((m) => _monthNames[m - 1]).join(', ');
    final formattedTotal = _controller.formatCurrency(_controller.totalTagihan);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          _KonfirmasiDialog(monthLabels: monthLabels, total: formattedTotal),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final method = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _PaymentMethodPickerDialog(),
    );

    if (method == null || !mounted) return;

    _controller.selectPaymentMethod(method);
    await _controller.fetchBankAccounts();
    if (!mounted) return;
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PaymentDetailsPopup(
        controller: _controller,
        selfUserId: _selfUserId,
        picker: _picker,
      ),
    );

    if (success == true && mounted) {
      _controller.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti pembayaran berhasil dikirim!'),
          backgroundColor: Color(0xFF10B367),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RiwayatView()),
      );
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
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoadingItems) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalTunggakan = _controller.totalTunggakan;

          bool isAllPaid = true;
          for (int i = 1; i <= 12; i++) {
            if (_controller.getMonthStatus(i) != AnggotaMonthStatus.paid) {
              isAllPaid = false;
              break;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (totalTunggakan > 0)
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
                          _controller.formatCurrency(totalTunggakan),
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
                if (totalTunggakan > 0) const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    border: Border.all(color: const Color(0xFFB4B4B4)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _controller.selectedYear,
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
                        if (value != null) _handleYearChange(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _monthNames.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final monthName = _monthNames[index];
                    final status = _controller.getMonthStatus(month);

                    bool isDisabled = false;
                    for (int i = 1; i < month; i++) {
                      final s = _controller.getMonthStatus(i);
                      if (s != AnggotaMonthStatus.paid &&
                          !_controller.selectedMonths.contains(i)) {
                        isDisabled = true;
                        break;
                      }
                    }

                    return _MonthCard(
                      name: monthName,
                      status: status,
                      isSelected: _controller.selectedMonths.contains(month),
                      isDisabled: isDisabled,
                      onTap: () => _handleMonthTap(month),
                    );
                  },
                ),
                const SizedBox(height: 20),

                if (_controller.selectedMonths.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF074D2C), Color(0xFF10B367)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _controller.formatCurrency(_controller.totalTagihan),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _controller.selectedMonthsLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isAllPaid ? null : _handleKonfirmasi,
                    icon: Icon(
                      isAllPaid
                          ? Icons.check_circle_outline
                          : Icons.receipt_long_rounded,
                    ),
                    label: Text(
                      isAllPaid
                          ? 'Pembayaran sudah lunas'
                          : 'Konfirmasi Pembayaran',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF073D4D),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFEBEBEB),
                      disabledForegroundColor: const Color(0xFFA1A1A1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const RoleBottomNavigationBar(
        currentRoute: AppRoutes.anggota,
        homeRoute: AppRoutes.anggota,
      ),
    );
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
  final AnggotaMonthStatus status;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLunas = status == AnggotaMonthStatus.paid;
    final isTunggakan = status == AnggotaMonthStatus.tunggakan;

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
                Icon(
                  iconData,
                  color: isDisabled ? const Color(0xFFA1A1A1) : Colors.white,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KonfirmasiDialog extends StatelessWidget {
  final String monthLabels;
  final String total;

  const _KonfirmasiDialog({required this.monthLabels, required this.total});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                size: 34,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Konfirmasi Pembayaran',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Apakah anda yakin membayar bulan $monthLabels sebesar $total?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                fontFamily: 'Poppins',
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4B5563),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C844C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Ya, Bayar'),
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

class _PaymentMethodPickerDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Metode Pembayaran',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 20),
            _MethodOption(
              icon: Icons.account_balance,
              iconColor: const Color(0xFF5D7FE8),
              iconBg: const Color(0x335D7FE8),
              title: 'Transfer Bank',
              subtitle: 'Transfer ke rekening PC',
              onTap: () => Navigator.pop(context, 'transfer'),
            ),
            const SizedBox(height: 12),
            _MethodOption(
              icon: Icons.qr_code_scanner,
              iconColor: const Color(0xFFDE8D00),
              iconBg: const Color(0x33E8DA5D),
              title: 'QRIS',
              subtitle: 'Scan via Gopay, OVO, Dana',
              onTap: () => Navigator.pop(context, 'qris'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF494949),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF949494),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
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

class _PaymentDetailsPopup extends StatefulWidget {
  final PembayaranController controller;
  final String selfUserId;
  final ImagePicker picker;

  const _PaymentDetailsPopup({
    required this.controller,
    required this.selfUserId,
    required this.picker,
  });

  @override
  State<_PaymentDetailsPopup> createState() => _PaymentDetailsPopupState();
}

class _PaymentDetailsPopupState extends State<_PaymentDetailsPopup> {
  @override
  Widget build(BuildContext context) {
    final isTransfer = widget.controller.selectedPaymentMethod == 'transfer';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isTransfer
                                ? const Color(0x335D7FE8)
                                : const Color(0x33E8DA5D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isTransfer
                                ? Icons.account_balance
                                : Icons.qr_code_scanner,
                            color: isTransfer
                                ? const Color(0xFF5D7FE8)
                                : const Color(0xFFDE8D00),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTransfer ? 'Transfer Bank' : 'QRIS',
                                style: const TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                widget.controller.formatCurrency(
                                  widget.controller.totalTagihan,
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF10B367),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF6C6C6C),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (widget.controller.isLoadingAccounts)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            color: Color(0xFF10B367),
                          ),
                        ),
                      )
                    else if (isTransfer)
                      _buildTransferContent()
                    else
                      _buildQrisContent(),

                    const SizedBox(height: 20),

                    const Text(
                      'Upload Bukti Pembayaran',
                      style: TextStyle(
                        color: Color(0xFF074D2C),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildUploadArea(),
                    const SizedBox(height: 20),
                    if (widget.controller.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          widget.controller.errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransferContent() {
    final accounts = widget.controller.transferAccounts;

    if (accounts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Belum ada rekening tersedia untuk wilayah Anda. Hubungi PC.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF856404),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Bank Tujuan',
          style: TextStyle(
            color: Color(0xFF074D2C),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: accounts.map((account) {
            final isSelected = widget.controller.selectedBankId == account.id;
            return GestureDetector(
              onTap: () {
                widget.controller.setBankById(account.id ?? '');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE9FFE9) : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10B367)
                        : const Color(0xFFAFAFAF),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  account.bankName ?? '-',
                  style: const TextStyle(
                    color: Color(0xFF494949),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            border: Border.all(color: const Color(0xFFB4B4B4)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bank Tujuan',
                    style: TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    widget.controller.selectedBankName,
                    style: const TextStyle(
                      color: Color(0xFF464646),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFA3A3A3), height: 24),
              const Text(
                'Nomor Rekening',
                style: TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                widget.controller.selectedAccountNumber,
                style: const TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Atas Nama',
                style: TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                widget.controller.selectedAccountHolder,
                style: const TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrisContent() {
    final accounts = widget.controller.qrisAccounts;

    if (accounts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Belum ada QRIS tersedia untuk wilayah Anda. Hubungi PC.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF856404),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih QRIS',
          style: TextStyle(
            color: Color(0xFF074D2C),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: accounts.map((account) {
            final isSelected = widget.controller.selectedQrisId == account.id;
            return GestureDetector(
              onTap: () {
                widget.controller.setQrisById(account.id ?? '');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF8E1) : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFDE8D00)
                        : const Color(0xFFAFAFAF),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 16,
                      color: isSelected
                          ? const Color(0xFFDE8D00)
                          : const Color(0xFF949494),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      account.bankName ?? 'QRIS',
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFDE8D00)
                            : const Color(0xFF494949),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.controller.qrisImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      AppConfig.fullUrl(widget.controller.qrisImageUrl!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.qr_code_2,
                        size: 170,
                        color: Colors.black87,
                      ),
                    ),
                  )
                : const Icon(Icons.qr_code_2, size: 170, color: Colors.black87),
          ),
        ),
        if (widget.controller.selectedQrisName != '-') ...[
          const SizedBox(height: 10),
          Center(
            child: Text(
              widget.controller.selectedQrisName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Color(0xFF494949),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadArea() {
    final ctrl = widget.controller;

    return GestureDetector(
      onTap: ctrl.isUploading ? null : () => _pickAndUpload(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          border: Border.all(
            color: ctrl.buktiFile != null
                ? const Color(0xFF10B367)
                : const Color(0xFFB4B4B4),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ctrl.isUploading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B367)),
              )
            : ctrl.buktiFile != null
            ? Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 40,
                    color: Color(0xFF10B367),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ctrl.buktiFile!.path.split('/').last,
                    style: const TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ketuk untuk ganti',
                    style: TextStyle(
                      color: Color(0xFF10B367),
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              )
            : const Column(
                children: [
                  Icon(Icons.upload_file, size: 40, color: Color(0xFF10B367)),
                  SizedBox(height: 8),
                  Text(
                    'Ketuk untuk Unggah Bukti',
                    style: TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'JPG, PNG, Max 5mb',
                    style: TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final picked = await widget.picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      widget.controller.setBuktiFile(File(picked.path));
      await widget.controller.uploadBukti();
    }
  }

  Widget _buildSubmitButton() {
    final ctrl = widget.controller;
    final canSubmit = ctrl.canSubmit && !ctrl.isLoading;

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: canSubmit
                ? [const Color(0xFF074D2C), const Color(0xFF10B367)]
                : [const Color(0xFFAAAAAA), const Color(0xFFCCCCCC)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: canSubmit ? () => _handleSubmit() : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: ctrl.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Kirim Bukti Pembayaran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    await widget.controller.submitTransaction(anggotaId: widget.selfUserId);

    if (!mounted) return;

    if (widget.controller.isSuccess) {
      Navigator.pop(context, true);
    } else if (widget.controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
