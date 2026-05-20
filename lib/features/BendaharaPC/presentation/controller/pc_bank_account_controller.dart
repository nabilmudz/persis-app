import 'package:flutter/foundation.dart';
import 'package:persis_app/core/network/api_client.dart';
import 'package:persis_app/core/storage/secure_storage_service.dart';
import 'dart:convert';
import '../../../BendaharaPC/data/datasources/bank_account_remote_datasources.dart';
import '../../../BendaharaPC/data/datasources/payment_method_remote_datasources.dart';
import '../../../BendaharaPC/data/models/bank_account_model.dart';
import '../../../BendaharaPC/data/models/payment_method_model.dart';

class PcBankAccountController extends ChangeNotifier {
  PcBankAccountController({BankAccountRemoteDataSource? dataSource})
    : _dataSource =
          dataSource ?? BankAccountRemoteDataSource(ApiClient.baseUrl),
      _paymentMethodDataSource = PaymentMethodRemoteDataSource(
        ApiClient.baseUrl,
      );

  final BankAccountRemoteDataSource _dataSource;
  final PaymentMethodRemoteDataSource _paymentMethodDataSource;
  final List<BankAccountModel> _bankAccounts = <BankAccountModel>[];
  final List<PaymentMethodModel> _paymentMethods = <PaymentMethodModel>[];

  bool _isLoading = false;
  bool _isLoadingPaymentMethods = false;
  String? _errorMessage;

  List<BankAccountModel> get bankAccounts =>
      List<BankAccountModel>.unmodifiable(_bankAccounts);
  List<PaymentMethodModel> get paymentMethods =>
      List<PaymentMethodModel>.unmodifiable(_paymentMethods);
  bool get isLoading => _isLoading;
  bool get isLoadingPaymentMethods => _isLoadingPaymentMethods;
  String? get errorMessage => _errorMessage;

  String? get transferBankPaymentMethodId {
    for (final method in _paymentMethods) {
      if (_isTransferBankMethod(method)) {
        return method.id;
      }
    }
    return null;
  }

  String? get qrisPaymentMethodId {
    for (final method in _paymentMethods) {
      if (_isQrisMethod(method)) {
        return method.id;
      }
    }
    return null;
  }

  List<BankAccountModel> get qrisAccounts =>
      _bankAccounts.where((account) => isQrisAccount(account)).toList();

  Future<String?> resolveTransferBankPaymentMethodId() async {
    await _ensurePaymentMethodsLoaded();
    return _resolvePaymentMethodIdByLabel(
      const ['Pembayaran via Virtual Account atau transfer antar bank'],
      exactCodes: const ['Transfer Bank'],
    );
  }

  Future<String?> resolveQrisPaymentMethodId() async {
    await _ensurePaymentMethodsLoaded();

    try {
      final qrisMethod = _paymentMethods.firstWhere(
        (method) => _isQrisMethod(method),
      );
      return qrisMethod.id;
    } catch (e) {
      print('❌ QRIS Method tidak ditemukan di dalam list');
      return null;
    }
  }

  Future<String?> resolveRegionId() async {
    final token = await SecureStorageService.read(
      SecureStorageService.accessTokenKey,
    );

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      final payload = _decodeJwtPayload(parts[1]);
      return _extractRegionId(payload);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadPaymentMethods() async {
    _isLoadingPaymentMethods = true;
    notifyListeners();

    try {
      final methods = await _paymentMethodDataSource.getAllPaymentMethods();
      print('===== PAYMENT METHODS LOADED =====');
      print('Loaded ${methods.length} payment methods');
      for (var method in methods) {
        print('Method: code=${method.code}, label=${method.label}');
      }
      _paymentMethods
        ..clear()
        ..addAll(methods);
    } catch (e) {
      print('===== ERROR LOADING PAYMENT METHODS =====');
      print('Error in loadPaymentMethods: $e');
      _errorMessage = 'Error loading payment methods: $e';
    } finally {
      _isLoadingPaymentMethods = false;
      notifyListeners();
    }
  }

  Future<void> loadBankAccounts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final accounts = await _dataSource.getAll();
      print('Loaded ${accounts.length} bank accounts');
      for (var account in accounts) {
        print('Account: ${account.bankName} - ${account.accountNumber}');
      }
      _bankAccounts
        ..clear()
        ..addAll(accounts);
    } catch (e) {
      _errorMessage = 'Error loading bank accounts: $e';
      print('Error in loadBankAccounts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBankAccount(BankAccountModel account) async {
    try {
      print('===== ADD BANK ACCOUNT =====');
      print(
        'Received account with paymentMethodId: "${account.paymentMethodId}"',
      );
      await _dataSource.create(account);
      await loadBankAccounts();
      return true;
    } catch (e) {
      _errorMessage = 'Error adding bank account: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBankAccount(String id, BankAccountModel account) async {
    try {
      await _dataSource.update(id, account);
      await loadBankAccounts();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating bank account: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBankAccount(String id) async {
    try {
      await _dataSource.delete(id);
      await loadBankAccounts();
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting bank account: $e';
      notifyListeners();
      return false;
    }
  }

  bool _isTransferBankMethod(PaymentMethodModel method) {
    final code = _normalize(method.code);
    final label = _normalize(method.label);

    return code == 'bank_transfer' ||
        code == 'transfer_bank' ||
        code == 'transfer' ||
        label.contains('transfer bank') ||
        label.contains('bank transfer');
  }

  bool _isQrisMethod(PaymentMethodModel method) {
    final code = _normalize(method.code);
    final label = _normalize(method.label);

    return code == 'qris' || code.contains('qris') || label.contains('qris');
  }

  Future<String?> _resolvePaymentMethodIdByLabel(
    List<String> labels, {
    List<String> exactCodes = const [],
    List<String> exactLabels = const [],
    List<String> fallbackCodes = const [],
  }) async {
    for (final method in _paymentMethods) {
      final normalizedCode = _normalize(method.code);
      print('  Comparing normalized code: "$normalizedCode" with exactCodes');
      if (exactCodes.any((code) => normalizedCode == _normalize(code))) {
        print('  ✓ MATCH! Returning id: ${method.id}');
        return method.id;
      }
    }

    for (final method in _paymentMethods) {
      final normalizedLabel = _normalize(method.label);
      print(
        '  Comparing normalized label: "$normalizedLabel" with exactLabels',
      );
      if (exactLabels.any((label) => normalizedLabel == _normalize(label))) {
        print('  ✓ MATCH! Returning id: ${method.id}');
        return method.id;
      }
    }

    for (final method in _paymentMethods) {
      final normalizedLabel = _normalize(method.label);
      if (labels.any((label) => normalizedLabel == _normalize(label))) {
        print('  ✓ MATCH! Returning id: ${method.id}');
        return method.id;
      }
    }

    print('No labels match. Checking fallbackCodes...');
    for (final method in _paymentMethods) {
      final normalizedCode = _normalize(method.code);
      if (fallbackCodes.any((code) => normalizedCode == _normalize(code))) {
        print('  ✓ MATCH! Returning id: ${method.id}');
        return method.id;
      }
    }

    print('❌ NO MATCH FOUND. Returning null');
    return null;
  }

  Future<void> _ensurePaymentMethodsLoaded() async {
    print('===== ENSURE PAYMENT METHODS LOADED =====');
    if (_paymentMethods.isEmpty) {
      print('Payment methods empty. Loading...');
      await loadPaymentMethods();
    } else {
      print('Payment methods already loaded. Count: ${_paymentMethods.length}');
    }
  }

  bool isQrisAccount(BankAccountModel account) {
    final qrisMethodId = qrisPaymentMethodId;
    if (qrisMethodId != null && account.paymentMethodId == qrisMethodId) {
      return true;
    }

    final bankName = _normalize(account.bankName);
    return bankName == 'qris' ||
        (account.qrisImageUrl?.isNotEmpty ?? false) && bankName.isEmpty;
  }

  String _normalize(String? value) => value?.trim().toLowerCase() ?? '';

  Map<String, dynamic> _decodeJwtPayload(String payloadPart) {
    final normalized = base64Url.normalize(payloadPart);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payload = jsonDecode(decoded);

    if (payload is Map<String, dynamic>) {
      return payload;
    }

    return <String, dynamic>{};
  }

  String? _extractRegionId(Map<String, dynamic> json) {
    final directCandidates = <dynamic>[
      json['region_id'],
      json['regionId'],
      json['region'],
    ];

    for (final candidate in directCandidates) {
      final resolved = _extractIdValue(candidate);
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    }

    for (final value in json.values) {
      if (value is Map<String, dynamic>) {
        final nested = _extractRegionId(value);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return null;
  }

  String? _extractIdValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (value is Map<String, dynamic>) {
      final nestedCandidates = <dynamic>[
        value['_id'],
        value['id'],
        value['region_id'],
        value['regionId'],
      ];

      for (final nested in nestedCandidates) {
        final resolved = _extractIdValue(nested);
        if (resolved != null && resolved.isNotEmpty) {
          return resolved;
        }
      }
    }

    return null;
  }
}
