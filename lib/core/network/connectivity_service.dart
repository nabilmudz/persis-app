import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:persis_app/core/network/network_status.dart';
import 'package:persis_app/features/bendahara_pj/presentation/controller/pj_hive_controller.dart';

class ConnectivityService {
  ConnectivityService._();

  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _wasOffline = false;

  static Future<void> init() async {
    final initialResults = await Connectivity().checkConnectivity();
    _wasOffline = _isOffline(initialResults);

    _subscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  static void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isCurrentlyOffline = _isOffline(results);

    if (_wasOffline && !isCurrentlyOffline) {
      final hasInternet = await NetworkStatus.hasInternetConnection();
      if (hasInternet) {
        PjHiveController().syncPendingTransactions();
      }
    }

    _wasOffline = isCurrentlyOffline;
  }

  static bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
