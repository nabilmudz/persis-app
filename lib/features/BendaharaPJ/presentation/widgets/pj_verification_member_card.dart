import 'package:flutter/material.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_controller.dart';

class PjVerificationMemberCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isTunggakan;
  final List<MemberIuranStatusModel> iuranStatuses;
  final PjMonthStatus? cardStatus;
  final VoidCallback? onTapCekKartu;
  final VoidCallback? onTapDetail;
  final VoidCallback? onTapInvoice;
  final bool showIuranList;

  const PjVerificationMemberCard({
    super.key,
    required this.name,
    this.subtitle = '',
    this.isTunggakan = false,
    this.iuranStatuses = const <MemberIuranStatusModel>[],
    this.cardStatus,
    this.onTapCekKartu,
    this.onTapDetail,
    this.onTapInvoice,
    this.showIuranList = false,
  });

  void _showActionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF073D4D),
                  fontFamily: 'Poppins',
                ),
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'NPA: $subtitle',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 10),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFFBEA),
                  child: Icon(Icons.info_outline, color: Color(0xFFDE8D00)),
                ),
                title: const Text(
                  'Lihat Detail Anggota',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (onTapDetail != null) {
                    onTapDetail!();
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE9EDFF),
                  child: Icon(
                    Icons.credit_card_outlined,
                    color: Color(0xFF2116A3),
                  ),
                ),
                title: const Text(
                  'Lihat Kartu Bayar Anggota',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (onTapCekKartu != null) {
                    onTapCekKartu!();
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFFAF4),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF0C844C),
                  ),
                ),
                title: const Text(
                  'Lihat Invoice Terakhir',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (onTapInvoice != null) {
                    onTapInvoice!();
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(Icons.close, color: Color(0xFFEF4444)),
                ),
                title: const Text(
                  'Batal',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFFEF4444),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const cardBackground = Colors.white;
    const cardBorder = Color(0xFFE8E8E8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF073D4D),
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.trim().isNotEmpty ? 'NPA: $subtitle' : '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF073D4D)),
            onPressed: () => _showActionBottomSheet(context),
          ),
        ],
      ),
    );
  }
}
