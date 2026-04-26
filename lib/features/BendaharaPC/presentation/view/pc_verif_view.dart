import 'package:flutter/material.dart';
import '../../data/datasources/iuran_local_datasources.dart';
import '../../data/models/iuran_model.dart';

import '../widgets/sweet_alert_dialog.dart';
import '../widgets/verifikasi_card.dart';

class PcVerifikasiPage extends StatefulWidget {
  const PcVerifikasiPage({super.key});

  @override
  State<PcVerifikasiPage> createState() => _PcVerifikasiPageState();
}

class _PcVerifikasiPageState extends State<PcVerifikasiPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Belum Diverifikasi';

  static const List<String> _categories = <String>[
    'Belum Diverifikasi',
    'Sudah Diverifikasi',
    'Tunggakan',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_VerifikasiItem> _filteredItems() {
    final allItems = dummyDaftarIuran.map(_toVerifikasiItem).toList();
    final query = _searchController.text.trim().toLowerCase();

    return allItems.where((item) {
      final sameCategory = item.category == _selectedCategory;
      if (!sameCategory) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return item.name.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.idNumber.toLowerCase().contains(query) ||
          item.paymentMethod.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _handleAccPressed(_VerifikasiItem item) async {
    if (item.status == StatusIuran.diverifikasi) {
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

    final index = dummyDaftarIuran.indexWhere((i) => i.id == item.idIuran);

    if (index == -1) {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Data Tidak Ditemukan',
        message: 'Data iuran gagal diperbarui. Coba lagi.',
      );
      return;
    }

    setState(() {
      dummyDaftarIuran[index].status = StatusIuran.diverifikasi;
    });

    await SweetAlertDialog.showSuccess(
      context: context,
      title: 'Berhasil',
      message: 'Pembayaran PJ ${item.name} berhasil di-ACC.',
    );
  }

  _VerifikasiItem _toVerifikasiItem(IuranModel item) {
    return _VerifikasiItem(
      idIuran: item.id,
      date: _formatDate(item.tanggalBayar),
      location: 'PJ ${item.lokasiPjNama}',
      name: item.lokasiPjNama,
      idNumber: '-',
      paymentMethod: _paymentMethodText(item),
      price: _formatCurrency(item.nominal),
      category: _categoryFromStatus(item.status),
      status: item.status,
    );
  }

  String _categoryFromStatus(StatusIuran status) {
    switch (status) {
      case StatusIuran.diverifikasi:
        return 'Sudah Diverifikasi';
      case StatusIuran.tunggakan:
        return 'Tunggakan';
      case StatusIuran.menungguVerifikasi:
      case StatusIuran.belumDibayar:
        return 'Belum Diverifikasi';
    }
  }

  String _paymentMethodText(IuranModel item) {
    switch (item.metodePembayaran) {
      case MetodePembayaran.transferBank:
        return 'Transfer Bank';
      case MetodePembayaran.tunai:
        return 'Tunai';
      case MetodePembayaran.qrisCode:
        return 'QRIS';
      case null:
        return item.buktiTransferUrl == null ? 'Tunai' : 'Transfer';
    }
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = value.day.toString().padLeft(2, '0');
    return '$day ${months[value.month - 1]} ${value.year}';
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

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Verifikasi Pembayaran')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 12.0 : 20.0;

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
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0C844C)),
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
        ),
      ),
    );
  }
}

class _VerifikasiItem {
  final String idIuran;
  final String date;
  final String location;
  final String name;
  final String idNumber;
  final String paymentMethod;
  final String price;
  final String category;
  final StatusIuran status;

  const _VerifikasiItem({
    required this.idIuran,
    required this.date,
    required this.location,
    required this.name,
    required this.idNumber,
    required this.paymentMethod,
    required this.price,
    required this.category,
    required this.status,
  });
}
