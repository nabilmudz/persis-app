import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:persis_app/features/bendahara_pj/data/datasources/transaction_remote_datasources.dart';

class PcBuktiController extends ChangeNotifier {
  final TransactionRemoteDataSource _dataSource;
  final ImagePicker _picker = ImagePicker();

  PcBuktiController({TransactionRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? TransactionRemoteDataSource();

  bool _isUploading = false;
  String? _errorMessage;
  File? _selectedFile;
  String? _uploadedUrl;
  bool _isPatching = false;

  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  File? get selectedFile => _selectedFile;
  String? get uploadedUrl => _uploadedUrl;
  bool get isPatching => _isPatching;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        _selectedFile = File(picked.path);
        _uploadedUrl = null;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Gagal memilih gambar: $e';
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedFile = null;
    _uploadedUrl = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<String?> uploadBukti() async {
    if (_selectedFile == null) {
      _errorMessage = 'Pilih gambar terlebih dahulu.';
      notifyListeners();
      return null;
    }

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = await _dataSource.uploadBuktiBayar(_selectedFile!);
      if (url == null || url.isEmpty) {
        _errorMessage = 'Gagal upload bukti: server tidak mengembalikan URL.';
        _isUploading = false;
        notifyListeners();
        return null;
      }
      _uploadedUrl = url;
      _isUploading = false;
      notifyListeners();
      return url;
    } catch (e) {
      _errorMessage = 'Upload gagal: $e';
      _isUploading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTransactionItemBukti({
    required String itemId,
    required String buktiUrl,
  }) async {
    _isPatching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _dataSource.updateTransactionItem(itemId, {
        'bukti_url': buktiUrl,
      });
      _isPatching = false;
      if (!success) {
        _errorMessage = 'Gagal menyimpan bukti ke server.';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Gagal update: $e';
      _isPatching = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> pickUploadAndPatch(String itemId) async {
    await pickImage();
    if (_selectedFile == null) return false;

    final url = await uploadBukti();
    if (url == null) return false;

    return updateTransactionItemBukti(itemId: itemId, buktiUrl: url);
  }
}
