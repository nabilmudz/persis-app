import 'dart:io';
import 'package:flutter/material.dart';
import 'package:persis_app/app/routes.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../controller/pembayaran_controller.dart';
import '../widgets/bulan_iuran_bottom_sheet.dart';

class QrisView extends StatefulWidget {
  const QrisView({super.key});

  @override
  State<QrisView> createState() => _QrisViewState();
}

class _QrisViewState extends State<QrisView> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PembayaranController>().fetchQrisDetail();
    });
  }

  Future<void> _pickImage(PembayaranController controller) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      controller.setBuktiFile(File(picked.path));
      await controller.uploadBukti();
    }
  }

  Future<void> _showMonthPicker(
    BuildContext context,
    bool isMulai,
    PembayaranController controller,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BulanIuranBottomSheet(),
    );
    if (result != null) {
      if (isMulai) {
        controller.setPeriodeMulai(result);
      } else {
        controller.setPeriodeAkhir(result);
      }
    }
  }

  void _handleSubmit(
    BuildContext context,
    PembayaranController controller,
  ) async {
    final userId = '123';

    await controller.submitQris(anggotaId: userId);

    if (!mounted) return;

    if (controller.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti pembayaran berhasil dikirim!'),
          backgroundColor: Color(0xFF10B367),
        ),
      );
      Navigator.pop(context);
    } else if (controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );

    return Consumer<PembayaranController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'QRIS',
              style: TextStyle(
                color: Color(0xFF363636),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFD0D0D0), height: 1),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD0D0D0)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.calendar_month, color: Color(0xFF074D2C)),
                          SizedBox(width: 8),
                          Text(
                            'Pilih Periode Iuran',
                            style: TextStyle(
                              color: Color(0xFF074D2C),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPeriodeSelector(
                        controller.periodeMulai.isEmpty
                            ? 'Pilih bulan mulai'
                            : controller.periodeMulai,
                        () => _showMonthPicker(context, true, controller),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '-',
                          style: TextStyle(
                            fontSize: 24,
                            color: Color(0xFF6C6C6C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildPeriodeSelector(
                        controller.periodeAkhir.isEmpty
                            ? 'Pilih bulan akhir'
                            : controller.periodeAkhir,
                        () => _showMonthPicker(context, false, controller),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Scan QRIS',
                  style: TextStyle(
                    color: Color(0xFF074D2C),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF074D2C), Color(0xFF10B367)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatCurrency.format(controller.totalTagihan),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.labelPeriode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 215,
                    height: 215,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: controller.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF10B367),
                            ),
                          )
                        : controller.qrisImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              controller.qrisImageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.qr_code_2,
                                size: 180,
                                color: Colors.black87,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.qr_code_2,
                            size: 180,
                            color: Colors.black87,
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Upload Bukti Pembayaran',
                  style: TextStyle(
                    color: Color(0xFF074D2C),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: controller.isUploading
                      ? null
                      : () => _pickImage(controller),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      border: Border.all(
                        color: controller.buktiFile != null
                            ? const Color(0xFF10B367)
                            : const Color(0xFFB4B4B4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: controller.isUploading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF10B367),
                            ),
                          )
                        : controller.buktiFile != null
                        ? Column(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 50,
                                color: Color(0xFF10B367),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                controller.buktiFile!.path.split('/').last,
                                style: const TextStyle(
                                  color: Color(0xFF6B6B6B),
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Ketuk untuk ganti',
                                style: TextStyle(
                                  color: Color(0xFF10B367),
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            children: [
                              Icon(
                                Icons.upload_file,
                                size: 50,
                                color: Color(0xFF10B367),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Ketuk untuk Unggah Bukti Transfer',
                                style: TextStyle(
                                  color: Color(0xFF6B6B6B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'JPG, PNG, Max 5mb',
                                style: TextStyle(
                                  color: Color(0xFF6B6B6B),
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: controller.buktiUrl == null
                          ? [const Color(0xFFAAAAAA), const Color(0xFFCCCCCC)]
                          : [const Color(0xFF074D2C), const Color(0xFF10B367)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ElevatedButton(
                    onPressed:
                        controller.isLoading || controller.buktiUrl == null
                        ? null
                        : () => _handleSubmit(context, controller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Kirim Bukti Pembayaran',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                  ),
                ),
              ),
              const RoleBottomNavigationBar(
                currentRoute: AppRoutes.anggota,
                homeRoute: AppRoutes.anggota,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodeSelector(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          border: Border.all(color: const Color(0xFFB4B4B4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF6C6C6C),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6C6C6C)),
          ],
        ),
      ),
    );
  }
}
