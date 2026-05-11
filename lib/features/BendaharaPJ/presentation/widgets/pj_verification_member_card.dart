import 'package:flutter/material.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_controller.dart';

class PjVerificationMemberCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isTunggakan;
  final bool showTotal;
  final String total;
  final List<MemberIuranStatusModel> iuranStatuses;
  final PjMonthStatus? cardStatus;
  final VoidCallback? onTapCekKartu;
  final VoidCallback? onTapDetail;
  final bool showIuranList;

  const PjVerificationMemberCard({
    super.key,
    required this.name,
    this.subtitle = '',
    this.isTunggakan = false,
    this.showTotal = false,
    this.total = 'Rp. 40.000',
    this.iuranStatuses = const <MemberIuranStatusModel>[],
    this.cardStatus,
    this.onTapCekKartu,
    this.onTapDetail,
    this.showIuranList = false,
  });

  PjMonthStatus _aggregateStatus() {
    if (cardStatus != null) {
      return cardStatus!;
    }

    if (iuranStatuses.any((status) => status.status == PjMonthStatus.paid)) {
      return PjMonthStatus.paid;
    }

    if (iuranStatuses.any(
          (status) => status.status == PjMonthStatus.tunggakan,
        ) ||
        isTunggakan) {
      return PjMonthStatus.tunggakan;
    }

    return PjMonthStatus.pending;
  }

  String _statusLabel(PjMonthStatus status) {
    switch (status) {
      case PjMonthStatus.paid:
        return 'Lunas';
      case PjMonthStatus.tunggakan:
        return 'Tunggakan';
      case PjMonthStatus.pending:
        return 'Belum Bayar';
    }
  }

  Color _statusColor(PjMonthStatus status) {
    switch (status) {
      case PjMonthStatus.paid:
        return const Color(0xFF28A745);
      case PjMonthStatus.tunggakan:
        return const Color(0xFFB31012);
      case PjMonthStatus.pending:
        return const Color(0xFF6B7280);
    }
  }

  IconData _statusIcon(PjMonthStatus status) {
    switch (status) {
      case PjMonthStatus.paid:
        return Icons.check_circle_rounded;
      case PjMonthStatus.tunggakan:
        return Icons.warning_amber_rounded;
      case PjMonthStatus.pending:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aggregateStatus = _aggregateStatus();
    final aggregateColor = _statusColor(aggregateStatus);
    final aggregateIcon = _statusIcon(aggregateStatus);
    final aggregateLabel = _statusLabel(aggregateStatus);
    final cardBackground = aggregateStatus == PjMonthStatus.paid
        ? const Color(0xFFF2FBF4)
        : aggregateStatus == PjMonthStatus.tunggakan
        ? const Color(0xFFFFF6F6)
        : Colors.white;
    final cardBorder = aggregateStatus == PjMonthStatus.paid
        ? const Color(0xFFBFE7C7)
        : aggregateStatus == PjMonthStatus.tunggakan
        ? const Color(0xFFF2C8C8)
        : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 59,
                height: 67,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  'https://placehold.co/59x67',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF3F4F6),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF9CA3AF),
                        size: 28,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF073D4D),
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (aggregateStatus != PjMonthStatus.pending) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: aggregateColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: aggregateColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  aggregateIcon,
                                  size: 14,
                                  color: aggregateColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  aggregateLabel,
                                  style: TextStyle(
                                    color: aggregateColor,
                                    fontSize: 10,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onTapCekKartu,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0x4989CCD1),
                              foregroundColor: const Color(0xFF02457B),
                              side: const BorderSide(color: Color(0xFF5DB1BA)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'Cek Kartu Iuran',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onTapDetail,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFFBEA),
                              foregroundColor: const Color(0xFF073D4D),
                              side: const BorderSide(color: Color(0xFFFFD700)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'Detail',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (showIuranList && iuranStatuses.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: iuranStatuses.map((status) {
                          final chipColor = _statusColor(status.status);
                          final chipLabel = _statusLabel(status.status);
                          final chipBackground =
                              status.status == PjMonthStatus.paid
                              ? const Color(0xFFE8F7EB)
                              : status.status == PjMonthStatus.tunggakan
                              ? const Color(0xFFFFEBEB)
                              : const Color(0xFFF3F4F6);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: chipBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: chipColor.withOpacity(0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _statusIcon(status.status),
                                  size: 12,
                                  color: chipColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${status.label} - $chipLabel',
                                  style: TextStyle(
                                    color: chipColor,
                                    fontSize: 10,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (showTotal) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Total :',
                  style: TextStyle(
                    color: Color(0xFF073D4D),
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  total,
                  style: const TextStyle(
                    color: Color(0xFF073D4D),
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
