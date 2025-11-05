import 'package:flutter/material.dart';
import 'daftar_page.dart';
import 'LoginPage.dart';

class PageAwal extends StatelessWidget {
  const PageAwal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bisa diganti warna background sesuai tema
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            // Optional: background image (hapus jika tidak ada asset)
            Positioned.fill(
              child: Image.asset(
                'assets/image/background.png',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.05),
                colorBlendMode: BlendMode.darken,
              ),
            ),

            // Konten utama
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Image.asset('assets/image/logo.png'),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'SMART FARM',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      'Pantau dan kelola lahan pertanianmu kapan saja — notifikasi cerdas, data realtime, dan lebih mudah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.black87),
                    ),

                    const SizedBox(height: 36),

                    // Tombol DAFTAR
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DaftarPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('DAFTAR', style: TextStyle(fontSize: 16)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tombol MASUK
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'MASUK',
                          style: TextStyle(fontSize: 16, color: Colors.green),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Footer kecil
                    TextButton(
                      onPressed: () {
                        // contoh: bisa arahkan ke halaman bantuan / tentang
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur ini belum diimplementasikan')),
                        );
                      },
                      child: const Text('Tentang Aplikasi', style: TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}