import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_smart_farm/DeviceControlPage.dart';
import 'package:app_smart_farm/main.dart';
import 'HomePage.dart';

class ProfilPage extends StatelessWidget {
  final String userId;
  final String? userName;
  final String? userLocation;

  const ProfilPage({
    super.key,
    required this.userId,
    this.userName,
    this.userLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Profil User",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset('assets/image/back.png', width: 24, height: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    profileRow("User ID", userId),
                    const SizedBox(height: 12),
                    profileRow("Nama Pengguna", userName ?? "-"),
                    const SizedBox(height: 12),
                    profileRow("Lokasi Anda", userLocation ?? "-"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ===================== Kontrol Perangkat =====================
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeviceControlPage(
                      userId: userId,
                      userName: userName,
                      userLocation: userLocation,
                    ),
                  ),
                );
              },

              label: const Text(
                "Kontrol Perangkat",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),

            const SizedBox(height: 22),

            const Spacer(),

            // ===================== LOGOUT =====================
            Column(
              children: [
                IconButton(
                  tooltip: 'Logout',
                  iconSize: 42,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Konfirmasi Logout'),
                        content: const Text(
                          'Apakah Anda yakin ingin keluar dari aplikasi?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FirebaseAuth.instance.signOut();

                      if (!context.mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StartSetupPage(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  icon: Image.asset(
                    'assets/image/logout.png',
                    width: 38,
                    height: 38,
                  ),
                ),

                const SizedBox(height: 6),

                const Text("KELUAR DARI AKUN", style: TextStyle(fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget profileRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }
}
