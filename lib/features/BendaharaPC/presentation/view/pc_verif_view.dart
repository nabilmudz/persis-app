import 'package:flutter/material.dart';
import '../controller/pc_controller.dart';

import '../widgets/sweet_alert_dialog.dart';
import '../widgets/verifikasi_card.dart';

class PcVerifikasiPage extends StatefulWidget {
  const PcVerifikasiPage({super.key, this.controller});

  final PcController? controller;

  @override
  State<PcVerifikasiPage> createState() => _PcVerifikasiPageState();
}

class _PcVerifikasiPageState extends State<PcVerifikasiPage> {
  final TextEditingController _searchController = TextEditingController();
  late final PcController _controller;
  late final bool _ownsController;
  String _selectedCategory = 'Belum Diverifikasi';

  List<String> get _categories => PcController.verificationCategories;

  Future<void> _loadTransactions() async {
    await _controller.loadTransactions();

    if (!mounted) {
      return;
    }

    final error = _controller.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? PcController();

    if (_ownsController) {
      _loadTransactions();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();

    if (_ownsController) {
      _controller.dispose();
    }

    super.dispose();
  }

  List<PcVerifikasiItem> _filteredItems() {
    return _controller.filteredVerifikasiItems(
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

    if (result == PcAccResult.alreadyVerified) {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Sudah Diverifikasi',
        message: 'Pembayaran ${item.name} sudah pernah di-ACC sebelumnya.',
      );
      return;
    }

    if (result == PcAccResult.notFound) {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Data Tidak Ditemukan',
        message: 'Data transaksi gagal diperbarui. Coba lagi.',
      );
      return;
    }

    await SweetAlertDialog.showSuccess(
      context: context,
      title: 'Berhasil',
      message: 'Pembayaran ${item.name} berhasil di-ACC.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Verifikasi Pembayaran')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            if (_controller.isLoading) {
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
                        hintText: 'Cari nama, lokasi, ID, atau metode',
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
                            'Data tidak ditemukan',
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
                          child: Align(
                            child: VerifikasiCard(
                              date: item.date,
                              location: item.location,
                              name: item.name,
                              idNumber: item.idNumber,
                              paymentMethod: item.paymentMethod,
                              price: item.price,
                              onAccPressed: () async => _handleAccPressed(item),
                              onLihatBuktiPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Menampilkan bukti ${item.paymentMethod}',
                                    ),
                                  ),
                                );
                              },
                            ),
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
    );
  }
}
