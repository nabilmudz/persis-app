import 'package:flutter/foundation.dart';
import 'package:persis_app/features/BendaharaPC/data/models/iuran_model.dart';
import 'package:persis_app/features/BendaharaPC/data/datasources/iuran_local_datasources.dart';
import 'package:persis_app/features/anggota/data/datasources/anggota_local_datasource.dart';
import 'package:persis_app/features/anggota/data/models/anggota_model.dart';
import 'package:persis_app/features/anggota/data/models/lokasi_model.dart';
import 'pj_verif_controller.dart';

export 'pj_verif_controller.dart'
    show PjMonthStatus, PjPaymentCartItem, PjSubmitResult;

class PjController extends ChangeNotifier {
  PjController() {
    _verifController = PjVerifController(
      daftarIuran: daftarIuran,
      members: _members,
    );
    _verifController.addListener(_onVerifChanged);
  }

  List<IuranModel> daftarIuran = dummyDaftarIuran;
  final List<AnggotaModel> _members = dummyAnggota;
  late final PjVerifController _verifController;

  List<AnggotaModel> get members => List<AnggotaModel>.unmodifiable(_members);
  List<PjPaymentCartItem> get cartItems => _verifController.cartItems;
  int get cartItemCount => _verifController.cartItemCount;
  double get cartTotalNominal => _verifController.cartTotalNominal;

  void _onVerifChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _verifController.removeListener(_onVerifChanged);
    _verifController.dispose();
    super.dispose();
  }

  List<AnggotaModel> filterMembers(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return members;
    }

    return _members.where((member) {
      return member.nama.toLowerCase().contains(trimmed) ||
          member.npa.toLowerCase().contains(trimmed) ||
          member.lokasiPj.nama.toLowerCase().contains(trimmed);
    }).toList();
  }

  bool isInCart({
    required String anggotaId,
    required int month,
    required int year,
  }) {
    return _verifController.isInCart(
      anggotaId: anggotaId,
      month: month,
      year: year,
    );
  }

  void addMonthToCart({
    required AnggotaModel member,
    required int month,
    required int year,
    double? nominal,
  }) {
    _verifController.addMonthToCart(
      member: member,
      month: month,
      year: year,
      nominal: nominal,
    );
  }

  void removeFromCart(String cartItemId) {
    _verifController.removeFromCart(cartItemId);
  }

  void removeMemberFromCart(String anggotaId) {
    _verifController.removeMemberFromCart(anggotaId);
  }

  void clearCart() {
    _verifController.clearCart();
  }

  PjSubmitResult? submitCart({
    MetodePembayaran metodePembayaran = MetodePembayaran.tunai,
  }) {
    return _verifController.submitCart(metodePembayaran: metodePembayaran);
  }

  String _lokasiPjNamaByAnggotaId(String anggotaId) {
    final member = _members.cast<AnggotaModel?>().firstWhere(
      (item) => item?.id == anggotaId,
      orElse: () => null,
    );
    return member?.lokasiPj.nama ?? '';
  }

  int tunggakanCountByMember(String anggotaId) {
    final lokasiPjNama = _lokasiPjNamaByAnggotaId(anggotaId);
    return daftarIuran.where((iuran) {
      return iuran.lokasiPjNama == lokasiPjNama &&
          (iuran.status == StatusIuran.tunggakan ||
              iuran.status == StatusIuran.belumDibayar);
    }).length;
  }

  double tunggakanNominalByMember(String anggotaId) {
    final lokasiPjNama = _lokasiPjNamaByAnggotaId(anggotaId);
    return daftarIuran
        .where((iuran) {
          return iuran.lokasiPjNama == lokasiPjNama &&
              (iuran.status == StatusIuran.tunggakan ||
                  iuran.status == StatusIuran.belumDibayar);
        })
        .fold<double>(0, (total, iuran) => total + iuran.nominal);
  }

  double getNominalForMemberMonth({
    required String anggotaId,
    required int month,
    required int year,
  }) {
    return _verifController.getNominalForMemberMonth(
      anggotaId: anggotaId,
      month: month,
      year: year,
    );
  }

  PjMonthStatus getMonthStatus({
    required String anggotaId,
    required int month,
  }) {
    return _verifController.getMonthStatus(anggotaId: anggotaId, month: month);
  }

  void accPembayaran(String idIuran, TingkatLokasi roleBendahara) {
    _verifController.accPembayaran(idIuran, roleBendahara);
  }
}
