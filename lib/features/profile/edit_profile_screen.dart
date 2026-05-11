import 'package:flutter/material.dart';
import 'package:persis_app/features/anggota/data/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _npaController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullname ?? widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _npaController = TextEditingController(text: widget.user.npa);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Informasi Pribadi")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _npaController,
            readOnly: true, // NPA biasanya ga boleh ganti sembarangan
            decoration: const InputDecoration(labelText: "NPA (Hanya Baca)", border: OutlineInputBorder(), fillColor: Color(0xFFF5F5F5), filled: true),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A7A4A), padding: const EdgeInsets.all(16)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui!")));
              Navigator.pop(context);
            },
            child: const Text("Simpan Perubahan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}