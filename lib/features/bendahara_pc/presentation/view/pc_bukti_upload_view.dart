import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persis_app/features/bendahara_pc/presentation/controller/pc_bukti_controller.dart';

class PcBuktiUploadView extends StatefulWidget {
  final String itemId;
  final String memberName;
  final String description;
  final int amount;
  final String? existingBuktiUrl;

  const PcBuktiUploadView({
    super.key,
    required this.itemId,
    required this.memberName,
    required this.description,
    required this.amount,
    this.existingBuktiUrl,
  });

  @override
  State<PcBuktiUploadView> createState() => _PcBuktiUploadViewState();
}

class _PcBuktiUploadViewState extends State<PcBuktiUploadView> {
  late final PcBuktiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PcBuktiController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(widget.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Bukti Bayar',
          style: TextStyle(
            color: Color(0xFF363636),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFD0D0D0), height: 1.0),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Transaksi',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF363636),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Nama', value: widget.memberName),
                      _DetailRow(label: 'Deskripsi', value: widget.description),
                      _DetailRow(label: 'Jumlah', value: formatted),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.existingBuktiUrl != null &&
                    widget.existingBuktiUrl!.isNotEmpty) ...[
                  const Text(
                    'Bukti Saat Ini',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF363636),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: Image.network(
                            widget.existingBuktiUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Gagal memuat gambar.',
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.existingBuktiUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: const Color(0xFFEDEDED),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Upload Bukti Baru',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF363636),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_controller.selectedFile != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _controller.selectedFile!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _controller.clearSelection(),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text(
                      'Hapus Gambar',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_controller.selectedFile == null)
                  GestureDetector(
                    onTap: () => _controller.pickImage(),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD0D0D0),
                          width: 1.5,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: Color(0xFF6A6A6A),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pilih Gambar dari Galeri',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF6A6A6A),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                if (_controller.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _controller.errorMessage!,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_controller.uploadedUrl != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Bukti berhasil diupload!',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_controller.selectedFile != null) ...[
                  if (_controller.uploadedUrl == null)
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _controller.isUploading
                            ? null
                            : () async {
                                final url = await _controller.uploadBukti();
                                if (url != null && mounted) {
                                  await _controller.updateTransactionItemBukti(
                                    itemId: widget.itemId,
                                    buktiUrl: url,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF189D4A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _controller.isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: Text(
                          _controller.isUploading
                              ? 'Mengupload...'
                              : 'Upload Bukti',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  if (_controller.uploadedUrl != null && _controller.isPatching)
                    const SizedBox(height: 16),
                  if (_controller.uploadedUrl != null && _controller.isPatching)
                    const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (_controller.uploadedUrl != null &&
                      !_controller.isPatching)
                    const SizedBox(height: 16),
                  if (_controller.uploadedUrl != null &&
                      !_controller.isPatching)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Text(
                        'Bukti berhasil disimpan!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
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
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF363636),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
