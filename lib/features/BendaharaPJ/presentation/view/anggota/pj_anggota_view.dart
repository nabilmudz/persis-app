import 'package:flutter/material.dart';
import 'package:persis_app/app/routes.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_controller.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_hive_controller.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_invoice_controller.dart';
import 'package:persis_app/core/widgets/role_bottom_navigation_bar.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/widgets/pj_verification_member_card.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/anggota/pj_verif_tunai_view.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/tunai/pending_transaction_view.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/pj_invoice.view.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/view/anggota/pj_detail_anggota_view.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/core/network/api_client.dart';

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
  int _currentPage = 1;
  final int _itemsPerPage = 20;

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
                  builder: (_) =>
                      PendingTransactionViewPage(controller: widget.controller),
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

          final List<UserModel> filteredMembers = widget.controller
              .filterMembers(_searchController.text);

          final int totalPages = (filteredMembers.length / _itemsPerPage)
              .ceil();
          final List<UserModel> paginatedMembers = filteredMembers
              .skip((_currentPage - 1) * _itemsPerPage)
              .take(_itemsPerPage)
              .toList();

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
                    onChanged: (_) => setState(() {
                      _currentPage = 1;
                    }),
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
                              if (_filterStatus != status) {
                                setState(() {
                                  _filterStatus = status;
                                  _currentPage = 1;
                                });
                                widget.controller.fetchMembersByStatus(status);
                              }
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
                  if (paginatedMembers.isEmpty)
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
                    Builder(
                      builder: (context) {
                        return Column(
                          children: paginatedMembers.map((member) {
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
                            final PjMonthStatus? cardStatus =
                                member.status != null
                                ? (member.status!.toLowerCase() == 'lunas'
                                      ? PjMonthStatus.paid
                                      : (member.status!.toLowerCase() ==
                                                'tunggakan'
                                            ? PjMonthStatus.tunggakan
                                            : PjMonthStatus.pending))
                                : (memberId.isEmpty
                                      ? null
                                      : widget.controller.memberCardStatus(
                                          memberId,
                                        ));

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: PjVerificationMemberCard(
                                name: widget.controller.memberDisplayName(
                                  member,
                                ),
                                subtitle: widget.controller.memberDisplayCode(
                                  member,
                                ),
                                isTunggakan: totalTunggakan > 0,
                                iuranStatuses: iuranStatuses,
                                cardStatus: cardStatus,
                                onTapCekKartu: () {
                                  if (memberId.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'ID anggota tidak tersedia.',
                                        ),
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
                                onTapInvoice:
                                    _getLastInvoiceForMember(member) != null
                                    ? () async {
                                        var invoiceData =
                                            _getLastInvoiceForMember(member);
                                        if (invoiceData == null) return;

                                        // Fetch complete member if phone is missing
                                        if ((invoiceData.member.noHp == null ||
                                                invoiceData
                                                    .member
                                                    .noHp!
                                                    .isEmpty) &&
                                            invoiceData.member.id != null) {
                                          try {
                                            final userRemote =
                                                UserRemoteDataSource(
                                                  ApiClient.baseUrl,
                                                );
                                            final fetchedUser = await userRemote
                                                .getOneUsers(
                                                  invoiceData.member.id!,
                                                );
                                            if (fetchedUser.noHp != null &&
                                                fetchedUser.noHp!.isNotEmpty) {
                                              invoiceData = invoiceData
                                                  .copyWith(
                                                    member: fetchedUser,
                                                  );
                                            }
                                          } catch (_) {}
                                        }

                                        if (!mounted) return;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PjInvoiceViewPage(
                                              invoiceData: invoiceData!,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ), // Builder
                  if (totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _currentPage > 1
                                ? () {
                                    setState(() {
                                      _currentPage--;
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            'Halaman $_currentPage dari $totalPages',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _currentPage < totalPages
                                ? () {
                                    setState(() {
                                      _currentPage++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                ], // children: ListView
              ); // ListView
            }, // LayoutBuilder builder
          ); // LayoutBuilder
        }, // ListenableBuilder builder
      ), // ListenableBuilder (body)
      bottomNavigationBar: const RoleBottomNavigationBar(
        currentRoute: AppRoutes.bendaharaPJ,
        homeRoute: AppRoutes.bendaharaPJ,
      ),
    ); // Scaffold
  }

  /// Ambil invoice terakhir milik anggota dari Hive (pending) atau Controller (history).
  PjInvoiceData? _getLastInvoiceForMember(UserModel member) {
    final memberId = member.id?.toString() ?? '';
    if (memberId.isEmpty) return null;

    PjInvoiceData? hiveInvoice;
    PjInvoiceData? historyInvoice;

    // 1. Cek dari Hive (Pending/Local)
    try {
      final hiveController = PjHiveController();
      final allPending = hiveController.getPendingTransactions();

      final memberPending = allPending.where((entry) {
        final data = entry['data'] as Map<String, dynamic>;

        // Cocokkan creatorId
        final creatorId =
            (data['creatorId'] ?? data['creator_id'])?.toString() ?? '';
        if (creatorId == memberId) return true;

        // Cocokkan items anggotaId
        final items = data['items'];
        if (items is List) {
          return items.any((item) {
            if (item is Map) {
              final id =
                  (item['anggotaId'] ?? item['anggota_id'])?.toString() ?? '';
              return id == memberId;
            }
            return false;
          });
        }
        return false;
      }).toList();

      if (memberPending.isNotEmpty) {
        // Sort by local_timestamp or createdAt
        memberPending.sort((a, b) {
          final aTs =
              (a['data'] as Map)['local_timestamp'] ??
              (a['data'] as Map)['createdAt'] ??
              '';
          final bTs =
              (b['data'] as Map)['local_timestamp'] ??
              (b['data'] as Map)['createdAt'] ??
              '';
          return bTs.toString().compareTo(aTs.toString());
        });

        final lastHiveData =
            memberPending.first['data'] as Map<String, dynamic>;
        hiveInvoice = _buildInvoiceFromHiveMap(member, lastHiveData);
      }
    } catch (e) {
      debugPrint('Error check Hive invoice: $e');
    }

    // 2. Cek dari Controller (History/Synced)
    try {
      final lastHistoryTx = widget.controller.lastTransactionForMember(
        memberId,
      );
      if (lastHistoryTx != null) {
        historyInvoice = PjInvoiceData.fromTransaction(
          member: member,
          transaction: lastHistoryTx,
        );
      }
    } catch (e) {
      debugPrint('Error check History invoice: $e');
    }

    // 3. Bandingkan mana yang lebih baru
    if (hiveInvoice != null && historyInvoice != null) {
      return hiveInvoice.generatedAt.isAfter(historyInvoice.generatedAt)
          ? hiveInvoice
          : historyInvoice;
    }

    return hiveInvoice ?? historyInvoice;
  }

  PjInvoiceData _buildInvoiceFromHiveMap(
    UserModel member,
    Map<String, dynamic> data,
  ) {
    // Helper logic same as above
    final transaction = _buildTransactionFromHive(data);
    final rawItems = data['items'] as List? ?? [];
    final invoiceItems = <PjInvoiceLineItem>[];
    final months = <int>[];
    int year = DateTime.now().year;

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

    for (final rawItem in rawItems) {
      if (rawItem is! Map) continue;
      final desc = rawItem['description']?.toString() ?? '';
      int month = 0;
      for (var i = 0; i < monthNames.length; i++) {
        if (desc.contains(monthNames[i])) {
          month = i + 1;
          final yearMatch = RegExp(r'(20\d{2})').firstMatch(desc);
          if (yearMatch != null)
            year = int.tryParse(yearMatch.group(0)!) ?? year;
          break;
        }
      }
      if (month > 0) months.add(month);
      invoiceItems.add(
        PjInvoiceLineItem(
          month: month,
          year: year,
          label: desc,
          amount: (rawItem['amount'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return PjInvoiceData(
      member: member,
      transaction: transaction,
      items: invoiceItems,
      months: months,
      year: year,
      totalAmount:
          (data['totalAmount'] ?? data['total_amount'] as num?)?.toInt() ?? 0,
      syncedToBackend: data['isSynced'] == true,
      generatedAt:
          DateTime.tryParse(
            data['createdAt']?.toString() ??
                data['created_at']?.toString() ??
                data['local_timestamp']?.toString() ??
                '',
          ) ??
          DateTime(1900),
    );
  }

  static TransactionModel _buildTransactionFromHive(Map<String, dynamic> data) {
    try {
      return TransactionModel.fromJson(data);
    } catch (_) {
      return TransactionModel(
        id: data['id']?.toString() ?? data['_id']?.toString() ?? '',
        type: data['type']?.toString() ?? 'tunai',
        status: data['status']?.toString() ?? 'pending',
        totalAmount:
            (data['totalAmount'] ?? data['total_amount'] as num?)?.toInt() ?? 0,
        createdAt:
            data['createdAt']?.toString() ??
            data['local_timestamp']?.toString(),
      );
    }
  }
}
