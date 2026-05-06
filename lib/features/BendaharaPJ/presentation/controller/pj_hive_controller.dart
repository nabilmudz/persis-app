import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persis_app/core/config/config.dart';
import 'package:persis_app/core/network/network_status.dart';
import 'package:persis_app/features/BendaharaPC/data/datasources/payment_method_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/datasources/transaction_remote_datasources.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';

class PjHiveController extends ChangeNotifier {
  static const String _boxName = 'pj_pending_transactions';
  static Timer? _autoSyncTimer;
  static bool _isSyncing = false;

  /// Inisialisasi Hive dan buka box untuk menyimpan transaksi.
  /// Panggil ini di fungsi main() atau saat inisialisasi aplikasi.
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  /// Mendapatkan instance dari box.
  Box get _box => Hive.box(_boxName);

  /// 1. Simpan transaksi tunai secara lokal sebelum dikirim ke BE/MongoDB.
  Future<int> saveTransactionLocally(
    Map<String, dynamic> transactionData, {
    TransactionRemoteDataSource? dataSource,
  }) async {
    transactionData['local_timestamp'] = DateTime.now().toIso8601String();
    transactionData['status'] = 'pending';
    transactionData['isSynced'] = false;

    final int key = await _box.add(transactionData);
    notifyListeners();

    unawaited(
      NetworkStatus.hasInternetConnection().then((isOnline) {
        if (isOnline) {
          syncPendingTransactions(dataSource: dataSource).then((syncedCount) {
            if (syncedCount > 0) {
              debugPrint(
                '[PjHiveController] Auto-sync setelah save: $syncedCount transaksi terkirim.',
              );
              notifyListeners();
            }
          });
        }
      }),
    );

    return key;
  }

  /// Coba kirim semua transaksi yang masih tersimpan lokal.
  static Future<int> syncPendingTransactions({
    TransactionRemoteDataSource? dataSource,
  }) async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }

    if (!await NetworkStatus.hasInternetConnection()) {
      return 0;
    }

    if (_isSyncing) {
      return 0;
    }

    _isSyncing = true;
    var syncedCount = 0;

    try {
      final box = Hive.box(_boxName);
      final remoteDataSource = dataSource ?? TransactionRemoteDataSource();
      final paymentMethodDataSource = PaymentMethodRemoteDataSource(
        AppConfig.baseUrl,
      );
      final entries = box.toMap().entries.toList();

      for (final entry in entries) {
        final rawValue = entry.value;
        if (rawValue is! Map) {
          continue;
        }

        try {
          final transaction = await _normalizePendingTransaction(
            Map<String, dynamic>.from(rawValue),
            remoteDataSource: remoteDataSource,
            paymentMethodDataSource: paymentMethodDataSource,
          );
          if (transaction == null) {
            continue;
          }

          final payload = transaction.copyWith(
            status: 'completed',
            isSynced: true,
          );
          final success = await remoteDataSource.createTransaction(payload);
          if (success) {
            await box.delete(entry.key);
            syncedCount++;
          }
        } catch (e) {
          // Tetap di Hive jika jaringan belum kembali atau payload gagal dikirim.
          debugPrint(
            '[PjHiveController] Gagal sync entry key=${entry.key}: $e',
          );
        }
      }
    } finally {
      _isSyncing = false;
    }

    return syncedCount;
  }

  static const Map<String, int> _monthLookup = {
    'januari': 1,
    'februari': 2,
    'maret': 3,
    'april': 4,
    'mei': 5,
    'juni': 6,
    'juli': 7,
    'agustus': 8,
    'september': 9,
    'oktober': 10,
    'november': 11,
    'desember': 12,
  };

  static Future<TransactionModel?> _normalizePendingTransaction(
    Map<String, dynamic> rawValue, {
    required TransactionRemoteDataSource remoteDataSource,
    required PaymentMethodRemoteDataSource paymentMethodDataSource,
  }) async {
    TransactionModel transaction;

    try {
      transaction = TransactionModel.fromJson(rawValue);
    } catch (e) {
      debugPrint('[PjHiveController] ❌ fromJson gagal: $e');
      debugPrint('[PjHiveController] rawValue: $rawValue');
      return null;
    }

    debugPrint(
      '[PjHiveController] ✅ Memproses sync untuk transaksi: ${transaction.id}',
    );

    final resolvedPaymentMethodId = await _resolvePaymentMethodId(
      transaction.paymentMethodId,
      paymentMethodDataSource,
    );
    if (resolvedPaymentMethodId == null || resolvedPaymentMethodId.isEmpty) {
      debugPrint(
        '[PjHiveController] ❌ paymentMethodId tidak resolve: "${transaction.paymentMethodId}"',
      );
      return null;
    }

    final normalizedItems = <TransactionItemModel>[];
    for (final item in transaction.items ?? const <TransactionItemModel>[]) {
      final resolvedItem = await _resolvePendingTransactionItem(
        item,
        remoteDataSource,
      );
      if (resolvedItem == null) {
        debugPrint(
          '[PjHiveController] ❌ item gagal resolve (period tidak ditemukan): periodId="${item.periodId}" duesPeriodId="${item.duesPeriodId}" desc="${item.description}"',
        );
        return null;
      }
      normalizedItems.add(resolvedItem);
    }

    return transaction.copyWith(
      paymentMethodId: resolvedPaymentMethodId,
      items: normalizedItems,
    );
  }

  static Future<String?> _resolvePaymentMethodId(
    String? currentPaymentMethodId,
    PaymentMethodRemoteDataSource paymentMethodDataSource,
  ) async {
    final normalized = currentPaymentMethodId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    if (normalized.toLowerCase() != 'tunai' &&
        normalized.toLowerCase() != 'cash') {
      return normalized;
    }

    final methods = await paymentMethodDataSource.getAllPaymentMethods();
    for (final method in methods) {
      final code = method.code?.toLowerCase().trim() ?? '';
      final label = method.label?.toLowerCase().trim() ?? '';
      if (code == 'tunai' ||
          label == 'tunai' ||
          code == 'cash' ||
          label == 'cash' ||
          code.contains('tunai') ||
          label.contains('tunai') ||
          code.contains('cash') ||
          label.contains('cash')) {
        return method.id;
      }
    }

    return null;
  }

  static Future<TransactionItemModel?> _resolvePendingTransactionItem(
    TransactionItemModel item,
    TransactionRemoteDataSource remoteDataSource,
  ) async {
    final currentPeriodId = (item.periodId ?? item.duesPeriodId ?? '').trim();
    if (_looksLikeBackendId(currentPeriodId)) {
      return item.copyWith(
        periodId: currentPeriodId,
        duesPeriodId: currentPeriodId,
      );
    }

    final parsedMonthYear = _parseMonthYearFromItem(item);
    if (parsedMonthYear == null) {
      return null;
    }

    final duesPeriod = await remoteDataSource.getDuesPeriodByMonthYear(
      month: parsedMonthYear.$1,
      year: parsedMonthYear.$2,
    );
    if (duesPeriod?.id == null || duesPeriod!.id!.isEmpty) {
      return null;
    }

    return item.copyWith(
      periodId: duesPeriod.id,
      duesPeriodId: duesPeriod.id,
      status: 'completed',
    );
  }

  static bool _looksLikeBackendId(String value) {
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value);
  }

  static (int, int)? _parseMonthYearFromItem(TransactionItemModel item) {
    final sources = <String?>[
      item.periodId,
      item.duesPeriodId,
      item.description,
    ];
    for (final source in sources) {
      final parsed = _parseMonthYear(source);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  static (int, int)? _parseMonthYear(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final periodMatch = RegExp(r'(\d{4})[-_/](\d{1,2})').firstMatch(raw);
    if (periodMatch != null) {
      final year = int.tryParse(periodMatch.group(1)!);
      final month = int.tryParse(periodMatch.group(2)!);
      if (year != null && month != null && month >= 1 && month <= 12) {
        return (month, year);
      }
    }

    final yearMatch = RegExp(r'(19|20)\d{2}').firstMatch(raw);
    final year = yearMatch != null ? int.tryParse(yearMatch.group(0)!) : null;
    if (year == null) {
      return null;
    }

    final lower = raw.toLowerCase();
    for (final entry in _monthLookup.entries) {
      if (lower.contains(entry.key)) {
        return (entry.value, year);
      }
    }

    return null;
  }

  /// Jalankan retry sinkronisasi berkala selama aplikasi aktif.
  /// Interval default 30 detik sebagai fallback backup — sinkronisasi utama
  /// sudah dipicu event-driven oleh [ConnectivityService] saat internet kembali.
  static void startAutoSync({
    Duration interval = const Duration(seconds: 30),
    TransactionRemoteDataSource? dataSource,
  }) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) {
      syncPendingTransactions(dataSource: dataSource);
    });
  }

  static void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// 2. Ambil semua transaksi yang masih pending (belum dikirim ke BE).
  /// Mengembalikan list of map yang berisi kombinasi 'key' dan 'data'.
  List<Map<String, dynamic>> getPendingTransactions() {
    return _box.keys.map((key) {
      final value = _box.get(key);
      // Parsing value agar aman
      final data = Map<String, dynamic>.from(value as Map);
      return {'key': key, 'data': data};
    }).toList();
  }

  /// 3. Hapus transaksi setelah berhasil dikirim ke API/BE.
  Future<void> removeSyncedTransaction(dynamic key) async {
    await _box.delete(key);
    notifyListeners();
  }

  /// Hapus semua transaksi lokal (opsional).
  Future<void> clearAllTransactions() async {
    await _box.clear();
    notifyListeners();
  }
}
