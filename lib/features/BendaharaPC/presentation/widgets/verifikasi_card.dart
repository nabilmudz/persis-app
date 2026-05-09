import 'package:flutter/material.dart';

class VerifikasiCard extends StatelessWidget {
  final String date;
  final String location;
  final String name;
  final String idNumber;
  final String paymentMethod;
  final String price;
  final String? status; 
  final VoidCallback? onAccPressed;
  final VoidCallback? onLihatBuktiPressed;

  const VerifikasiCard({
    super.key,
    required this.date,
    required this.location,
    required this.name,
    required this.idNumber,
    required this.paymentMethod,
    required this.price,
    this.status,
    this.onAccPressed,
    this.onLihatBuktiPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = status?.toLowerCase() == 'sudah diverifikasi' || 
                       status?.toLowerCase() == 'verified';
    final badgeColor = isVerified ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final textColor = isVerified ? const Color(0xFF0C844C) : const Color(0xFFE65100);
    final badgeText = isVerified ? 'Sudah Diverifikasi' : 'Belum Diverifikasi';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF074D2C),
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                price,
                style: const TextStyle(
                  color: Color(0xFF0C844C),
                  fontSize: 15,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$location • $idNumber',
                  style: const TextStyle(
                    color: Color(0xFF6A6A6A),
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  color: Color(0xFF6A6A6A),
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE0E0E0)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF6A6A6A)),
                  const SizedBox(width: 6),
                  Text(
                    paymentMethod,
                    style: const TextStyle(
                      color: Color(0xFF6A6A6A),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (onAccPressed != null) ...[
                Row(
                  children: [
                    if (onLihatBuktiPressed != null) ...[
                      GestureDetector(
                        onTap: onLihatBuktiPressed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF074D2C),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('Lihat Bukti', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'Poppins')),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    GestureDetector(
                      onTap: onAccPressed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C844C),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('Verifikasi', style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ] else if (status != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
