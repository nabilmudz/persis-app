import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persis_app/features/auth/login_screen.dart';

void main() {
  Widget jalankanLayarLogin() {
    return const MaterialApp(home: LoginScreen());
  }

  group('Skenario Tampilan Layar Login (Widget Test)', () {
    testWidgets('1. Pastikan judul dan Tab "Masuk" / "Aktivasi" muncul di layar', (WidgetTester tester) async {
      await tester.pumpWidget(jalankanLayarLogin());
      expect(find.text('InfaQu'), findsOneWidget);

      expect(find.widgetWithText(Tab, 'Masuk'), findsOneWidget); 
      expect(find.widgetWithText(Tab, 'Aktivasi Akun'), findsOneWidget);
    });

    testWidgets('4. Pastikan logo mata (password) bisa ditekan untuk melihat password', (WidgetTester tester) async {
      await tester.pumpWidget(jalankanLayarLogin());
      final kolomPassword = find.byType(TextField).last;
      
      TextField tfWidget = tester.widget(kolomPassword);
      expect(tfWidget.obscureText, true);


      final logoMataTertutup = find.byIcon(Icons.visibility_off_outlined);
      await tester.tap(logoMataTertutup);
      await tester.pump();

      tfWidget = tester.widget(find.byType(TextField).last);
      expect(tfWidget.obscureText, false);
    });
  });
}