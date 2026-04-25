import 'package:flutter/material.dart';

class OfflineWarningBanner extends StatelessWidget {
  final bool isOffline;
  final String message;

  const OfflineWarningBanner({
    super.key,
    required this.isOffline,
    this.message =
        'Anda sedang offline. Data akan disimpan sementara di perangkat.',
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade700,
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}