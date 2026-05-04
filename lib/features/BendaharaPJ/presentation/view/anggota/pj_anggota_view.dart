import 'package:flutter/material.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import '../../controller/pj_controller.dart';
import '../../widgets/pj_verification_member_card.dart';
import 'pj_verif_tunai_view.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/tunai/pending_transaction_view.dart';
import '../anggota/pj_detail_anggota_view.dart';

class PjAnggotaViewPage extends StatefulWidget {
  final PjController controller;

  const PjAnggotaViewPage({super.key, required this.controller});

  @override
  State<PjAnggotaViewPage> createState() => _PjAnggotaViewPageState();
}

class _PjAnggotaViewPageState extends State<PjAnggotaViewPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'Semua';
  final List<String> _statusFilters = ['Semua', 'Tunggakan', 'Lunas'];

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
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFF073D4D)),
            tooltip: 'Pending Transaction',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PendingTransactionViewPage(
                    controller: widget.controller,
                  ),
                ),
              );
            },
          ),
        ],
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

          final List<UserModel> allMembers = widget.controller.filterMembers(
            _searchController.text,
          );

          // Filter berdasarkan status
          final List<UserModel> filteredMembers = allMembers.where((member) {
            final memberId = member.id ?? '';
            if (memberId.isEmpty) return true;

            final totalTunggakan = widget.controller.tunggakanNominalByMember(
              memberId,
            );

            if (_filterStatus == 'Tunggakan') {
              return totalTunggakan > 0;
            } else if (_filterStatus == 'Lunas') {
              return totalTunggakan == 0;
            }
            return true;
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 380
                  ? 12.0
                  : 20.0;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  24,
                ),
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, no anggota, lokasi',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF7F7F7),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0C844C)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusFilters.map((status) {
                        final isSelected = status == _filterStatus;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _filterStatus = status;
                              });
                            },
                            selectedColor: const Color(0xFF0C844C),
                            backgroundColor: const Color(0xFFF0F0F0),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF444444),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF0C844C)
                                    : const Color(0xFFE0E0E0),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredMembers.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: const Center(
                        child: Text(
                          'Data anggota tidak ditemukan',
                          style: TextStyle(
                            color: Color(0xFF6A6A6A),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    ...filteredMembers.map((member) {
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

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PjVerificationMemberCard(
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
                              builder: (_) =>
                                  PjDetailAnggotaView(member: member),
                            );
                          },
                        ),
                      );
                    }).toList(),
                ],
              );
            },
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
