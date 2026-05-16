import 'package:flutter/material.dart';
import 'package:persis_app/features/anggota/presentation/controller/anggota_controller.dart';
import 'package:persis_app/features/anggota/presentation/widgets/anggota_card.dart';
import 'package:provider/provider.dart';

class RiwayatView extends StatefulWidget {
  const RiwayatView({super.key});

  @override
  State<RiwayatView> createState() => _RiwayatViewState();
}

class _RiwayatViewState extends State<RiwayatView> {
  String _selectedFilter = 'Semua';

  static const _filterOptions = [
    'Semua',
    'Tahun 2026',
    'Tahun 2025',
    'Tahun 2024',
  ];

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
          'Riwayat',
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
      body: Consumer<AnggotaController>(
        builder: (context, controller, _) {
          // Semua filtering & perhitungan dilakukan di controller
          final transactions =
              controller.filterLunasByTahun(_selectedFilter);
          final totalAmount = controller.hitungTotalNominal(transactions);

          return Column(
            children: [
              const SizedBox(height: 16),

              // ── Filter chips ──────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: _filterOptions
                      .map((label) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: label,
                              isSelected: _selectedFilter == label,
                              onTap: () =>
                                  setState(() => _selectedFilter = label),
                            ),
                          ))
                      .toList(),
                ),
              ),

              const SizedBox(height: 24),

              // ── Kartu total pembayaran lunas ──────────────────────
              if (transactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _TotalCard(totalAmount: totalAmount),
                ),

              const SizedBox(height: 20),

              // ── Daftar transaksi ──────────────────────────────────
              Expanded(
                child: transactions.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) => AnggotaCard(
                          transaction: transactions[index],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

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
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

  String _formatRupiah(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF189D4A),
          width: 1.5,
        ),
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
            'Rp ${_formatRupiah(totalAmount)}',
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada riwayat pembayaran.',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}