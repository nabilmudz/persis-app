import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persis_app/features/auth/login_screen.dart';

void main() {
  // Fungsi bantuan untuk menjalankan layar Login
  Widget jalankanLayarLogin() {
    return const MaterialApp(
      home: LoginScreen(),
    );
  }

  group('Skenario Tampilan Layar Login (Widget Test)', () {
    
    testWidgets('1. Pastikan judul dan Tab "Masuk" / "Aktivasi" muncul di layar', (WidgetTester tester) async {
      await tester.pumpWidget(jalankanLayarLogin());

      // Cek tulisan judul
      expect(find.text('InfaQu'), findsOneWidget);
      expect(find.text('Sistem Manajemen Iuran Terpusat'), findsOneWidget);

      // Cek tulisan di Tab
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Aktivasi Akun'), findsOneWidget);
    });

    testWidgets('2. Pastikan muncul peringatan merah (Snackbar) kalau tombol Masuk ditekan saat kosong', (WidgetTester tester) async {
      await tester.pumpWidget(jalankanLayarLogin());

      // Cari tombol "Masuk" di layar
      final tombolMasuk = find.widgetWithText(ElevatedButton, 'Masuk');
      expect(tombolMasuk, findsOneWidget);

      // Kita simulasikan jari user menekan tombol tersebut
      await tester.tap(tombolMasuk);
      await tester.pump(); // Tunggu animasi layar merespons

      // Harus muncul peringatan ini di bawah layar
      expect(find.text('Email dan Password tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('3. Pastikan user bisa geser ke Tab Aktivasi Akun', (WidgetTester tester) async {
      await tester.pumpWidget(jalankanLayarLogin());

      // Cari Tab "Aktivasi Akun" dan tekan
      final tabAktivasi = find.text('Aktivasi Akun');
      await tester.tap(tabAktivasi);
      
      // Tunggu animasi gesernya selesai
      await tester.pumpAndSettle(); 

      // Pastikan sekarang di layar ada kolom input NPA dan tombol Daftar
      expect(find.text('Masukkan NPA'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Daftar'), findsOneWidget);
    });

    testWidgets('4. Pastikan logo mata (password) bisa ditekan untuk melihat password', (WidgetTester tester) async {
      await tester.pumpWidget(jalankanLayarLogin());

      // Cari kolom teks password
      final kolomPassword = find.byType(TextField).last;
      
      // Cek apakah mode sensor (titik-titik) sedang aktif (obscureText = true)
      TextField tfWidget = tester.widget(kolomPassword);
      expect(tfWidget.obscureText, true);

      // Cari logo mata (visibility) dan tekan
      final logoMata = find.byIcon(Icons.visibility_outlined);
      await tester.tap(logoMata);
      await tester.pump();

      // Cek apakah sekarang sensornya mati (obscureText = false)
      tfWidget = tester.widget(find.byType(TextField).last);
      expect(tfWidget.obscureText, false);
    });

  });
}