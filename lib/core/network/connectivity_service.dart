import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:persis_app/core/network/network_status.dart';
import 'package:persis_app/features/BendaharaPJ/presentation/controller/pj_hive_controller.dart';

/// Service yang mendeteksi perubahan konektivitas internet secara real-time
/// dan langsung memicu sinkronisasi data Hive ke backend ketika internet kembali.
class ConnectivityService {
  ConnectivityService._();

  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _wasOffline = false;

  /// Mulai mendengarkan perubahan konektivitas.
  /// Panggil sekali di [main()].
  static Future<void> init() async {
    // Cek status konektivitas awal
    final initialResults = await Connectivity().checkConnectivity();
    _wasOffline = _isOffline(initialResults);

    _subscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  static void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isCurrentlyOffline = _isOffline(results);

    if (_wasOffline && !isCurrentlyOffline) {
      // Internet baru kembali — verifikasi benar-benar bisa menjangkau internet
      final hasInternet = await NetworkStatus.hasInternetConnection();
      if (hasInternet) {
        // Trigger sync segera tanpa menunggu timer auto-sync
        PjHiveController().syncPendingTransactions();
      }

    }

    _wasOffline = isCurrentlyOffline;
  }

  static bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }

  /// Hentikan listener (opsional, misalnya saat app ditutup).
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
