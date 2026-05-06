import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  // 1. Siapkan parameter untuk data yang akan berubah-ubah
  final String duration;
  final String name;
  final String idNumber;
  final String location;
  final String price;

  const CustomCard({
    super.key,
    required this.duration,
    required this.name,
    required this.idNumber,
    required this.location,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 325,
      height: 69,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 325,
              height: 69,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          Positioned(
            left: 273,
            top: 36,
            child: Text(
              duration, // Menggunakan parameter
              style: const TextStyle(
                color: Color(0xFFB31012),
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            left: 57,
            top: 14,
            child: SizedBox(
              width: 224,
              height: 21,
              child: Text(
                name, // Menggunakan parameter
                style: const TextStyle(
                  color: Color(0xFF494949),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            left: 57,
            top: 36,
            child: Text(
              idNumber, // Menggunakan parameter
              style: const TextStyle(
                color: Color(0xFF6A6A6A),
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            left: 108,
            top: 36,
            child: Text(
              location, // Menggunakan parameter
              style: const TextStyle(
                color: Color(0xFF6A6A6A),
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            left: 235,
            top: 14,
            child: Text(
              price, // Menggunakan parameter
              style: const TextStyle(
                color: Color(0xFFB31012),
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            left: 151,
            top: 23,
            child: SizedBox(
              width: 24,
              height: 24,
            ), // Ini sepertinya tempat untuk icon/gambar
          ),
        ],
      ),
    );
  }
}
