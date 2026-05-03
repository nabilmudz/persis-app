import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/network/connectivity_service.dart';
import 'core/storage/hive_service.dart';
import 'features/BendaharaPJ/presentation/controller/pj_hive_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  await HiveService.init();
  await PjHiveController.init(); // Inisialisasi Box untuk PjHiveController
  await PjHiveController.syncPendingTransactions(); // Sync saat startup

  // Mulai listener konektivitas — sync dipicu event-driven saat internet kembali
  await ConnectivityService.init();

  // Backup polling setiap 30 detik (fallback jika event connectivity terlewat)
  PjHiveController.startAutoSync();

  runApp(const MyApp());
}
