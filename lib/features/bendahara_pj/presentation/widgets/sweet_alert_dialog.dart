import 'package:flutter/material.dart';

enum SweetAlertType { warning, success }

class SweetAlertDialog extends StatelessWidget {
  final SweetAlertType type;
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const SweetAlertDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
  });

  factory SweetAlertDialog.confirm({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    String confirmText = 'Ya, Lanjutkan',
    String cancelText = 'Batal',
  }) {
    return SweetAlertDialog(
      type: SweetAlertType.warning,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  factory SweetAlertDialog.success({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'OK',
  }) {
    return SweetAlertDialog(
      type: SweetAlertType.success,
      title: title,
      message: message,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }

  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Ya, Lanjutkan',
    String cancelText = 'Batal',
  }) async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return SweetAlertDialog.confirm(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: () => Navigator.of(dialogContext).pop(true),
          onCancel: () => Navigator.of(dialogContext).pop(false),
        );
      },
    );

    return shouldContinue ?? false;
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return SweetAlertDialog.success(
          title: title,
          message: message,
          confirmText: buttonText,
          onConfirm: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWarning = type == SweetAlertType.warning;
    final iconColor = isWarning
        ? const Color(0xFFF59E0B)
        : const Color(0xFF10B367);
    final icon = isWarning
        ? Icons.help_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                fontFamily: 'Poppins',
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            if (isWarning)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4B5563),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(cancelText ?? 'Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C844C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(confirmText ?? 'Ya, Lanjutkan'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C844C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(confirmText ?? 'OK'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PjPaymentConfirmationDialog extends StatelessWidget {
  final String memberName;
  final String month;
  final String amount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PjPaymentConfirmationDialog({
    super.key,
    required this.memberName,
    required this.month,
    required this.amount,
    required this.onConfirm,
    required this.onCancel,
  });

  static Future<bool> show({
    required BuildContext context,
    required String memberName,
    required String month,
    required String amount,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PjPaymentConfirmationDialog(
          memberName: memberName,
          month: month,
          amount: amount,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(color: Color(0xFF2B67EB)),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0x77D9D9D9),
                          borderRadius: BorderRadius.circular(90),
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Konfirmasi Pembayaran',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x195A83DB),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: [
                            Text(
                              memberName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF074D2C),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              amount,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF130CDF),
                                fontSize: 24,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Pembayaran bulan : ',
                                    style: TextStyle(
                                      color: Color(0xFF6A6A6A),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: month,
                                    style: const TextStyle(
                                      color: Color(0xFF360C98),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Pastikan uang tunai sudah Anda terima di tangan sebelum menekan tombol rekap di bawah ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF1D0C0C),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: onCancel,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0x89D0D9FF),
                                  foregroundColor: const Color(0xFF074D2C),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: onConfirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2B67EB),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Rekap Selesai',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
