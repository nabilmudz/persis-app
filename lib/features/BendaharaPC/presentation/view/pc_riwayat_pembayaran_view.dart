import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../controller/pc_controller.dart';
import '../../../BendaharaPJ/data/models/transaction_item_detail_model.dart';
import '../../../BendaharaPJ/presentation/controller/pj_transaction_item_controller.dart';

class PcRiwayatPembayaranViewPage extends StatefulWidget {
  final PcController controller;

  const PcRiwayatPembayaranViewPage({super.key, required this.controller});

  @override
  State<PcRiwayatPembayaranViewPage> createState() => _PcRiwayatPembayaranViewPageState();
}

class _PcRiwayatPembayaranViewPageState extends State<PcRiwayatPembayaranViewPage> {
  late final PjTransactionItemController _itemController;
  bool _isLoading = true;

  static const _statusLunas = {
    'paid',
    'lunas',
    'selesai',
    'success',
    'completed',
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _itemController = PjTransactionItemController();
    _loadRiwayatLunasKolektif();
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _loadRiwayatLunasKolektif() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _itemController.loadByUser('all_members', forceRefresh: false);
    } catch (e) {
      debugPrint('Error membaca riwayat iuran: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<TransactionItemDetailModel> _getLunasItems() {
    return _itemController.items.where((tx) {
      final status = (tx.status ?? '').trim().toLowerCase();
      return _statusLunas.any((s) => status.contains(s));
    }).toList();
  }

  double _hitungTotal(List<TransactionItemDetailModel> items) {
    return items.fold(0.0, (sum, tx) => sum + (tx.amount ?? 0));
  }

  @override
  Widget build(BuildContext context) {
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
          'Riwayat Pembayaran',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF189D4A)))
          : ListenableBuilder(
              listenable: _itemController,
              builder: (context, _) {
                final transactions = _getLunasItems();
                final totalAmount = _hitungTotal(transactions);

                return RefreshIndicator(
                  color: const Color(0xFF189D4A),
                  onRefresh: _loadRiwayatLunasKolektif,
                  child: Column(
                    children: [

                      // Kartu total hanya muncul kalau datanya ada
                      if (transactions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _TotalCard(totalAmount: totalAmount),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Daftar transaksi / Empty State Tengah Layar
                      Expanded(
                        child: transactions.isEmpty
                            ? const _EmptyState() 
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: transactions.length,
                                itemBuilder: (context, index) => _RiwayatCard(item: transactions[index]),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ── Sub-widgets Komponen Pelengkap Tampilan ──

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalAmount});
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalAmount);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF189D4A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Pembayaran Lunas', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF7F7F7F), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(formatted, style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF189D4A), fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  const _RiwayatCard({required this.item});
  final TransactionItemDetailModel item;

  static const _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.amount ?? 0);
    
    String label = item.description ?? 'Iuran Anggota';
    final month = item.resolveMonth();
    final year = item.resolveYear();
    if (month != null && year != null && month >= 1 && month <= 12) {
      label = 'Iuran ${_monthNames[month - 1]} $year';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE9FFE9), border: Border.all(color: const Color(0xFF074D2C), width: 1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.check_circle, color: Color(0xFF10B367), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF074D2C), fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Sistem InfaQu', style: TextStyle(color: Color(0xFF6A6A6A), fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Lunas', style: TextStyle(color: Color(0xFF10B367), fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(formatted, style: const TextStyle(color: Color(0xFF6A6A6A), fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Tidak ada riwayat pembayaran lunas.', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
        ],
      ),
    );
  }
}
