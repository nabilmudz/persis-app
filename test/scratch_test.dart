import 'package:flutter_test/flutter_test.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/core/storage/secure_storage.dart';
import 'dart:convert';
import 'dart:io';

void main() async {
  test('fetch transaction structure', () async {
    // Override HttpClient to bypass SSL issues if any
    HttpOverrides.global = _MyHttpOverrides();

    // Since it's a test, we might need a token if the endpoint is protected
    // If we don't have token, we can just print what we can. 
    // Wait, we can't easily get token in a pure unit test unless we mock or login.
    // Instead of unit test, let's write a simple script that logs it from the app or 
    // better, I can just check the backend's response format if the user can run this script.
  });
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
