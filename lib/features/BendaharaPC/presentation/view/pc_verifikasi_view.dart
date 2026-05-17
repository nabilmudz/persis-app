import 'package:flutter/material.dart';
import 'package:persis_app/app/routes.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';
import '../controller/pc_controller.dart';
import '../widgets/verifikasi_card.dart';
import '../widgets/sweet_alert_dialog.dart';

class PcVerifikasiPage extends StatefulWidget {
  const PcVerifikasiPage({super.key});

  @override
  State<PcVerifikasiPage> createState() => _PcVerifikasiPageState();
}

class _PcVerifikasiPageState extends State<PcVerifikasiPage> {
  late final PcController _controller;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = PcController();
    _controller.loadTransactions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleVerifikasi(var item) async {
    final nominalText = _controller.formatCurrency(
      item.transaction.totalAmount ?? 0,
    );
    final shouldContinue = await SweetAlertDialog.showConfirmation(
      context: context,
      title: 'Verifikasi Laporan',
      message:
          'Uang fisik sebesar $nominalText dari ${item.name} sudah diterima dan sesuai?',
      confirmText: 'Ya, Verifikasi',
      cancelText: 'Batal',
    );

    if (!shouldContinue || !mounted) return;
    final result = await _controller.accTransaction(item.transaction);
    if (!mounted) return;

    if (result == PcAccResult.success) {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Berhasil',
        message: 'Data berhasil diverifikasi dan dipindahkan ke Riwayat.',
        buttonText: 'OK',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF363636)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Verifikasi Laporan PJ',
            style: TextStyle(
              color: Color(0xFF363636),
              fontSize: 18,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF0C844C),
            unselectedLabelColor: Color(0xFF6A6A6A),
            indicatorColor: Color(0xFF0C844C),
            // TEKS TAB UDAH DIKEMBALIKAN KE SEMULA:
            tabs: [
              Tab(text: 'Perlu Review'),
              Tab(text: 'Sudah Diverifikasi'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (query) => setState(() => _searchQuery = query),
                decoration: InputDecoration(
                  hintText: 'Cari Nama Anggota atau Wilayah...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6A6A6A),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF0C844C)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.isLoading)
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0C844C),
                      ),
                    );
                  return TabBarView(
                    children: [
                      _buildListTab('Belum Diverifikasi'),
                      _buildListTab('Sudah Diverifikasi'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: const RoleBottomNavigationBar(
          currentRoute: AppRoutes.bendaharaPC,
          homeRoute: AppRoutes.bendaharaPC,
        ),
      ),
    );
  }

  Widget _buildListTab(String category) {
    final items = _controller.filteredVerifikasiItems(
      category: category,
      query: _searchQuery,
    );
    if (items.isEmpty)
      return const Center(
        child: Text(
          'Tidak ada data.',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
        ),
      );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isPending = category == 'Belum Diverifikasi';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: VerifikasiCard(
            name: item.name,
            date: item.date,
            location: item.location,
            idNumber: item.transaction.creatorId ?? item.idNumber,
            paymentMethod: item.paymentMethod,
            price: item.price,
            onAccPressed: isPending ? () => _handleVerifikasi(item) : null,
            status: isPending ? null : item.category,
          ),
        );
      },
    );
  }
}
