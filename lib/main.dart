import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/network/connectivity_service.dart';
import 'core/storage/hive_service.dart';
import 'features/BendaharaPJ/presentation/controller/pj_controller.dart';
import 'features/BendaharaPJ/presentation/controller/pj_transaction_item_controller.dart';
import 'features/BendaharaPJ/presentation/controller/pj_hive_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  await HiveService.init();
  await PjHiveController.init();
  await PjController.initCache();
  await PjTransactionItemController.initCache();
  final hiveController = PjHiveController();
  await hiveController.syncPendingTransactions();
  await Hive.openBox('riwayat_anggota');
  await ConnectivityService.init();
  hiveController.startAutoSync();

  runApp(const MyApp());
}
