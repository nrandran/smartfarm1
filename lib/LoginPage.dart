import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'HomePage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController namaC = TextEditingController();
  final TextEditingController passwordC = TextEditingController();
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref(
    "SmartFarm/User",
  );

  bool _isLoading = false;

  // FUNGSI HASH PASSWORD (KEAMANAN)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _login() async {
    final name = namaC.text.trim();
    final password = passwordC.text;

    if (name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama dan password wajib diisi.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await dbRef.get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Belum ada data pengguna terdaftar.")),
        );
        setState(() => _isLoading = false);
        return;
      }

      final hashedPassword = _hashPassword(password);
      bool found = false;

      String userId = "";
      String lokasi = "";

      // PENCARIAN USER BERDASARKAN NAMA & PASSWORD
      for (final child in snapshot.children) {
        final data = Map<String, dynamic>.from(child.value as Map);

        if (data['name'] == name && data['password_hash'] == hashedPassword) {
          found = true;
          userId = child.key!;
          lokasi = data['lokasi'] ?? "-";
          break;
        }
      }

      // JIKA LOGIN BERHASIL
      if (found) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Login berhasil!")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HomePage(userId: userId, userName: name, userLocation: lokasi),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nama atau password salah.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    namaC.dispose();
    passwordC.dispose();
    super.dispose();
  }

  // UI HALAMAN LOGIN
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Text(
              "Masuk ke Akun Anda",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Gunakan nama dan password yang sudah terdaftar.",
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildInputField(
                    label: "Nama",
                    hint: "Masukkan nama",
                    controller: namaC,
                  ),
                  _buildInputField(
                    label: "Password",
                    hint: "Masukkan password",
                    controller: passwordC,
                    obscureText: true,
                  ),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
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
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "LOGIN",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET INPUT
  static Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              fillColor: Colors.grey.shade200,
              filled: true,
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
