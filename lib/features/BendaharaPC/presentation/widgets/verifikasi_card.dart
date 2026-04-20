import 'package:flutter/material.dart';

class VerifikasiCard extends StatelessWidget {
  final String date;
  final String location;
  final String name;
  final String idNumber;
  final String paymentMethod;
  final String price;
  final VoidCallback onAccPressed;
  final VoidCallback onLihatBuktiPressed;

  const VerifikasiCard({
    super.key,
    required this.date,
    required this.location,
    required this.name,
    required this.idNumber,
    required this.paymentMethod,
    required this.price,
    required this.onAccPressed,
    required this.onLihatBuktiPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 325,
      height: 171,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 250,
            top: 35,
            child: Text(
              date,
              style: const TextStyle(
                color: Color(0xFF6A6A6A),
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Positioned(
            left: 19,
            top: 35,
            child: Text(
              location,
              style: const TextStyle(
                color: Color(0xFF6A6A6A),
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Positioned(
            left: 19,
            top: 15,
            child: SizedBox(
              width: 224,
              height: 21,
              child: Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF074D2C),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            left: 66,
            top: 77,
            child: Text(
              paymentMethod,
              style: const TextStyle(
                color: Color(0xFF6A6A6A),
                fontSize: 13,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            left: 235,
            top: 15,
            child: Text(
              price,
              style: const TextStyle(
                color: Color(0xFF0C844C),
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            left: 19,
            top: 55.50,
            child: Container(
              width: 288,
              decoration: const ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignCenter,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 105,
            top: 35,
            child: Text(
              idNumber,
              style: const TextStyle(
                color: Color(0xFF6A6A6A),
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Positioned(
            left: 19,
            top: 71,
            child: Container(
              width: 38,
              height: 36,
              decoration: ShapeDecoration(
                color: const Color(0xFFD9D9D9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
          ),
          // Tombol Lihat Bukti
          Positioned(
            left: 238,
            top: 75,
            child: GestureDetector(
              onTap: onLihatBuktiPressed,
              child: Container(
                width: 64,
                height: 24,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: const Color(0xFF074D2C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                child: const Text(
                  'Lihat Bukti',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          // Tombol ACC Pembayaran
          Positioned(
            left: 139,
            top: 123,
            child: GestureDetector(
              onTap: onAccPressed,
              child: Container(
                width: 163,
                height: 35,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: const Color(0xFF0C844C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                child: const Text(
                  'ACC Pembayaran',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}