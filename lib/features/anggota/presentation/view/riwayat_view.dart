import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:persis_app/helpers/auth_helper.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_item_detail_model.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_transaction_item_controller.dart';

class RiwayatView extends StatefulWidget {
  const RiwayatView({super.key});

  @override
  State<RiwayatView> createState() => _RiwayatViewState();
}

class _RiwayatViewState extends State<RiwayatView> {
  late final PjTransactionItemController _controller;
  String _selectedYear = 'Semua';
  String? _userId;
  bool _loadingUser = true;

  // Status yang dianggap lunas
  static const _statusLunas = {
    'paid',
    'lunas',
    'selesai',
    'success',
    'completed',
  };

  @override
  void initState() {
    super.initState();
    _controller = PjTransactionItemController();
    _initUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    final uid = await AuthHelper.getUserId();
    if (!mounted) return;
    setState(() {
      _userId = uid;
      _loadingUser = false;
    });
    if (uid != null && uid.isNotEmpty) {
      _controller.loadByUser(uid);
    }
  }

  /// Item milik user ini yang statusnya lunas
  List<TransactionItemDetailModel> _getLunasItems() {
    return _controller.items.where((tx) {
      final status = (tx.status ?? '').trim().toLowerCase();
      final isOwner = _userId == null || tx.anggotaId == _userId;
      return isOwner && _statusLunas.any((s) => status.contains(s));
    }).toList();
  }

  /// Filter lunas berdasarkan tahun yang dipilih
  List<TransactionItemDetailModel> _filterByYear(
    List<TransactionItemDetailModel> lunas,
  ) {
    if (_selectedYear == 'Semua') return lunas;
    final year = int.tryParse(_selectedYear);
    if (year == null) return lunas;
    return lunas.where((tx) => tx.resolveYear() == year).toList();
  }

  /// Daftar tahun unik dari data lunas, diurutkan descending
  List<String> _availableYears(List<TransactionItemDetailModel> lunas) {
    final years = <String>{};
    for (final tx in lunas) {
      final y = tx.resolveYear();
      if (y != null) years.add(y.toString());
    }
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  double _hitungTotal(List<TransactionItemDetailModel> items) {
    return items.fold(0.0, (sum, tx) => sum + (tx.amount ?? 0));
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
          'Riwayat Pembayaran',
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
      body: _loadingUser
          ? const Center(child: CircularProgressIndicator())
          : _userId == null
              ? const _ErrorState(message: 'Gagal membaca data pengguna.')
              : ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    if (_controller.isLoading && _controller.items.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_controller.errorMessage != null &&
                        _controller.items.isEmpty) {
                      return _ErrorState(
                        message: _controller.errorMessage!,
                        onRetry: () =>
                            _controller.loadByUser(_userId!, forceRefresh: true),
                      );
                    }

                    final lunasAll = _getLunasItems();
                    final years = _availableYears(lunasAll);

                    // Reset filter jika tahun yang dipilih tidak ada lagi
                    if (_selectedYear != 'Semua' &&
                        !years.contains(_selectedYear)) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedYear = 'Semua');
                      });
                    }

                    final filterOptions = ['Semua', ...years];
                    final transactions = _filterByYear(lunasAll);
                    final totalAmount = _hitungTotal(transactions);

                    return RefreshIndicator(
                      color: const Color(0xFF189D4A),
                      onRefresh: () =>
                          _controller.loadByUser(_userId!, forceRefresh: true),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // ── Filter chips ──────────────────────────────
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: filterOptions
                                  .map(
                                    (label) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _FilterChip(
                                        label: label == 'Semua'
                                            ? 'Semua'
                                            : 'Tahun $label',
                                        isSelected: _selectedYear == label,
                                        onTap: () => setState(
                                          () => _selectedYear = label,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Kartu total ───────────────────────────────
                          if (transactions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: _TotalCard(totalAmount: totalAmount),
                            ),

                          const SizedBox(height: 16),

                          // ── Daftar transaksi ──────────────────────────
                          Expanded(
                            child: transactions.isEmpty
                                ? const _EmptyState()
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    itemCount: transactions.length,
                                    itemBuilder: (context, index) =>
                                        _RiwayatCard(
                                      item: transactions[index],
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

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF189D4A)
              : const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF7F7F7F),
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalAmount});

  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(totalAmount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF189D4A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Pembayaran Lunas',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF7F7F7F),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatted,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF189D4A),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  const _RiwayatCard({required this.item});

  final TransactionItemDetailModel item;

  static const _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(item.amount ?? 0);

    // Bangun label bulan-tahun yang terbaca
    String label = item.description ?? 'Iuran';
    final month = item.resolveMonth();
    final year = item.resolveYear();
    if (month != null && year != null && month >= 1 && month <= 12) {
      label = 'Iuran ${_monthNames[month - 1]} $year';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon lunas
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE9FFE9),
              border: Border.all(color: const Color(0xFF074D2C), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF10B367),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Deskripsi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF074D2C),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sistem InfaQu',
                  style: TextStyle(
                    color: Color(0xFF6A6A6A),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Status & nominal
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Lunas',
                style: TextStyle(
                  color: Color(0xFF10B367),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatted,
                style: const TextStyle(
                  color: Color(0xFF6A6A6A),
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
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
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada riwayat pembayaran lunas.',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

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
