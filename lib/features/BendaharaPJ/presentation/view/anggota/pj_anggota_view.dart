import 'package:flutter/material.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import '../../controller/pj_controller.dart';
import '../../widgets/pj_verification_member_card.dart';
import '../tunai/pj_verif_tunai_view.dart';
import 'pj_detail_anggota_view.dart';

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
    widget.controller.loadInitialData();
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
        actions: [],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          if (widget.controller.isLoading &&
              widget.controller.members.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = widget.controller.errorMessage;
          if (error != null && widget.controller.members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: widget.controller.loadInitialData,
                      child: const Text('Muat Ulang'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<UserModel> members = widget.controller.filterMembers(
            _searchController.text,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      final memberId = member.id ?? '';
                      final totalTunggakan = memberId.isEmpty
                          ? 0.0
                          : widget.controller.tunggakanNominalByMember(
                              memberId,
                            );
                      final iuranStatuses = memberId.isEmpty
                          ? const <MemberIuranStatusModel>[]
                          : widget.controller.memberIuranStatusItems(
                              memberId,
                              limit: 4,
                            );
                      final cardStatus = memberId.isEmpty
                          ? null
                          : widget.controller.memberCardStatus(memberId);

                      return PjVerificationMemberCard(
                        name: widget.controller.memberDisplayName(member),
                        subtitle: widget.controller.memberDisplayCode(member),
                        isTunggakan: totalTunggakan > 0,
                        showTotal: true,
                        total: _formatCurrency(totalTunggakan),
                        iuranStatuses: iuranStatuses,
                        cardStatus: cardStatus,
                        onTapCekKartu: () {
                          if (memberId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ID anggota tidak tersedia.'),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PjVerifTunaiViewPage(
                                controller: widget.controller,
                                member: member,
                              ),
                            ),
                          );
                        },
                        onTapDetail: () {
                          showDialog(
                            context: context,
                            builder: (_) => PjDetailAnggotaView(member: member),
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
