import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/anggota_card.dart';
import '../controller/anggota_controller.dart';

class RiwayatView extends StatefulWidget {
  const RiwayatView({Key? key}) : super(key: key);

  @override
  State<RiwayatView> createState() => _RiwayatViewState();
}

class _RiwayatViewState extends State<RiwayatView> {
  String selectedFilter = 'Semua';

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
          style: TextStyle(color: Color(0xFF363636), fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFD0D0D0), height: 1.0),
        ),
      ),
      body: Consumer<AnggotaController>(
        builder: (context, controller, child) {

          final filteredTransactions = controller.riwayatTransaksi.where((tx) {
            if (selectedFilter == 'Semua') return true;
            final deskripsi = (tx.description ?? '').toLowerCase();
            if (selectedFilter == 'Tahun 2026') return deskripsi.contains('2026');
            if (selectedFilter == 'Tahun 2025') return deskripsi.contains('2025');
            if (selectedFilter == 'Tahun 2024') return deskripsi.contains('2024');
            return true;
          }).toList();

          return Column(
            children: [
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildFilterChip('Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Tahun 2026'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Tahun 2025'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Tahun 2024'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: filteredTransactions.isEmpty 
                  ? const Center(
                      child: Text(
                        'Tidak ada riwayat transaksi.',
                        style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        return AnggotaCard(transaction: filteredTransactions[index]);
                      },
                    ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF189D4A) : const Color(0xFFEDEDED),
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
