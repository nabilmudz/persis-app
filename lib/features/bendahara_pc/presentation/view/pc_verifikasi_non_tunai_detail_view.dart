import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persis_app/core/config/config.dart';
import '../controller/pc_controller.dart';
import '../../../bendahara_pj/data/models/transaction_model.dart';

class PcVerifikasiNonTunaiDetailView extends StatefulWidget {
  final TransactionModel transaction;
  final PcController controller;

  const PcVerifikasiNonTunaiDetailView({
    super.key,
    required this.transaction,
    required this.controller,
  });

  @override
  State<PcVerifikasiNonTunaiDetailView> createState() =>
      _PcVerifikasiNonTunaiDetailViewState();
}

class _PcVerifikasiNonTunaiDetailViewState
    extends State<PcVerifikasiNonTunaiDetailView> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    final tx = widget.transaction;
    final name = tx.memberName ?? tx.creatorId ?? '-';
    final date = tx.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(tx.createdAt!))
        : '-';
    final amount = tx.totalAmount ?? 0;
    final method = tx.bankName ?? 'Non-Tunai';
    final buktiUrl =
        tx.proofUrl ??
        (tx.items?.isNotEmpty == true ? tx.items!.first.buktiUrl : null);
    final isPending = (tx.accStatus ?? '').toLowerCase() == 'pending';
    final monthLabel = _resolveMonthsLabel(tx);

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
          'Detail Verifikasi',
          style: TextStyle(
            color: Color(0xFF363636),
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFE65100),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Transaksi ini memerlukan persetujuan PC.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Nama', name),
                  const Divider(height: 20),
                  _infoRow('Metode', method),
                  const Divider(height: 20),
                  _infoRow('Tanggal', date),
                  const Divider(height: 20),
                  _infoRow('Total', formatCurrency.format(amount)),
                  if (monthLabel.isNotEmpty) ...[
                    const Divider(height: 20),
                    _infoRow('Periode Iuran', monthLabel),
                  ],
                  if (tx.npa != null && tx.npa!.isNotEmpty) ...[
                    const Divider(height: 20),
                    _infoRow('NPA', tx.npa!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (buktiUrl != null && buktiUrl.isNotEmpty) ...[
              const Text(
                'Bukti Pembayaran',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF363636),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: InteractiveViewer(
                        child: Image.network(
                          AppConfig.fullUrl(buktiUrl),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            height: 300,
                            color: const Color(0xFFF0F0F0),
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 50),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    AppConfig.fullUrl(buktiUrl),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: const Color(0xFFF0F0F0),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Color(0xFFB4B4B4),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Bukti tidak tersedia',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFFB4B4B4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 200,
                        color: const Color(0xFFF0F0F0),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () => _handleReject(),
                      icon: const Icon(Icons.close, color: Color(0xFFB31012)),
                      label: const Text(
                        'Tolak',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB31012),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFB31012)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _handleApprove(),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'ACC',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C844C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  static const _monthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String _resolveMonthsLabel(TransactionModel tx) {
    final items = tx.items;
    if (items == null || items.isEmpty) return '';
    final months = <int>[];
    int? year;
    for (final item in items) {
      final pm = item.periodMonth;
      final py = item.periodYear;
      if (pm != null && pm >= 1 && pm <= 12 && py != null) {
        months.add(pm);
        year = py;
      }
    }
    if (months.isEmpty) return '';
    months.sort();
    year ??= DateTime.now().year;
    final label = months.map((m) => _monthNames[m]).join(', ');
    return '$label $year';
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF6A6A6A),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF363636),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleApprove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi ACC',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        content: const Text(
          'Setujui transaksi ini? Status akan berubah menjadi Disetujui PC.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C844C),
            ),
            child: const Text(
              'Ya, ACC',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    final success = await widget.controller.approveTransaction(
      widget.transaction.id ?? '',
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi disetujui.'),
          backgroundColor: Color(0xFF10B367),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyetujui transaksi.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleReject() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RejectReasonSheet(),
    );

    if (reason == null || reason.isEmpty || !mounted) return;

    setState(() => _isProcessing = true);

    final success = await widget.controller.rejectTransaction(
      widget.transaction.id ?? '',
      reason,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi ditolak.'),
          backgroundColor: Color(0xFFB31012),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menolak transaksi.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _RejectReasonSheet extends StatefulWidget {
  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  String? _selectedPreset;
  final _customController = TextEditingController();

  static const _presets = [
    'Bukti tidak jelas',
    'Nominal tidak sesuai',
    'Bukti tidak valid / manipulasi',
    'Data tidak lengkap',
    'Pembayaran ganda',
  ];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D0D0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Alasan Penolakan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF363636),
            ),
          ),
          const SizedBox(height: 16),
          ...(_presets.map(
            (preset) => RadioListTile<String>(
              title: Text(
                preset,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
              value: preset,
              groupValue: _selectedPreset,
              onChanged: (v) {
                setState(() {
                  _selectedPreset = v;
                  _customController.clear();
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          )),
          const SizedBox(height: 8),
          TextField(
            controller: _customController,
            onChanged: (v) {
              if (v.isNotEmpty) setState(() => _selectedPreset = null);
            },
            decoration: const InputDecoration(
              hintText: 'Atau tulis alasan lain...',
              hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            maxLines: 2,
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final reason = _customController.text.isNotEmpty
                    ? _customController.text.trim()
                    : _selectedPreset;
                if (reason != null && reason.isNotEmpty) {
                  Navigator.pop(context, reason);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB31012),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Konfirmasi Tolak',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
