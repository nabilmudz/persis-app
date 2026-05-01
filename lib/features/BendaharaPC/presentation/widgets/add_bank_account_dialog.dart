import 'package:flutter/material.dart';
import '../../../BendaharaPC/data/models/bank_account_model.dart';

class AddBankAccountDialog extends StatefulWidget {
  final Function(BankAccountModel) onSubmit;
  final BankAccountModel? initialAccount;
  final String? defaultRegionId;
  final String? defaultPaymentMethodId;
  final String title;
  final String submitLabel;

  const AddBankAccountDialog({
    super.key,
    required this.onSubmit,
    this.defaultRegionId,
    this.defaultPaymentMethodId,
    this.initialAccount,
    this.title = 'Tambah Rekening Bank',
    this.submitLabel = 'Tambah Rekening',
  });

  @override
  State<AddBankAccountDialog> createState() => _AddBankAccountDialogState();
}

class _AddBankAccountDialogState extends State<AddBankAccountDialog> {
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController(
      text: widget.initialAccount?.bankName ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.initialAccount?.accountNumber ?? '',
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: Color(0xFF7A7A7A),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: Color(0xFFB8B8B8),
      ),
      filled: true,
      fillColor: const Color(0xFFF7F9FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE3E8EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE3E8EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0C844C), width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _handleSubmit() {
    if (_bankNameController.text.isEmpty ||
        _accountNumberController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua field harus diisi')));
      return;
    }

    setState(() => _isLoading = true);

    final newAccount = BankAccountModel(
      id: widget.initialAccount?.id,
      regionId: widget.initialAccount?.regionId ?? widget.defaultRegionId,
      bankName: _bankNameController.text,
      accountNumber: _accountNumberController.text,
      paymentMethodId:
          widget.initialAccount?.paymentMethodId ??
          widget.defaultPaymentMethodId,
      qrisImageUrl: widget.initialAccount?.qrisImageUrl,
      isActive: widget.initialAccount?.isActive ?? true,
    );

    widget.onSubmit(newAccount);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialAccount != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0C844C), Color(0xFF16A765)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            isEditing
                                ? 'Perbarui data rekening yang sudah tersimpan.'
                                : 'Isi data rekening dengan rapi agar mudah dipilih saat transaksi.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontFamily: 'Poppins',
                              color: Color(0xFFE7FFF3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBFD),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE8EDF2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Rekening',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2F3A45),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _bankNameController,
                            decoration: _fieldDecoration(
                              label: 'Nama Bank',
                              hint: 'Contoh: Bank BRI',
                            ),
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _accountNumberController,
                            keyboardType: TextInputType.number,
                            decoration: _fieldDecoration(
                              label: 'Nomor Rekening',
                              hint: 'Contoh: 00998877665544',
                            ),
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF667085),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C844C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                          ),
                          child: _isLoading
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
                                  widget.submitLabel,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
