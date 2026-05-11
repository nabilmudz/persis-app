import 'package:flutter/material.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';

class BendaharaSaldoCard extends StatefulWidget {
  final String role;
  final String badgeText;
  final String title;

  const BendaharaSaldoCard({
    super.key,
    required this.role,
    required this.badgeText,
    required this.title,
  });

  @override
  State<BendaharaSaldoCard> createState() => _BendaharaSaldoCardState();
}

class _BendaharaSaldoCardState extends State<BendaharaSaldoCard> {
  final _dataSource = TransactionRemoteDataSource();

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

  late int _selectedMonth;
  late int _selectedYear;

  int _amount = 0;
  int? _totalMembersPaid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final result = await _dataSource.fetchSummary(
      year: _selectedYear,
      month: _selectedMonth,
    );

    if (!mounted) return;

    final dist = result?['summary']?['distribution'];
    final roleData = dist?[widget.role.toLowerCase()];
    final amount = (roleData?['amount'] as num?)?.toInt() ?? 0;
    final totalTx = result?['meta']?['total_transactions'] as int?;

    setState(() {
      _amount = amount;
      _totalMembersPaid = _selectedMonth > 0 ? totalTx : null;
      _isLoading = false;
    });
  }

  String _formatCurrency(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer('Rp ');
    for (var i = 0; i < s.length; i++) {
      final reverseIndex = s.length - i;
      buffer.write(s[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }

  String get _dropdownLabel {
    if (_selectedMonth == 0) return 'Tahun $_selectedYear';
    return _monthNames[_selectedMonth - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

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
          // ── Row: Badge + Dropdown ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0x77D9D9D9),
                  borderRadius: BorderRadius.all(Radius.circular(80)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Text(
                    widget.badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // ── Dropdown kecil ─────────────────────────────────────────
              GestureDetector(
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (_) => _FilterSheet(
                      selectedMonth: _selectedMonth,
                      selectedYear: _selectedYear,
                      monthNames: _monthNames,
                      onSelected: (month, year) {
                        setState(() {
                          _selectedMonth = month;
                          _selectedYear = year;
                        });
                        _load();
                      },
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x77D9D9D9),
                    borderRadius: BorderRadius.circular(80),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _dropdownLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // ── Amount ────────────────────────────────────────────────────
          _isLoading
              ? const SizedBox(
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : Text(
                  _formatCurrency(_amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),

          // ── Subtitle: anggota lunas (hanya per bulan) ─────────────────
          if (!_isLoading && _totalMembersPaid != null) ...[
            const SizedBox(height: 4),
            Text(
              '$_totalMembersPaid Anggota Lunas $_dropdownLabel',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom sheet filter ────────────────────────────────────────────────────────
class _FilterSheet extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final List<String> monthNames;
  final void Function(int month, int year) onSelected;

  const _FilterSheet({
    required this.selectedMonth,
    required this.selectedYear,
    required this.monthNames,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = [now.year - 1, now.year]; // tahun lalu + tahun ini

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Periode',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: Color(0xFF073D4D),
            ),
          ),
          const SizedBox(height: 16),

          // ── Full year options ──────────────────────────────────────────
          ...years.map(
            (year) => _SheetTile(
              label: 'Tahun $year',
              isSelected: selectedMonth == 0 && selectedYear == year,
              onTap: () {
                Navigator.pop(context);
                onSelected(0, year);
              },
            ),
          ),

          const Divider(height: 24),
          Text(
            'Per Bulan (${DateTime.now().year})',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(monthNames.length, (i) {
              final month = i + 1;
              final isSelected =
                  selectedMonth == month && selectedYear == now.year;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onSelected(month, now.year);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0C844C)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    monthNames[i],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF444444),
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SheetTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: isSelected ? const Color(0xFF0C844C) : const Color(0xFF374151),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF0C844C), size: 18)
          : null,
      onTap: onTap,
    );
  }
}

class BendaharaMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;

  const BendaharaMenuCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconBackgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 7,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF074D2C), size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF074D2C),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
