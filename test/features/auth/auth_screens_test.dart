import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persis_app/features/auth/otp_screen.dart';
import 'package:persis_app/features/auth/forgot_password_screen.dart';

void main() {
  // Widget pembungkus untuk ngetest layar
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  // Helper function untuk me-resize layar tester menjadi ukuran HP modern
  void setupScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400); 
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('OtpScreen Widget Tests', () {
    // ==========================================
    // TC01: OtpScreen UI - Positif
    // ==========================================
    testWidgets('TC01: Mampu merender judul, email, dan numpad dengan benar', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createWidgetUnderTest(
        const OtpScreen(npa: '12345', email: 'test@email.com'),
      ));

      // Verifikasi Teks Muncul
      expect(find.text('Aktivasi Akun'), findsWidgets);
      
      expect(find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText().contains('test@email.com')
      ), findsOneWidget); 
      
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);

      // FAST-FORWARD WAKTU: Percepat 31 detik agar Timer OTP selesai sebelum test ditutup
      await tester.pump(const Duration(seconds: 31));
    });

    // ==========================================
    // TC02: OtpScreen UI - Positif
    // ==========================================
    testWidgets('TC02: Tombol Verifikasi OTP ter-disable saat OTP belum 4 digit', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createWidgetUnderTest(
        const OtpScreen(npa: '12345', email: 'test@email.com'),
      ));

      final verifyButtonFinder = find.byType(ElevatedButton);
      final ElevatedButton verifyButton = tester.widget(verifyButtonFinder);

      expect(verifyButton.onPressed, isNull, reason: 'Tombol harus disable jika OTP belum 4 digit');

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      await tester.pump(); 

      final ElevatedButton activeVerifyButton = tester.widget(verifyButtonFinder);
      expect(activeVerifyButton.onPressed, isNotNull, reason: 'Tombol harus enable jika OTP sudah 4 digit');

      // FAST-FORWARD WAKTU
      await tester.pump(const Duration(seconds: 31));
    });

    // ==========================================
    // TC03: OtpScreen UI - Positif
    // ==========================================
    testWidgets('TC03: Numpad backspace dapat menghapus input', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createWidgetUnderTest(
        const OtpScreen(npa: '12345', email: 'test@email.com'),
      ));

      await tester.tap(find.text('9'));
      await tester.pump();
      expect(find.text('9'), findsWidgets); 

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      expect(find.text('9'), findsOneWidget);

      // FAST-FORWARD WAKTU
      await tester.pump(const Duration(seconds: 31));
    });
  });

  group('ForgotPasswordScreen Widget Tests', () {
    // ==========================================
    // TC04: ForgotPasswordScreen UI - Positif
    // ==========================================
    testWidgets('TC04: Mampu merender input form dan tombol Kirim OTP', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createWidgetUnderTest(const ForgotPasswordScreen()));

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Email atau NPA'), findsWidgets); 
      expect(find.text('Kirim OTP'), findsOneWidget); 
    });

    // ==========================================
    // TC05: ForgotPasswordScreen UI - Negatif
    // ==========================================
    testWidgets('TC05: Validasi kosong memunculkan error snackbar', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createWidgetUnderTest(const ForgotPasswordScreen()));

      await tester.tap(find.text('Kirim OTP'));
      await tester.pump(); 

      expect(find.text('Email atau NPA tidak boleh kosong'), findsOneWidget);
    });
  });
}