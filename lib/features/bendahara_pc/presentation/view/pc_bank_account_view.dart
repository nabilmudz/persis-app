import 'package:flutter/material.dart';
import 'package:persis_app/app/routes.dart';
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

  Future<void> _loadBankAccounts() async {
    await _controller.loadBankAccounts();
    await _controller.loadPaymentMethods();

    if (!mounted) return;

    final error = _controller.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _handleAddBankAccount() async {
    final paymentMethodId = await _controller
        .resolveTransferBankPaymentMethodId();

    if (!mounted) return;

    if (paymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metode Transfer Bank belum tersedia.')),
      );
      return;
    }

    _showDialog(paymentMethodId: paymentMethodId, isQris: false);
  }

  Future<void> _handleAddQris() async {
    final paymentMethodId = await _controller.resolveQrisPaymentMethodId();

    if (!mounted) return;

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

    _showDialog(paymentMethodId: paymentMethodId, isQris: true);
  }

  void _handleEdit(BankAccountModel account) {
    final isQris = (account.bankName ?? '').trim().toUpperCase() == 'QRIS';

    _showDialog(
      paymentMethodId: account.paymentMethodId ?? '',
      isQris: isQris,
      existing: account,
    );
  }

  void _showDialog({
    required String paymentMethodId,
    required bool isQris,
    BankAccountModel? existing,
  }) {
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AddBankAccountDialog(
        initialAccount: existing,
        defaultPaymentMethodId: paymentMethodId,
        isQris: isQris,
        title: isQris
            ? (isEdit ? 'Edit QRIS' : 'Tambah QRIS')
            : (isEdit ? 'Edit Rekening Bank' : 'Tambah Rekening Bank'),
        submitLabel: isEdit ? 'Simpan Perubahan' : 'Tambah',
        onSubmit: (account) async {
          bool result;
          if (isEdit && existing.id != null) {
            result = await _controller.updateBankAccount(existing.id!, account);
          } else {
            result = await _controller.addBankAccount(account);
          }

          if (!mounted) return;

          if (result) {
            await SweetAlertDialog.showSuccess(
              context: context,
              title: 'Berhasil',
              message: isEdit
                  ? 'Data berhasil diperbarui.'
                  : 'Data berhasil ditambahkan.',
            );
          } else {
            await SweetAlertDialog.showSuccess(
              context: context,
              title: 'Gagal',
              message: _controller.errorMessage ?? 'Gagal menyimpan data.',
            );
          }
        },
      ),
    );
  }

  Future<void> _handleToggleActive(BankAccountModel account) async {
    if (account.id == null) return;
    final newActive = !(account.isActive == true);
    await _controller.toggleBankAccountActive(account.id!, newActive);
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

            if (_controller.errorMessage != null && accounts.isEmpty) {
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
                        Row(
                          children: [
                            _AddButton(
                              label: 'Bank',
                              icon: Icons.account_balance,
                              onTap: _handleAddBankAccount,
                            ),
                            const SizedBox(width: 8),
                            _AddButton(
                              label: 'QRIS',
                              icon: Icons.qr_code,
                              onTap: _handleAddQris,
                            ),
                          ],
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
                            accountNumber: account.accountNumber ?? '',
                            accountHolder: account.bankName ?? '-',
                            qrisImageUrl: account.qrisImageUrl,
                            isActive: account.isActive == true,
                            onEdit: () => _handleEdit(account),
                            onToggleActive: () => _handleToggleActive(account),
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
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

class _AddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AddButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0C844C),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              '+ $label',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
