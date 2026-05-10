import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_invoice_controller.dart';

class PjInvoiceViewPage extends StatefulWidget {
  const PjInvoiceViewPage({super.key, required this.invoiceData});

  final PjInvoiceData invoiceData;

  @override
  State<PjInvoiceViewPage> createState() => _PjInvoiceViewPageState();
}

class _PjInvoiceViewPageState extends State<PjInvoiceViewPage> {
  late final PjInvoiceController _controller;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = PjInvoiceController(widget.invoiceData);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Invoice Iuran',
          style: TextStyle(
            color: Color(0xFF073D4D),
            fontSize: 20,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share ke WhatsApp',
            icon: const Icon(Icons.share_rounded, color: Color(0xFF25D366)),
            onPressed: _controller.isSharing
                ? null
                : () async {
                    final success = await _controller.shareInvoiceAsImage(
                      _boundaryKey,
                    );
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _controller.errorMessage ??
                                'Gagal membagikan invoice.',
                          ),
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              RepaintBoundary(
                key: _boundaryKey,
                child: Container(
                  color: const Color(0xFFF4F7FA),
                  child: Column(
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
                            const Text(
                              'Invoice berhasil dibuat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _controller.invoiceData.invoiceNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _controller.invoiceData.memberName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Periode ${_controller.invoiceData.monthLabelSummary} ${_controller.invoiceData.year}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InvoiceCard(
                        title: 'Ringkasan',
                        child: Column(
                          children: [
                            _InvoiceRow(
                              label: 'Nama',
                              value: _controller.invoiceData.memberName,
                            ),
                            const SizedBox(height: 10),
                            _InvoiceRow(
                              label: 'Kode / NPA',
                              value: _controller.invoiceData.memberCode,
                            ),
                            const SizedBox(height: 10),
                            _InvoiceRow(
                              label: 'Tanggal',
                              value: _controller.invoiceData.generatedAtLabel,
                            ),
                            const SizedBox(height: 10),
                            _InvoiceRow(
                              label: 'Status',
                              value: _controller.invoiceData.statusLabel,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InvoiceCard(
                        title: 'Rincian Iuran',
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index < _controller.invoiceData.items.length;
                              index++
                            ) ...[
                              _InvoiceLineItemTile(
                                item: _controller.invoiceData.items[index],
                              ),
                              if (index !=
                                  _controller.invoiceData.items.length - 1)
                                const SizedBox(height: 12),
                            ],
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
                                  _controller.invoiceData.totalFormatted,
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
                    ],
                  ),
                ),
              ),
              if (_controller.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _controller.errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB31012),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _controller.isSharing
                          ? null
                          : () async {
                              final success = await _controller
                                  .saveInvoiceToGallery(_boundaryKey);
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Invoice berhasil disimpan ke galeri.',
                                    ),
                                    backgroundColor: Color(0xFF0C844C),
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _controller.errorMessage ??
                                          'Gagal menyimpan gambar.',
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Generate PNG (Download)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF073D4D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _controller.isSharing
                          ? null
                          : () async {
                              final success = await _controller
                                  .shareInvoiceAsText();
                              if (!success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _controller.errorMessage ??
                                          'Gagal membuka WhatsApp.',
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: _controller.isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded),
                      label: Text(
                        _controller.isSharing
                            ? 'Memproses...'
                            : 'Kirim ke WhatsApp (Teks)',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.title, required this.child});

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

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.label, required this.value});

  final String label;
  final String value;

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
            style: const TextStyle(
              color: Color(0xFF1B1B1B),
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _InvoiceLineItemTile extends StatelessWidget {
  const _InvoiceLineItemTile({required this.item});

  final PjInvoiceLineItem item;

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(item.amount);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EEF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0C844C).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF0C844C),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF073D4D),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_monthName(item.month)} ${item.year}',
                  style: const TextStyle(
                    color: Color(0xFF6A6A6A),
                    fontFamily: 'Poppins',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: const TextStyle(
              color: Color(0xFF1B1B1B),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _monthName(int month) {
  const monthNames = [
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

  if (month < 1 || month > 12) {
    return '-';
  }

  return monthNames[month - 1];
}
