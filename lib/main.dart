import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/network/api_client.dart';
import 'app/app.dart';
import 'core/storage/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isConnected = await ApiClient.checkConnection();
  print(isConnected ? 'Backend online' : 'Backend offline');

  await Hive.initFlutter();
  await HiveService.init();

  runApp(const MyApp());
}
