import 'package:flutter/material.dart';

class BulanIuranBottomSheet extends StatefulWidget {
  const BulanIuranBottomSheet({super.key});

  @override
  State<BulanIuranBottomSheet> createState() => _BulanIuranBottomSheetState();
}

class _BulanIuranBottomSheetState extends State<BulanIuranBottomSheet> {
  int selectedYear = 2026;
  String selectedMonth = 'Januari';

  final List<String> months = [
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.calendar_month, color: Color(0xFF10B367)),
                  SizedBox(width: 8),
                  Text(
                    'Bulan Mulai Iuran',
                    style: TextStyle(
                      color: Color(0xFF074D2C),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF074D2C)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD0D0D0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => setState(() => selectedYear--),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF6C6C6C),
                  ),
                ),
                Text(
                  selectedYear.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFF363636),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => selectedYear++),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF6C6C6C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: months.length,
            itemBuilder: (context, index) {
              final month = months[index];
              final isSelected = selectedMonth == month;
              return GestureDetector(
                onTap: () {
                  setState(() => selectedMonth = month);
                  // Otomatis tutup bottom sheet & kirim data bulan + tahun
                  Navigator.pop(context, '$month $selectedYear');
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF10B367) : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF10B367)
                          : const Color(0xFFD0D0D0),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    month,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6C6C6C),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
