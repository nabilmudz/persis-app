class AccessControlService {
  AccessControlService._();

  static bool canAccessApproval(String role) {
    return ['bendahara_pj', 'bendahara_pc', 'bendahara_pd'].contains(role);
  }

  static bool canApproveTunai(String role) {
    return role == 'bendahara_pj';
  }

  static bool canApproveTransfer(String role) {
    return role == 'bendahara_pc';
  }

  static bool canApproveFinalReport(String role) {
    return role == 'bendahara_pd';
  }

  static bool canManagePaymentSettings(String role) {
    return role == 'bendahara_pc';
  }

  static bool canViewGlobalMonitoring(String role) {
    return role == 'bendahara_pd';
  }

  static bool canViewPersonalHistory(String role) {
    return role == 'anggota';
  }

  static bool isAnggota(String role) {
    return role == 'anggota';
  }

  static bool isBendaharaPC(String role) {
    return role == 'bendahara_pc';
  }

  static bool isBendaharaPJ(String role) {
    return role == 'bendahara_pj';
  }

  static bool isBendaharaPD(String role) {
    return role == 'bendahara_pd';
  }

  static bool hasAnyRole(String role, List<String> allowedRoles) {
    return allowedRoles.any((r) => r == role);
  }

  static bool canManagePaymentMethods(String role) {
    return role == 'bendahara_pc';
  }

  static bool canUploadBuktiTransactionItem(String role) {
    return role == 'bendahara_pc';
  }

  static bool canViewNonTunaiTransactions(String role) {
    return role == 'anggota';
  }

  static bool canViewPaymentStatusMatrix(String role) {
    return role == 'bendahara_pc' ||
        role == 'bendahara_pj' ||
        role == 'bendahara_pd';
  }
}
