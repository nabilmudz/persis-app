import 'package:flutter/material.dart';
import 'package:persis_app/app/routes.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';
import '../../controller/pj_verif_non_tunai_controller.dart';
import '../../../../BendaharaPC/presentation/controller/pc_controller.dart';
import '../../../../BendaharaPC/presentation/widgets/sweet_alert_dialog.dart';
import '../../../../BendaharaPC/presentation/widgets/verifikasi_card.dart';

class PjVerifNonTunaiViewPage extends StatefulWidget {
  const PjVerifNonTunaiViewPage({super.key});

  @override
  State<PjVerifNonTunaiViewPage> createState() =>
      _PjVerifNonTunaiViewPageState();
}

class _PjVerifNonTunaiViewPageState extends State<PjVerifNonTunaiViewPage> {
  final TextEditingController _searchController = TextEditingController();
  late final PjVerifNonTunaiController _controller;
  String _selectedCategory = 'Belum Diverifikasi';

  List<String> get _categories => PcController.verificationCategories;

  @override
  void initState() {
    super.initState();
    _controller = PjVerifNonTunaiController();
    _controller.loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<PcVerifikasiItem> _filteredItems() {
    return _controller.getFilteredItems(
      category: _selectedCategory,
      query: _searchController.text,
    );
  }

  Future<void> _handleAccPressed(PcVerifikasiItem item) async {
    if (_controller.isVerified(item.transaction)) {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Sudah Diverifikasi',
        message: 'Pembayaran ${item.name} sudah pernah di-ACC sebelumnya.',
      );
      return;
    }

    final shouldContinue = await SweetAlertDialog.showConfirmation(
      context: context,
      title: 'Konfirmasi ACC',
      message: 'Yakin ingin meng-ACC pembayaran ${item.name}?',
      confirmText: 'Ya, ACC',
      cancelText: 'Batal',
    );

    if (!shouldContinue || !mounted) {
      return;
    }

    final result = await _controller.accTransaction(item.transaction);

    if (result == PcAccResult.success) {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Berhasil',
        message: 'Pembayaran ${item.name} berhasil di-ACC.',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data transaksi gagal diperbarui. Coba lagi.'),
        ),
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
        title: const Text(
          'Verifikasi Non-Tunai',
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
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            if (_controller.isLoading && _controller.transactions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = _filteredItems();

            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 380
                    ? 12.0
                    : 20.0;

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    24,
                  ),
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau deskripsi',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF7F7F7),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0C844C),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          final isSelected = category == _selectedCategory;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                              selectedColor: const Color(0xFF0C844C),
                              backgroundColor: const Color(0xFFF0F0F0),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF444444),
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF0C844C)
                                      : const Color(0xFFE0E0E0),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: const Center(
                          child: Text(
                            'Tidak ada data iuran non-tunai',
                            style: TextStyle(
                              color: Color(0xFF6A6A6A),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: VerifikasiCard(
                            date: item.date,
                            location: item.location,
                            name: item.name,
                            idNumber: item.idNumber,
                            paymentMethod: item.paymentMethod,
                            price: item.price,
                            onAccPressed: () async => _handleAccPressed(item),
                            onLihatBuktiPressed: () {},
                          ),
                        );
                      }),
                  ],
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const RoleBottomNavigationBar(
        currentRoute: AppRoutes.bendaharaPJ,
        homeRoute: AppRoutes.bendaharaPJ,
      ),
    );
  }
}
