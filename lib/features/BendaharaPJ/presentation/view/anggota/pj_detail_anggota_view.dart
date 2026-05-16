import 'package:flutter/material.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';
import 'package:persis_app/features/anggota/data/datasources/user_remote_datasource.dart';
import 'package:persis_app/core/network/api_client.dart';

class PjDetailAnggotaView extends StatelessWidget {
  final UserModel member;

  const PjDetailAnggotaView({super.key, required this.member});

  Future<UserModel> _fetchMemberDetail() async {
    if (member.id == null || member.id!.isEmpty) return member;
    try {
      final userRemote = UserRemoteDataSource(ApiClient.baseUrl);
      return await userRemote.getOneUsers(member.id!);
    } catch (_) {
      return member;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<UserModel>(
        future: _fetchMemberDetail(),
        builder: (context, snapshot) {
          final displayMember = snapshot.data ?? member;
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF073D4D),
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayMember.fullname ?? 'Nama tidak tersedia',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF073D4D),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            'NPA: ${displayMember.npa ?? 'Tidak tersedia'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Detail Profil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF073D4D),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Nama Lengkap',
                  displayMember.fullname ?? 'Tidak tersedia',
                ),
                _buildDetailRow('NPA', displayMember.npa ?? 'Tidak tersedia'),
                _buildDetailRow('Email', displayMember.email ?? 'Tidak tersedia'),
                _buildDetailRow('No. HP', displayMember.noHp ?? 'Tidak tersedia'),
                _buildDetailRow('Role', displayMember.role ?? 'Tidak tersedia'),
                _buildDetailRow(
                  'Status',
                  displayMember.isActive == true ? 'Aktif' : 'Tidak Aktif',
                ),
                _buildDetailRow(
                  'Bergabung',
                  displayMember.createdAt != null
                      ? '${displayMember.createdAt!.day}/${displayMember.createdAt!.month}/${displayMember.createdAt!.year}'
                      : 'Tidak tersedia',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF073D4D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
