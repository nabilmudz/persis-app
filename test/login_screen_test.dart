import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persis_app/features/auth/login_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: LoginScreen(),
    );
  }

  group('LoginScreen UI Tests', () {
    testWidgets('Mampu merender judul InfaQu dan TabBar dengan benar', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verifikasi Teks Muncul
      expect(find.text('InfaQu'), findsOneWidget);
      expect(find.text('Sistem Manajemen Iuran Terpusat'), findsOneWidget);

      // Verifikasi TabBar Muncul
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Aktivasi Akun'), findsOneWidget);
    });

    testWidgets('Menampilkan snackbar error jika tombol Masuk ditekan dengan input kosong', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Pastikan ada di tab Masuk
      final loginButton = find.widgetWithText(ElevatedButton, 'Masuk');
      expect(loginButton, findsOneWidget);

      // Tekan tombol Masuk
      await tester.tap(loginButton);
      await tester.pump(); // trigger frame

      // Harus muncul snackbar
      expect(find.text('Email dan Password tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('Dapat berpindah ke Tab Aktivasi Akun dan menampilkan input NPA', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Cari tab "Aktivasi Akun" dan tap
      final aktivasiTab = find.text('Aktivasi Akun');
      await tester.tap(aktivasiTab);
      await tester.pumpAndSettle(); // Tunggu animasi transisi tab selesai

      // Verifikasi TextField NPA dan tombol Daftar muncul
      expect(find.text('Masukkan NPA'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Daftar'), findsOneWidget);
    });

    testWidgets('Bisa melakukan toggle visibility pada form Password', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Cari textfield password dengan hint 'Masukkan password'
      final passwordField = find.byType(TextField).last; 
      
      // Defaultnya harus obscureText = true
      TextField tfWidget = tester.widget(passwordField);
      expect(tfWidget.obscureText, true);

      // Tekan icon mata untuk toggle
      final visibilityIcon = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityIcon);
      await tester.pump();

      // Cek apakah sekarang obscureText = false
      tfWidget = tester.widget(find.byType(TextField).last);
      expect(tfWidget.obscureText, false);
    });
  });
}