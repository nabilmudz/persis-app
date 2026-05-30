import 'package:flutter/material.dart';

import '../features/bendahara_pj/presentation/controller/pj_hive_controller.dart';
import 'routes.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late PjHiveController _pjHiveController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pjHiveController = PjHiveController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pjHiveController.syncPendingTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iuran Pemuda Persis',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
    );
  }
}
