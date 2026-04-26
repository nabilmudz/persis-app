import 'package:flutter/foundation.dart';
import 'package:persis_app/features/BendaharaPC/data/models/iuran_model.dart';
import 'package:persis_app/features/anggota/data/models/anggota_model.dart';
import 'package:persis_app/features/anggota/data/models/lokasi_model.dart';
import 'package:persis_app/helpers/object_id_helper.dart';

enum PjMonthStatus { lunas, tunggakan, belumJatuhTempo }

class PjPaymentCartItem {
  final String id;
  final String anggotaId;
  final String anggotaNama;
  final int month;
  final int year;
  final double nominal;

  const PjPaymentCartItem({
    required this.id,
    required this.anggotaId,
    required this.anggotaNama,
    required this.month,
    required this.year,
    required this.nominal,
  });

  String get periodLabel => '$month/$year';
}

class PjSubmitResult {
  final String transactionId;
  final int totalItems;
  final double totalNominal;

  const PjSubmitResult({
    required this.transactionId,
    required this.totalItems,
    required this.totalNominal,
  });
}

class PjVerifController extends ChangeNotifier {
  static const double _fallbackNominal = 10000;

  PjVerifController({
    required List<IuranModel> daftarIuran,
    required List<AnggotaModel> members,
  }) : _daftarIuran = daftarIuran,
       _members = members;

  final List<IuranModel> _daftarIuran;
  final List<AnggotaModel> _members;
  final List<PjPaymentCartItem> _cartItems = [];

  String _lokasiPjNamaByAnggotaId(String anggotaId) {
    final member = _members.cast<AnggotaModel?>().firstWhere(
      (item) => item?.id == anggotaId,
      orElse: () => null,
    );
    return member?.lokasiPj.nama ?? '';
  }

  List<PjPaymentCartItem> get cartItems =>
      List<PjPaymentCartItem>.unmodifiable(_cartItems);
  int get cartItemCount => _cartItems.length;
  double get cartTotalNominal =>
      _cartItems.fold(0, (total, item) => total + item.nominal);

  bool isInCart({
    required String anggotaId,
    required int month,
    required int year,
  }) {
    return _cartItems.any(
      (item) =>
          item.anggotaId == anggotaId &&
          item.month == month &&
          item.year == year,
    );
  }

  void addMonthToCart({
    required AnggotaModel member,
    required int month,
    required int year,
    double? nominal,
  }) {
    if (isInCart(anggotaId: member.id, month: month, year: year)) {
      return;
    }

    final resolvedNominal =
        nominal ??
        getNominalForMemberMonth(
          anggotaId: member.id,
          month: month,
          year: year,
        );

    _cartItems.add(
      PjPaymentCartItem(
        id: ObjectIdHelper.generateLocalId(),
        anggotaId: member.id,
        anggotaNama: member.nama,
        month: month,
        year: year,
        nominal: resolvedNominal,
      ),
    );

    notifyListeners();
  }

  void removeFromCart(String cartItemId) {
    _cartItems.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
  }

  void removeMemberFromCart(String anggotaId) {
    _cartItems.removeWhere((item) => item.anggotaId == anggotaId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  PjSubmitResult? submitCart({
    MetodePembayaran metodePembayaran = MetodePembayaran.tunai,
  }) {
    if (_cartItems.isEmpty) {
      return null;
    }

    final transactionId = ObjectIdHelper.generateLocalId();

    for (final item in _cartItems) {
      _daftarIuran.add(
        IuranModel(
          id: ObjectIdHelper.generateLocalId(),
          lokasiPjNama: _lokasiPjNamaByAnggotaId(item.anggotaId),
          nominal: item.nominal,
          tanggalBayar: DateTime(item.year, item.month, 1),
          buktiTransferUrl: null,
          metodePembayaran: metodePembayaran,
          status: StatusIuran.menungguVerifikasi,
          catatan: 'Masuk transaksi keranjang: $transactionId',
        ),
      );
    }

    final result = PjSubmitResult(
      transactionId: transactionId,
      totalItems: _cartItems.length,
      totalNominal: cartTotalNominal,
    );

    _cartItems.clear();
    notifyListeners();
    return result;
  }

  double getNominalForMemberMonth({
    required String anggotaId,
    required int month,
    required int year,
  }) {
    final lokasiPjNama = _lokasiPjNamaByAnggotaId(anggotaId);
    final monthlyRecord = _daftarIuran.cast<IuranModel?>().firstWhere(
      (iuran) =>
          iuran != null &&
          iuran.lokasiPjNama == lokasiPjNama &&
          iuran.tanggalBayar.month == month &&
          iuran.tanggalBayar.year == year,
      orElse: () => null,
    );

    if (monthlyRecord != null) {
      return monthlyRecord.nominal;
    }

    final memberRecords = _daftarIuran
      .where((iuran) => iuran.lokasiPjNama == lokasiPjNama)
        .toList();

    if (memberRecords.isEmpty) {
      return _fallbackNominal;
    }

    memberRecords.sort((a, b) => b.tanggalBayar.compareTo(a.tanggalBayar));

    return memberRecords.first.nominal;
  }

  PjMonthStatus getMonthStatus({
    required String anggotaId,
    required int month,
  }) {
    final lokasiPjNama = _lokasiPjNamaByAnggotaId(anggotaId);
    final hasVerifiedPayment = _daftarIuran.any(
      (iuran) =>
          iuran.lokasiPjNama == lokasiPjNama &&
          iuran.tanggalBayar.month == month &&
          iuran.status == StatusIuran.diverifikasi,
    );

    if (hasVerifiedPayment) {
      return PjMonthStatus.lunas;
    }

    return PjMonthStatus.belumJatuhTempo;
  }

  void accPembayaran(String idIuran, TingkatLokasi roleBendahara) {
    final index = _daftarIuran.indexWhere((i) => i.id == idIuran);

    if (index == -1) {
      print('Data Iuran tidak ditemukan!');
      return;
    }

    if (_daftarIuran[index].status == StatusIuran.belumDibayar ||
        _daftarIuran[index].status == StatusIuran.tunggakan) {
      _daftarIuran[index].status = StatusIuran.diverifikasi;
      notifyListeners();
      print('Iuran berhasil diverifikasi');
    } else {
      print('Iuran tidak terverifikasi');
    }
  }
}
