import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'HomePage.dart';

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
  final TextEditingController namaC = TextEditingController();
  final TextEditingController lokasiC = TextEditingController();
  final TextEditingController passwordC = TextEditingController();

  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child(
    "SmartFarm/User",
  );
  bool _isSaving = false;

  // 🔐 Hash password untuk keamanan
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _simpanData() async {
    final name = namaC.text.trim();
    final lokasi = lokasiC.text.trim();
    final password = passwordC.text;

    if (name.isEmpty || lokasi.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua kolom terlebih dahulu.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 🔑 Buat ID unik otomatis untuk user baru
      final newUserRef = dbRef.push();

      // 🔹 Simpan data utama user
      final newData = {
        "uid": newUserRef.key,
        "name": name,
        "lokasi": lokasi,
        "status": "Belum dicek",
        "password_hash": _hashPassword(password),
        "created_at": DateTime.now().toIso8601String(),
      };

      await newUserRef.set(newData);

      // 🔹 Buat struktur kosong untuk 3 riwayat sensor
      await newUserRef.child("Riwayat_Suhu").set({});
      await newUserRef.child("Riwayat_KelembapanTanah").set({});
      await newUserRef.child("Riwayat_IntensitasCahaya").set({});

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Akun berhasil dibuat!")));

      // 🔹 Pindah ke halaman HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(userName: name, userLocation: lokasi),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menyimpan data: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    namaC.dispose();
    lokasiC.dispose();
    passwordC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Text(
              "Daftar Akun Petani",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Kelola semua lahan pertanianmu dalam satu aplikasi!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildInputField(
                    label: "Nama",
                    hint: "ex: Budi",
                    controller: namaC,
                  ),
                  _buildInputField(
                    label: "Password",
                    hint: "Masukkan password",
                    controller: passwordC,
                    obscureText: true,
                  ),
                  _buildInputField(
                    label: "Lokasi Sawah",
                    hint: "ex: Sleman",
                    controller: lokasiC,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _simpanData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "DAFTAR",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
