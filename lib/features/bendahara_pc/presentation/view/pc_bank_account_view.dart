import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:persis_app/app/routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';
import '../controller/pc_bank_account_controller.dart';
import '../../../bendahara_pc/data/models/bank_account_model.dart';
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
  Uint8List? _selectedQrisImageBytes;
  String? _selectedQrisImageName;
  bool _isSavingQris = false;

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

  Future<void> _pickQrisImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      final file = result?.files.single;
      if (file == null || file.bytes == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedQrisImageBytes = file.bytes;
        _selectedQrisImageName = file.name;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar QRIS: $e')));
    }
  }

  Future<void> _handleSaveQris(BankAccountModel? existingQris) async {
    if (_selectedQrisImageBytes == null || _selectedQrisImageBytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gambar QRIS terlebih dulu.')),
      );
      return;
    }

    final paymentMethodId = await _controller.resolveQrisPaymentMethodId();

    if (paymentMethodId == null || paymentMethodId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sistem tidak menemukan ID Metode Pembayaran QRIS. Hubungi Admin.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSavingQris = true;
    });

    final qrisAccount = BankAccountModel(
      id: existingQris?.id,
      paymentMethodId: paymentMethodId,
      bankName: null,
      accountNumber: null,
      qrisImageBytes: _selectedQrisImageBytes,
      qrisImageName: _selectedQrisImageName,
      isActive: true,
    );

    final result = existingQris == null
        ? await _controller.addBankAccount(qrisAccount)
        : await _controller.updateBankAccount(existingQris.id!, qrisAccount);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSavingQris = false;
      if (result) {
        _selectedQrisImageBytes = null;
        _selectedQrisImageName = null;
      }
    });

    if (result) {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Berhasil',
        message: existingQris == null
            ? 'QRIS berhasil ditambahkan.'
            : 'QRIS berhasil diperbarui.',
      );
    } else {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Gagal',
        message: _controller.errorMessage ?? 'Gagal menyimpan QRIS.',
      );
    }
  }

  Future<void> _handleDeleteQris(BankAccountModel qrisAccount) async {
    if (qrisAccount.id == null) {
      return;
    }

    final shouldDelete = await SweetAlertDialog.showConfirmation(
      context: context,
      title: 'Konfirmasi Hapus',
      message: 'Yakin ingin menghapus QRIS ini?',
      confirmText: 'Ya, Hapus',
      cancelText: 'Batal',
    );

    if (!shouldDelete || !mounted) {
      return;
    }

    final result = await _controller.deleteBankAccount(qrisAccount.id!);

    if (!mounted) {
      return;
    }

    if (result) {
      setState(() {
        _selectedQrisImageBytes = null;
        _selectedQrisImageName = null;
      });
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Berhasil',
        message: 'QRIS berhasil dihapus.',
      );
    } else {
      await SweetAlertDialog.showSuccess(
        context: context,
        title: 'Gagal',
        message: _controller.errorMessage ?? 'Gagal menghapus QRIS.',
      );
    }
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
            final qrisAccounts = _controller.qrisAccounts;
            final qrisAccount = qrisAccounts.isNotEmpty
                ? qrisAccounts.first
                : null;

            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

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
                      }),
                    const SizedBox(height: 24),
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
                    if (qrisAccount == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F6),
                          border: Border.all(
                            color: const Color(0xFFB4B4B4),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GestureDetector(
                              onTap: _pickQrisImage,
                              child: Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEFEF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: _selectedQrisImageBytes == null
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 75,
                                            color: Color(0xFFB4B4B4),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Unggah Gambar QRIS',
                                            style: TextStyle(
                                              color: Color(0xFF6B6B6B),
                                              fontSize: 15,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Tap untuk pilih file gambar',
                                            style: TextStyle(
                                              color: Color(0xFF6B6B6B),
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.memory(
                                          _selectedQrisImageBytes!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 220,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedQrisImageName ??
                                  'Belum ada file dipilih',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF6B6B6B),
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _pickQrisImage,
                              icon: const Icon(Icons.image_outlined),
                              label: const Text('Pilih Gambar QRIS'),
                            ),
                          ],
                        ),
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F6),
                            border: Border.all(
                              color: const Color(0xFFB4B4B4),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AspectRatio(
                                aspectRatio: 1.2,
                                child: _selectedQrisImageBytes != null
                                    ? Image.memory(
                                        _selectedQrisImageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : (qrisAccount.qrisImageUrl != null &&
                                          qrisAccount.qrisImageUrl!.isNotEmpty)
                                    ? Image.network(
                                        qrisAccount.qrisImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Center(
                                                child: Text(
                                                  'Preview QRIS gagal dimuat',
                                                ),
                                              );
                                            },
                                      )
                                    : const Center(
                                        child: Text('QRIS belum tersedia'),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextButton.icon(
                                      onPressed: _pickQrisImage,
                                      icon: const Icon(Icons.edit),
                                      label: Text(
                                        _selectedQrisImageBytes == null
                                            ? 'Ubah Gambar QRIS'
                                            : 'Ganti Gambar QRIS',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedQrisImageName ??
                                          'QRIS aktif saat ini',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF6B6B6B),
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isSavingQris
                          ? null
                          : () => _handleSaveQris(qrisAccount),
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
                        child: Center(
                          child: _isSavingQris
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  qrisAccount == null
                                      ? 'Upload QRIS'
                                      : 'Simpan Perubahan',
                                  style: const TextStyle(
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
                    if (qrisAccount != null)
                      TextButton.icon(
                        onPressed: () => _handleDeleteQris(qrisAccount),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Hapus QRIS',
                          style: TextStyle(color: Colors.red),
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
      bottomNavigationBar: const RoleBottomNavigationBar(
        currentRoute: AppRoutes.bendaharaPC,
        homeRoute: AppRoutes.bendaharaPC,
      ),
    );
  }
}
