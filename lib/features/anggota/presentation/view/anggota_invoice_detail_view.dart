import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import 'package:persis_app/features/bendahara_pc/data/datasources/payment_method_remote_datasources.dart';
import 'package:persis_app/features/bendahara_pc/data/models/payment_method_model.dart';
import 'package:persis_app/features/bendahara_pj/data/models/transaction_model.dart';
import 'package:persis_app/features/bendahara_pj/presentation/controller/pj_invoice_controller.dart';

class AnggotaInvoiceDetailView extends StatefulWidget {
  const AnggotaInvoiceDetailView({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  State<AnggotaInvoiceDetailView> createState() =>
      _AnggotaInvoiceDetailViewState();
}

class _AnggotaInvoiceDetailViewState extends State<AnggotaInvoiceDetailView> {
  List<PaymentMethodModel> _paymentMethods = [];
  String? _resolvedAccByName;
  bool _loadingMethods = true;

  TransactionModel get transaction => widget.transaction;

  @override
  void initState() {
    super.initState();
    _fetchPaymentMethods();
    _resolveAccByName();
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final ds = PaymentMethodRemoteDataSource(AppConfig.baseUrl);
      _paymentMethods = await ds.getAllPaymentMethods();
    } catch (_) {
      _paymentMethods = [];
    }
    if (mounted) setState(() => _loadingMethods = false);
  }

  Future<void> _resolveAccByName() async {
    final accBy = transaction.accBy?.trim();
    if (accBy == null || accBy.isEmpty) return;
    if (!RegExp(r'^[a-f0-9]{24}$').hasMatch(accBy)) {
      _resolvedAccByName = accBy;
      return;
    }
    try {
      final userDs = UserRemoteDataSource(AppConfig.baseUrl);
      final user = await userDs.getOneUsers(accBy);
      final name = user.fullname?.trim() ?? user.name?.trim();
      if (name != null && name.isNotEmpty && mounted) {
        setState(() => _resolvedAccByName = name);
      }
    } catch (_) {}
  }

  String _resolvePaymentMethod(String? id) {
    if (id == null || id.isEmpty) return '-';
    final match = _paymentMethods.where((pm) => pm.id == id);
    if (match.isNotEmpty) {
      final code = match.first.code?.trim();
      if (code != null && code.isNotEmpty) return code;
    }
    return id;
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

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day} ${_monthNames[dt.month]} ${dt.year}';
  }

  String _paymentMethodLabel(TransactionModel tx) {
    return _resolvePaymentMethod(tx.paymentMethodId);
  }

  String _accStatusLabel(String? accStatus, {String? rejectionReason}) {
    final s = (accStatus ?? '').toLowerCase().trim();
    switch (s) {
      case 'acc_pc':
        return 'Disetujui PC';
      case 'acc_pd':
        return 'Disetujui PD';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        final reason = rejectionReason ?? '';
        return reason.isNotEmpty ? 'Ditolak — $reason' : 'Ditolak';
      case 'pending':
      case 'acc_pj':
        return 'Menunggu ACC';
      default:
        return s.isNotEmpty ? s : '-';
    }
  }

  Color _accStatusColor(String? accStatus) {
    final s = (accStatus ?? '').toLowerCase().trim();
    switch (s) {
      case 'acc_pc':
      case 'acc_pd':
      case 'approved':
        return const Color(0xFF10B367);
      case 'rejected':
        return const Color(0xFFE53935);
      case 'pending':
      case 'acc_pj':
        return const Color(0xFFF57F17);
      default:
        return const Color(0xFF6A6A6A);
    }
  }

  IconData _accStatusIcon(String? accStatus) {
    final s = (accStatus ?? '').toLowerCase().trim();
    switch (s) {
      case 'acc_pc':
      case 'acc_pd':
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      case 'acc_pj':
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceData = _buildInvoiceData();

    final formattedTotal = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(transaction.totalAmount ?? 0);

    final statusColor = _accStatusColor(transaction.accStatus);
    final isRejected =
        (transaction.accStatus ?? '').toLowerCase().trim() == 'rejected';
    final isPending =
        (transaction.accStatus ?? '').toLowerCase().trim() == 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(
            color: Color(0xFF073D4D),
            fontSize: 20,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF073D4D), Color(0xFF0C844C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22073D4D),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Transaksi Non-Tunai',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _accStatusIcon(transaction.accStatus),
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _accStatusLabel(
                              transaction.accStatus,
                              rejectionReason: transaction.rejectionReason,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  invoiceData.memberName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((transaction.npa ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'NPA: ${transaction.npa}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          _DetailCard(
            title: 'Ringkasan',
            child: Column(
              children: [
                _DetailRow(
                  label: 'Metode',
                  value: _paymentMethodLabel(transaction),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Tanggal',
                  value: _formatDate(transaction.createdAt),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Status',
                  value: _accStatusLabel(transaction.accStatus),
                  valueColor: statusColor,
                  valueBold: true,
                ),
                if (transaction.accBy != null &&
                    transaction.accBy!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _DetailRow(
                    label: 'Di-ACC oleh',
                    value: _resolvedAccByName ?? transaction.accBy!.trim(),
                  ),
                ],
                if (transaction.rejectionReason != null &&
                    transaction.rejectionReason!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _DetailRow(
                    label: 'Catatan',
                    value: transaction.rejectionReason!.trim(),
                    valueColor: isRejected
                        ? const Color(0xFFE53935)
                        : const Color(0xFF6A6A6A),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_itemBuktiUrls.isNotEmpty) ...[
            for (final url in _itemBuktiUrls)
              _DetailCard(
                title: 'Bukti Pembayaran',
                child: GestureDetector(
                  onTap: () => _showFullImage(context, url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      AppConfig.fullUrl(url),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: const Color(0xFFF6F6F6),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                color: Color(0xFFA1A1A1),
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Gambar tidak tersedia',
                                style: TextStyle(
                                  color: Color(0xFFA1A1A1),
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 120,
                          color: const Color(0xFFF6F6F6),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF10B367),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
          if (invoiceData.hasData)
            _DetailCard(
              title: 'Rincian Iuran',
              child: Column(
                children: [
                  ...invoiceData.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DetailRow(
                        label: item.label,
                        value: formatRupiah(item.amount),
                      ),
                    ),
                  ),
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: Color(0xFF073D4D),
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        formattedTotal,
                        style: const TextStyle(
                          color: Color(0xFF0C844C),
                          fontSize: 20,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if ((transaction.bankName ?? '').isNotEmpty ||
              (transaction.bankAccountName ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            _DetailCard(
              title: 'Informasi Pembayaran',
              child: Column(
                children: [
                  if ((transaction.bankName ?? '').isNotEmpty)
                    _DetailRow(label: 'Bank', value: transaction.bankName!),
                  if ((transaction.bankAccountName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Atas Nama',
                      value: transaction.bankAccountName!,
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (isPending)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC02)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Transaksi ini masih menunggu verifikasi dari bendahara. '
                      'Anda tidak dapat membuat transaksi non-tunai baru '
                      'hingga transaksi ini disetujui atau ditolak.',
                      style: TextStyle(
                        color: Color(0xFF795548),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Kembali',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  List<String> get _itemBuktiUrls {
    final items = transaction.items;
    if (items == null || items.isEmpty) return [];
    return items
        .map((item) => item.buktiUrl?.trim())
        .where((url) => url != null && url.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList();
  }

  PjInvoiceData _buildInvoiceData() {
    final member = UserModel(
      fullname: transaction.memberName ?? 'Anggota',
      name: transaction.memberName,
      npa: transaction.npa,
    );

    return PjInvoiceData.fromTransaction(
      member: member,
      transaction: transaction,
    );
  }

  void _showFullImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImageView(imageUrl: AppConfig.fullUrl(url)),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F073D4D),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF073D4D),
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6A6A6A),
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF1B1B1B),
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FullImageView extends StatelessWidget {
  const _FullImageView({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bukti Pembayaran',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 16,
          ),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Gambar tidak dapat dimuat',
                    style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }
}
