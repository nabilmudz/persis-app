import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:persis_app/core/network/api_client.dart';
import '../../../BendaharaPJ/data/datasources/transaction_remote_datasources.dart';

class PcLaporanController extends ChangeNotifier {
  final TransactionRemoteDataSource _dataSource;

  PcLaporanController({TransactionRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? TransactionRemoteDataSource();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<Map<String, dynamic>?> exportLaporan({
    required int month,
    required int year,
    String? type,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _dataSource.exportTransactions(
        month,
        year,
        type: type,
      );

      if (result != null && result['url'] != null) {
        String urlString = result['url'];
        if (!urlString.startsWith('http')) {
          final baseUrl = ApiClient.baseUrl.endsWith('/')
              ? ApiClient.baseUrl.substring(0, ApiClient.baseUrl.length - 1)
              : ApiClient.baseUrl;
          urlString = '$baseUrl$urlString';
        }

        final url = Uri.parse(urlString);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _errorMessage = 'Tidak dapat membuka tautan unduhan: $urlString';
        }
      } else if (result != null && result['data'] != null) {
        final dataCount = (result['data'] as List?)?.length ?? 0;
        return result;
      } else if (result != null && result['message'] != null) {
        _errorMessage = result['message'];
        debugPrint('⚠ API message: $_errorMessage');
      } else if (result == null) {
        _errorMessage =
            'Gagal mengekspor laporan. Data tidak ditemukan di server.';
        debugPrint('❌ API returned null');
      }
      return result;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      debugPrint('❌ Error in exportLaporan: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
