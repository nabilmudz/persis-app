import 'package:flutter/material.dart';
import '../controller/pc_bank_account_controller.dart';
import '../../../BendaharaPC/data/models/bank_account_model.dart';
import '../widgets/add_bank_account_dialog.dart';
import '../widgets/bank_account_card.dart';
import '../widgets/sweet_alert_dialog.dart';

class PcBankAccountPage extends StatefulWidget {
  const PcBankAccountPage({super.key});

  @override
  State<PcBankAccountPage> createState() => _PcBankAccountPageState();
}

class _PcBankAccountPageState extends State<PcBankAccountPage> {
  late final PcBankAccountController _controller;

  Future<void> _loadBankAccounts() async {
    await _controller.loadBankAccounts();
    await _controller.loadPaymentMethods();

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

  Future<void> _handleAddBankAccount() async {
    final regionId = await _controller.resolveRegionId();
    final paymentMethodId = await _controller
        .resolveTransferBankPaymentMethodId();

    if (!mounted) {
      return;
    }

    if (paymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metode Transfer Bank belum tersedia.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddBankAccountDialog(
        defaultRegionId: regionId,
        defaultPaymentMethodId: paymentMethodId,
        onSubmit: (newAccount) async {
          final result = await _controller.addBankAccount(newAccount);

          if (!mounted) return;

          if (result) {
            await SweetAlertDialog.showSuccess(
              context: context,
              title: 'Berhasil',
              message: 'Rekening bank berhasil ditambahkan.',
            );
          } else {
            await SweetAlertDialog.showSuccess(
              context: context,
              title: 'Gagal',
              message:
                  _controller.errorMessage ?? 'Gagal menambahkan rekening.',
            );
          }
        },
      ),
    );
  }

  void _handleEditBankAccount(BankAccountModel account) {
    final defaultRegionId = account.regionId ?? '';
    final defaultPaymentMethodId = account.paymentMethodId ?? '';

    showDialog(
      context: context,
      builder: (context) => AddBankAccountDialog(
        initialAccount: account,
        defaultRegionId: defaultRegionId,
        defaultPaymentMethodId: defaultPaymentMethodId,
        title: 'Edit Rekening Bank',
        submitLabel: 'Simpan Perubahan',
        onSubmit: (updatedAccount) async {
          if (account.id == null) {
            return;
          }

          final result = await _controller.updateBankAccount(
            account.id!,
            updatedAccount,
          );

          if (!mounted) return;

          if (result) {
            await SweetAlertDialog.showSuccess(
              context: context,
              title: 'Berhasil',
              message: 'Rekening bank berhasil diperbarui.',
            );
          } else {
            await SweetAlertDialog.showSuccess(
              context: context,
              title: 'Gagal',
              message:
                  _controller.errorMessage ?? 'Gagal memperbarui rekening.',
            );
          }
        },
      ),
    );
  }

  Future<void> _handleDeleteBankAccount(String id, String bankName) async {
    final shouldDelete = await SweetAlertDialog.showConfirmation(
      context: context,
      title: 'Konfirmasi Hapus',
      message: 'Yakin ingin menghapus rekening $bankName?',
      confirmText: 'Ya, Hapus',
      cancelText: 'Batal',
    );

    if (!shouldDelete || !mounted) {
      return;
    }

    final result = await _controller.deleteBankAccount(id);

    if (!mounted) {
      return;
    }

    if (result) {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Berhasil',
        message: 'Rekening berhasil dihapus.',
      );
    } else {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Gagal',
        message: _controller.errorMessage ?? 'Gagal menghapus rekening.',
      );
    }
  }

  void _handleSaveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perubahan berhasil disimpan')),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = PcBankAccountController();
    _loadBankAccounts();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF363636)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kelola Rekening',
          style: TextStyle(
            color: Color(0xFF363636),
            fontSize: 20,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            final accounts = _controller.bankAccounts;

            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show error if any
            if (_controller.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 50,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${_controller.errorMessage}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBankAccounts,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Daftar Rekening
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Rekening',
                          style: TextStyle(
                            color: Color(0xFF074D2C),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: _handleAddBankAccount,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C844C),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              '+ Tambah Baru',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Bank Accounts List
                    if (accounts.isEmpty)
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
                            'Tidak ada rekening',
                            style: TextStyle(
                              color: Color(0xFF6A6A6A),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      ...accounts.map((account) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: BankAccountCard(
                            bankName: account.bankName ?? '-',
                            accountNumber: account.accountNumber ?? '-',
                            accountHolder: account.bankName ?? '-',
                            onEdit: () => _handleEditBankAccount(account),
                            onDelete: () async {
                              if (account.id != null) {
                                await _handleDeleteBankAccount(
                                  account.id!,
                                  account.bankName ?? '-',
                                );
                              }
                            },
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 24),
                    // Section: Gambar QRIS
                    const Text(
                      'Gambar QRIS',
                      style: TextStyle(
                        color: Color(0xFF074D2C),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // QRIS Upload Area
                    Container(
                      width: double.infinity,
                      height: 217,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        border: Border.all(
                          color: const Color(0xFFB4B4B4),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 75,
                            color: const Color(0xFFB4B4B4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Unggah Gambar QRIS',
                            style: TextStyle(
                              color: Color(0xFF6B6B6B),
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pastikan Gambar Jelas',
                            style: TextStyle(
                              color: Color(0xFF6B6B6B),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Save Button
                    GestureDetector(
                      onTap: _handleSaveChanges,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment(-0.04, 0.50),
                            end: Alignment(1.00, 0.50),
                            colors: [
                              Color(0xFF074D2C),
                              Color(0xFF0B7B46),
                              Color(0xFF10B367),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Center(
                          child: Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
