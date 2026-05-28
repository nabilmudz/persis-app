import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:persis_app/features/BendaharaPJ/data/models/transaction_model.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

String formatRupiah(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);

    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  final formatted = buffer.toString();
  return amount < 0 ? 'Rp -$formatted' : 'Rp $formatted';
}

class PjTransactionCreationResult {
  final TransactionModel transaction;
  final List<int> selectedMonths;
  final int year;
  final int totalAmount;
  final bool syncedToBackend;
  final DateTime generatedAt;

  const PjTransactionCreationResult({
    required this.transaction,
    required this.selectedMonths,
    required this.year,
    required this.totalAmount,
    required this.syncedToBackend,
    required this.generatedAt,
  });
}

class PjInvoiceLineItem {
  final int month;
  final int year;
  final String label;
  final int amount;

  const PjInvoiceLineItem({
    required this.month,
    required this.year,
    required this.label,
    required this.amount,
  });
}

class PjInvoiceData {
  final UserModel member;
  final TransactionModel transaction;
  final List<PjInvoiceLineItem> items;
  final List<int> months;
  final int year;
  final int totalAmount;
  final bool syncedToBackend;
  final DateTime generatedAt;
  final String? accByName;

  const PjInvoiceData({
    required this.member,
    required this.transaction,
    required this.items,
    required this.months,
    required this.year,
    required this.totalAmount,
    required this.syncedToBackend,
    required this.generatedAt,
    this.accByName,
  });

  PjInvoiceData copyWith({
    UserModel? member,
    TransactionModel? transaction,
    List<PjInvoiceLineItem>? items,
    List<int>? months,
    int? year,
    int? totalAmount,
    bool? syncedToBackend,
    DateTime? generatedAt,
    String? accByName,
  }) {
    return PjInvoiceData(
      member: member ?? this.member,
      transaction: transaction ?? this.transaction,
      items: items ?? this.items,
      months: months ?? this.months,
      year: year ?? this.year,
      totalAmount: totalAmount ?? this.totalAmount,
      syncedToBackend: syncedToBackend ?? this.syncedToBackend,
      generatedAt: generatedAt ?? this.generatedAt,
      accByName: accByName ?? this.accByName,
    );
  }

  factory PjInvoiceData.fromCreationResult({
    required UserModel member,
    required PjTransactionCreationResult result,
    String? accByName,
  }) {
    final sourceItems =
        result.transaction.items ?? const <TransactionItemModel>[];
    final invoiceItems = <PjInvoiceLineItem>[];

    for (var index = 0; index < result.selectedMonths.length; index++) {
      final month = result.selectedMonths[index];
      final item = index < sourceItems.length ? sourceItems[index] : null;
      final amount = item?.amount ?? 0;
      final label = item?.description?.trim().isNotEmpty == true
          ? item!.description!.trim()
          : '${_monthNames[month - 1]} ${result.year}';

      invoiceItems.add(
        PjInvoiceLineItem(
          month: month,
          year: result.year,
          label: label,
          amount: amount,
        ),
      );
    }

    return PjInvoiceData(
      member: member,
      transaction: result.transaction,
      items: invoiceItems,
      months: List<int>.from(result.selectedMonths),
      year: result.year,
      totalAmount: result.totalAmount,
      syncedToBackend: result.syncedToBackend,
      generatedAt: result.generatedAt,
      accByName: accByName,
    );
  }

  factory PjInvoiceData.fromTransaction({
    required UserModel member,
    required TransactionModel transaction,
    String? accByName,
  }) {
    final invoiceItems = <PjInvoiceLineItem>[];
    final months = <int>[];
    int year = DateTime.now().year;

    final sourceItems = transaction.items ?? const <TransactionItemModel>[];
    for (final item in sourceItems) {
      final resolved = _resolveItemPeriod(item, transaction.createdAt);
      final desc = item.description?.trim() ?? '';
      final month = resolved.$1;
      year = resolved.$2 ?? year;

      if (month > 0) {
        months.add(month);
      }

      invoiceItems.add(
        PjInvoiceLineItem(
          month: month,
          year: year,
          label: desc.isNotEmpty ? desc : _monthLabel(month, year),
          amount: item.amount ?? 0,
        ),
      );
    }

    final createdAt =
        DateTime.tryParse(transaction.createdAt ?? '') ?? DateTime(1900);

    return PjInvoiceData(
      member: member,
      transaction: transaction,
      items: invoiceItems,
      months: months,
      year: year,
      totalAmount: transaction.totalAmount ?? 0,
      syncedToBackend:
          true, // If it's a TransactionModel from history, it's synced
      generatedAt: createdAt,
      accByName: accByName,
    );
  }

  String get memberName {
    final fullname = member.fullname?.trim();
    if (fullname != null && fullname.isNotEmpty) {
      return fullname;
    }

    final name = member.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final code = member.code?.trim();
    if (code != null && code.isNotEmpty) {
      return code;
    }

    return 'Pengguna';
  }

  String get memberCode {
    final code = member.code?.trim();
    return code != null && code.isNotEmpty ? code : '-';
  }

  String get memberPhone => member.noHp?.trim() ?? '';

  /// Format: {NPA}-{MM}-{YY}
  /// Contoh: 12345-05-26 (untuk iuran Mei, tahun 2026)
  String get invoiceNumber {
    final npa = memberCode != '-' ? memberCode : 'NA';
    final month = months.isNotEmpty
        ? months.first.toString().padLeft(2, '0')
        : generatedAt.month.toString().padLeft(2, '0');
    final shortYear = (year % 100).toString().padLeft(2, '0');
    return '$npa-$month-$shortYear';
  }

  String get monthLabelSummary {
    if (months.isEmpty) {
      return '-';
    }

    final uniqueMonths = months.toSet().toList()..sort();
    return uniqueMonths.map((month) => _monthNames[month - 1]).join(', ');
  }

  String get statusLabel =>
      syncedToBackend ? 'Terkirim ke Server' : 'Tersimpan Lokal';

  String get generatedAtLabel {
    if (generatedAt.year == 1900) {
      return '-';
    }

    // Tampilkan dalam waktu WIB (UTC+7)
    final dt = generatedAt.isUtc ? generatedAt.toLocal() : generatedAt;
    final day = dt.day.toString().padLeft(2, '0');
    final monthName = _monthNames[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $monthName $year, $hour:$minute';
  }

  String get totalFormatted => formatRupiah(totalAmount);

  String buildWhatsappMessage() {
    final buffer = StringBuffer()
      ..writeln('Invoice Iuran InfaQu')
      ..writeln('No. Invoice: $invoiceNumber')
      ..writeln('Nama: $memberName')
      ..writeln('Kode/NPA: $memberCode')
      ..writeln('Periode: $monthLabelSummary $year')
      ..writeln('Tanggal: $generatedAtLabel')
      ..writeln('Status: $statusLabel')
      ..writeln('Di ACC oleh: ${(() {
        final acc = (transaction.accBy ?? transaction.verifiedBy ?? '').trim();
        return (acc.isEmpty || acc == '-') ? 'Bendahara PJ' : acc;
      })()}')
      ..writeln('')
      ..writeln('Rincian:');

    for (final item in items) {
      final amountText = formatRupiah(item.amount);
      buffer.writeln('- ${item.label}: $amountText');
    }

    buffer
      ..writeln('')
      ..writeln('Total: $totalFormatted')
      ..writeln('')
      ..writeln('Silakan simpan invoice ini sebagai bukti pembayaran.');

    return buffer.toString();
  }

  static (int, int?) _resolveItemPeriod(
    TransactionItemModel item,
    String? fallbackCreatedAt,
  ) {
    // Cek sumber-sumber period secara berurutan:
    // 1. periodId (sebaiknya "YYYY-MM" format)
    // 2. duesPeriodId
    // 3. description (e.g., "Iuran Januari 2026")
    final periodSources = <String?>[
      item.periodId,
      item.duesPeriodId,
      item.description,
    ];

    for (final source in periodSources) {
      final resolved = _resolveMonthYearFromText(source);
      if (resolved.$1 > 0) {
        return resolved;
      }
    }

    // Jangan fallback ke createdAt.month karena itu tanggal PEMBUATAN TRANSAKSI,
    // bukan bulan iuran yang dibayar (akan salah untuk catch-up payment).
    // Kembalikan (0, null) → caller akan handle sebagai "bulan tidak diketahui".
    return (0, null);
  }

  static (int, int?) _resolveMonthYearFromText(String? raw) {
    final src = raw?.trim() ?? '';
    if (src.isEmpty) {
      return (0, null);
    }

    final compactMatch = RegExp(r'(\d{4})[-_/](\d{1,2})').firstMatch(src);
    if (compactMatch != null) {
      final year = int.tryParse(compactMatch.group(1)!);
      final month = int.tryParse(compactMatch.group(2)!);
      if (year != null && month != null && month >= 1 && month <= 12) {
        return (month, year);
      }
    }

    final lowerSrc = src.toLowerCase();
    for (var i = 0; i < _monthNames.length; i++) {
      if (lowerSrc.contains(_monthNames[i].toLowerCase())) {
        final yearMatch = RegExp(r'(19|20)\d{2}').firstMatch(src);
        return (
          i + 1,
          yearMatch != null ? int.tryParse(yearMatch.group(0)!) : null,
        );
      }
    }

    return (0, null);
  }

  static String _monthLabel(int month, int year) {
    if (month < 1 || month > 12) {
      return 'Iuran';
    }

    return '${_monthNames[month - 1]} $year';
  }
}

class PjInvoiceController extends ChangeNotifier {
  PjInvoiceController(this.invoiceData);

  final PjInvoiceData invoiceData;

  bool _isSharing = false;
  String? _errorMessage;

  bool get isSharing => _isSharing;
  String? get errorMessage => _errorMessage;

  Future<bool> shareInvoiceAsImage(GlobalKey boundaryKey) async {
    if (_isSharing) {
      return false;
    }

    _isSharing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Capture Screenshot
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        _errorMessage = 'Gagal mengambil gambar invoice.';
        return false;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _errorMessage = 'Gagal memproses gambar.';
        return false;
      }

      final bytes = byteData.buffer.asUint8List();

      // 2. Save to Temp File
      final tempDir = await getTemporaryDirectory();
      final fileName = 'Invoice_${invoiceData.invoiceNumber}.png';
      final file = await File('${tempDir.path}/$fileName').create();
      await file.writeAsBytes(bytes);

      // 3. Share via Share Sheet (Most reliable for images)
      final xFile = XFile(file.path);
      final message = invoiceData.buildWhatsappMessage();

      await Share.shareXFiles(
        [xFile],
        text: message,
        subject: 'Invoice Iuran InfaQu',
      );

      return true;
    } catch (e) {
      _errorMessage = 'Gagal membagikan invoice: $e';
      return false;
    } finally {
      _isSharing = false;
      notifyListeners();
    }
  }

  Future<bool> saveInvoiceToGallery(GlobalKey boundaryKey) async {
    if (_isSharing) {
      return false;
    }

    _isSharing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Capture Screenshot
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        _errorMessage = 'Gagal mengambil gambar invoice.';
        return false;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _errorMessage = 'Gagal memproses gambar.';
        return false;
      }

      final bytes = byteData.buffer.asUint8List();

      // 2. Permission Check
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          _errorMessage = 'Izin galeri diperlukan untuk menyimpan gambar.';
          return false;
        }
      }

      // 3. Save to Gallery
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/Invoice_${invoiceData.invoiceNumber}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Gal.putImage(filePath);

      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan: $e';
      return false;
    } finally {
      _isSharing = false;
      notifyListeners();
    }
  }

  Future<bool> shareInvoiceAsText() async {
    if (_isSharing) {
      return false;
    }

    _isSharing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = Uri.encodeComponent(invoiceData.buildWhatsappMessage());
      final phone = _normalizeIndonesianPhone(invoiceData.memberPhone);
      final url = phone != null
          ? Uri.parse('https://wa.me/$phone?text=$message')
          : Uri.parse('https://wa.me/?text=$message');

      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _errorMessage = 'Tidak dapat membuka WhatsApp.';
      }

      return launched;
    } catch (e) {
      _errorMessage = 'Gagal membuka WhatsApp: $e';
      return false;
    } finally {
      _isSharing = false;
      notifyListeners();
    }
  }

  String? _normalizeIndonesianPhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return null;
    }

    if (digits.startsWith('62')) {
      return digits;
    }

    if (digits.startsWith('0')) {
      return '62${digits.substring(1)}';
    }

    if (digits.startsWith('8')) {
      return '62$digits';
    }

    return digits;
  }

}

const List<String> _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];
