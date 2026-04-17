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
}
