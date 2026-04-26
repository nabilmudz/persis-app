import 'package:flutter/material.dart';
import 'package:persis_app/features/anggota/data/models/anggota_model.dart';
import '../controller/pj_controller.dart';
import '../widgets/pj_verification_member_card.dart';
import 'pj_cart_view.dart';
import 'pj_verif_view.dart';

class PjAnggotaViewPage extends StatefulWidget {
  final PjController controller;

  const PjAnggotaViewPage({super.key, required this.controller});

  @override
  State<PjAnggotaViewPage> createState() => _PjAnggotaViewPageState();
}

class _PjAnggotaViewPageState extends State<PjAnggotaViewPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Data Anggota',
          style: TextStyle(
            color: Color(0xFF073D4D),
            fontSize: 20,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD0D0D0)),
        ),
        actions: [
          IconButton(
            tooltip: 'Lihat keranjang',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PjCartViewPage(controller: widget.controller),
                ),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (widget.controller.cartItemCount > 0)
                  Positioned(
                    right: -6,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB31012),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.controller.cartItemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          final List<AnggotaModel> members = widget.controller.filterMembers(
            _searchController.text,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBEE7CC)),
                  ),
                  child: Text(
                    'Keranjang aktif: ${widget.controller.cartItemCount} item • Total ${_formatCurrency(widget.controller.cartTotalNominal)}',
                    style: const TextStyle(
                      color: Color(0xFF0B6A3B),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE6F0),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF49454F),
                      fontFamily: 'Roboto',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, no anggota, lokasi',
                      hintStyle: const TextStyle(
                        color: Color(0xFF49454F),
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF49454F),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.tune, color: Color(0xFF49454F)),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(color: Color(0xFF5DB1BA)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                if (members.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Data anggota tidak ditemukan',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final totalTunggakan = widget.controller
                          .tunggakanNominalByMember(member.id);

                      return PjVerificationMemberCard(
                        name: member.nama,
                        isTunggakan: totalTunggakan > 0,
                        showTotal: true,
                        total: _formatCurrency(totalTunggakan),
                        onTapCekKartu: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PjVerifViewPage(
                                controller: widget.controller,
                                member: member,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatCurrency(double amount) {
    final number = amount.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < number.length; i++) {
      final reverseIndex = number.length - i;
      buffer.write(number[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp. ${buffer.toString()}';
  }
}
