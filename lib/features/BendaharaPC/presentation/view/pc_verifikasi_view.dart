import 'package:flutter/material.dart';
import '../controller/pc_controller.dart';
import 'pc_detail_verifikasi_view.dart';

class PcVerifikasiPage extends StatefulWidget {
  const PcVerifikasiPage({super.key});

  @override
  State<PcVerifikasiPage> createState() => _PcVerifikasiPageState();
}

class _PcVerifikasiPageState extends State<PcVerifikasiPage>
    with SingleTickerProviderStateMixin {
  late final PcController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = PcController();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.loadTransactions();
    if (!mounted) return;
    if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage!)),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF074D2C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verifikasi Setoran Kas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF074D2C),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final perluAccList = _controller.filteredVerifikasiItems(
                    category: 'Belum Diverifikasi',
                    query: '',
                  );
                  final selesaiList = _controller.filteredVerifikasiItems(
                    category: 'Sudah Diverifikasi',
                    query: '',
                  );

                  return TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF074D2C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF6A6A6A),
                    labelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(text: 'Perlu ACC (${perluAccList.length})'),
                      Tab(text: 'Selesai (${selesaiList.length})'),
                    ],
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                if (_controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0C844C)),
                  );
                }

                final perluAccList = _controller.filteredVerifikasiItems(
                  category: 'Belum Diverifikasi',
                  query: '',
                );
                final selesaiList = _controller.filteredVerifikasiItems(
                  category: 'Sudah Diverifikasi',
                  query: '',
                );

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(perluAccList, isVerified: false),
                    _buildList(selesaiList, isVerified: true),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<PcVerifikasiItem> items, {required bool isVerified}) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data.',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PcDetailVerifikasiPage(
                  item: item,
                  controller: _controller,
                ),
              ),
            );
            if (result == true) _loadData();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Garis kiri warna status
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: isVerified
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF39C12),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Baris atas: nama member + nominal
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name, // ✅ nama member, bukan ID
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF142B42),
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.price,
                                style: TextStyle(
                                  color: isVerified
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFD35400),
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Kode transaksi (pendek) + tanggal
                          Text(
                            'Trx #${item.txCode} • ${item.date}',
                            style: const TextStyle(
                              color: Color(0xFF7F8C8D),
                              fontFamily: 'Poppins',
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Baris bawah: NPA/ID number + badge status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.account_circle_outlined,
                                    size: 16,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.idNumber, // NPA atau '-'
                                    style: const TextStyle(
                                      color: Color(0xFF7F8C8D),
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.payments_outlined,
                                    size: 16,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.paymentMethod,
                                    style: const TextStyle(
                                      color: Color(0xFF7F8C8D),
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isVerified
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isVerified
                                          ? Icons.check_circle_outline
                                          : Icons.error_outline,
                                      size: 12,
                                      color: isVerified
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFD35400),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isVerified ? 'Sudah ACC' : 'Belum ACC',
                                      style: TextStyle(
                                        color: isVerified
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFFD35400),
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
