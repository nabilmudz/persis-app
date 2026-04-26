import 'package:flutter/material.dart';

class PjVerificationMemberCard extends StatelessWidget {
  final String name;
  final bool isTunggakan;
  final bool showTotal;
  final String total;
  final VoidCallback? onTapCekKartu;

  const PjVerificationMemberCard({
    super.key,
    required this.name,
    this.isTunggakan = false,
    this.showTotal = false,
    this.total = 'Rp. 40.000',
    this.onTapCekKartu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
                  image: const DecorationImage(
                    image: NetworkImage('https://placehold.co/59x67'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF073D4D),
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isTunggakan) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x2DB31012),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFB31012),
                              ),
                            ),
                            child: const Text(
                              'Tunggakan',
                              style: TextStyle(
                                color: Color(0xFFA50A0C),
                                fontSize: 10,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
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
