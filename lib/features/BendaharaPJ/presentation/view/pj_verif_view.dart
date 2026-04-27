import 'package:flutter/material.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import '../controller/pj_controller.dart';
import 'pj_cart_view.dart';

class PjVerifViewPage extends StatefulWidget {
  final PjController controller;
  final UserModel member;

  const PjVerifViewPage({
    super.key,
    required this.controller,
    required this.member,
  });

  @override
  State<PjVerifViewPage> createState() => _PjVerifViewPageState();
}

class _PjVerifViewPageState extends State<PjVerifViewPage> {
  int _selectedYear = 2026;
  final Set<int> _selectedMonths = <int>{};

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

    final memberName = widget.controller.memberDisplayName(widget.member);
    final isAlreadyInCart = widget.controller.isInCart(
      anggotaId: anggotaId,
      month: month,
      year: _selectedYear,
    );

    if (isAlreadyInCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bulan ${_monthNames[month - 1]} sudah ada di keranjang $memberName.',
          ),
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

  Future<void> _submitSelectedMonths() async {
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

    final memberName = widget.controller.memberDisplayName(widget.member);

    if (_selectedMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu bulan terlebih dahulu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final months = _selectedMonths.toList()..sort();
    final monthNominals = {
      for (final month in months)
        month: widget.controller.getNominalForMemberMonth(
          anggotaId: anggotaId,
          month: month,
          year: _selectedYear,
        ),
    };
    final totalMonths = months.length;
    final totalNominal = monthNominals.values.fold<double>(
      0,
      (sum, nominal) => sum + nominal,
    );
    final monthLabels = months.map((m) => _monthNames[m - 1]).join(', ');

    final shouldInsert = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Konfirmasi Masuk Keranjang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: Color(0xFF073D4D),
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Nama', value: memberName),
              _DetailRow(label: 'Jumlah Bulan', value: '$totalMonths bulan'),
              _DetailRow(label: 'Bulan Dipilih', value: monthLabels),
              _DetailRow(
                label: 'Total Nominal',
                value: _formatCurrency(totalNominal),
              ),
              const SizedBox(height: 4),
              const Text(
                'Rincian nominal per bulan',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...months.map((month) {
                final nominal = monthNominals[month] ?? 0;
                return _DetailRow(
                  label: _monthNames[month - 1],
                  value: _formatCurrency(nominal),
                );
              }),
              const SizedBox(height: 14),
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
                      child: const Text('Masukkan ke Keranjang'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldInsert != true || !mounted) {
      return;
    }

    for (final month in months) {
      widget.controller.addMonthToCart(
        member: widget.member,
        month: month,
        year: _selectedYear,
        nominal: monthNominals[month],
      );
    }

    setState(() {
      _selectedMonths.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$totalMonths bulan untuk $memberName dimasukkan ke keranjang.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        actions: [
          IconButton(
            tooltip: 'Lihat keranjang',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PjCartViewPage(controller: widget.controller),
                ),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (widget.controller.cartItemCount > 0)
                  Positioned(
                    right: -6,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB31012),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.controller.cartItemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBEE7CC)),
                  ),
                  child: Text(
                    'Keranjang aktif: ${widget.controller.cartItemCount} item • Total ${_formatCurrency(widget.controller.cartTotalNominal)}',
                    style: const TextStyle(
                      color: Color(0xFF0B6A3B),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                    final status = widget.controller.getMonthStatus(
                      anggotaId: anggotaId ?? '',
                      month: month,
                      year: _selectedYear,
                    );

                    return _MonthCard(
                      name: monthName,
                      status: status,
                      isSelected: _selectedMonths.contains(month),
                      isInCart: widget.controller.isInCart(
                        anggotaId: anggotaId ?? '',
                        month: month,
                        year: _selectedYear,
                      ),
                      onTap: () => _handleMonthTap(month),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitSelectedMonths,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C844C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _selectedMonths.isEmpty
                          ? 'Submit Pilihan ke Keranjang'
                          : 'Submit ${_selectedMonths.length} Bulan ke Keranjang',
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
    required this.isInCart,
    required this.onTap,
  });

  final String name;
  final PjMonthStatus status;
  final bool isSelected;
  final bool isInCart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLunas = status == PjMonthStatus.lunas;

    final Decoration decoration;
    final Color textColor;
    final IconData? iconData;

    if (isInCart) {
      decoration = BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E8D5A), Color(0xFF0B6A3B)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFAFAFAF)),
      );
      textColor = Colors.white;
      iconData = Icons.shopping_cart_checkout_rounded;
    } else if (isSelected) {
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
