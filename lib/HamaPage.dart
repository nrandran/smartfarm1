import 'package:app_smart_farm/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:video_player/video_player.dart';
import 'NotificationPage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // ✅ Import intl
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'GrafikSensorPage.dart';

class Hamapage extends StatefulWidget {
  final String? userName;
  final String? userLocation;
  const Hamapage({super.key, this.userName, this.userLocation});

  @override
  State<Hamapage> createState() => _HamapageState();
}

class _HamapageState extends State<Hamapage> {
  late VideoPlayerController _controller;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("SmartFarm");
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();

    // 🎬 Inisialisasi video
    _controller = VideoPlayerController.asset('assets/video/sample.mp4')
      ..initialize().then((_) {
        // Pastikan widget masih aktif sebelum setState (menghindari crash)
        if (mounted) {
          setState(() {});
          _controller
            ..setLooping(true)
            ..setVolume(0.5)
            ..play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ✅ Simpan data suhu & kelembapan hanya 1x per jam
  Future<void> _simpanDataPerJam(Map<String, dynamic> data) async {
    final suhu = data['suhu'];
    final kelembaban = data['kelembaban_udara'];

    // ✅ Pastikan data valid
    if (suhu == null || kelembaban == null) return;

    final now = DateTime.now();
    final jamKey = DateFormat('yyyy-MM-dd-HH:00').format(now);

    // ✅ Rujukan lokasi penyimpanan per user & per jam
    final ref = FirebaseDatabase.instance.ref(
      "SmartFarm/User/$userId/Riwayat_Suhu/$jamKey",
    );

    // ✅ Cegah duplikasi penyimpanan dalam jam yang sama
    final snapshot = await ref.get();
    if (snapshot.exists) {
      // Sudah ada data jam ini → tidak disimpan ulang
      return;
    }

    // ✅ Simpan sekali untuk jam ini
    await ref.set({
      'suhu': suhu,
      'kelembaban': kelembaban,
      'timestamp': now.toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference iotRef = _dbRef.child("/SmartFarm/Data_Terbaru");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // ================= Header =================
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Image.asset('assets/image/logo.png', height: 40),
                  const SizedBox(width: 10),
                  const Text(
                    'SMART FARM',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),

                  // 🔔 Tombol Notifikasi
                  IconButton(
                    tooltip: 'Lihat Notifikasi',
                    iconSize: 28,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationPage(),
                        ),
                      );
                    },
                    icon: const CircleAvatar(
                      backgroundImage: AssetImage('assets/image/notif.jpg'),
                      backgroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 1),

                  // 🚪 Tombol Logout
                  IconButton(
                    tooltip: 'Keluar dari akun',
                    iconSize: 32,
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
                        try {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StartSetupPage(),
                              ),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal logout: $e')),
                            );
                          }
                        }
                      }
                    },
                    icon: Image.asset(
                      'assets/image/logout.png',
                      width: 28,
                      height: 28,
                    ),
                  ),
                ],
              ),
            ),
            // ================= Konten Scrollable =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= Video =================
                    if (_controller.value.isInitialized)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ================= Sapaan + Lokasi =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${widget.userName ?? ""}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/image/lokasi.jpg',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.userLocation ?? "Yogyakarta",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    // ================= button Tambahan =================
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const HomePage(), // ← Pastikan nama class benar
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey, // 🔥 Warna hijau
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4, // Shadow lembut
                              ),
                              child: const Text(
                                'Sensor Lahan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.green, // 🔥 Warna abu-abu
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'Sensor Hama',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ================= Tips Tambahan =================
                    const SectionTitle(title: 'Tips'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 2,
                        color: Color(0xFFFFF3E0),
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Lakukan penyemprotan pestisida secara rutin pada tanaman.',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                    ),

                    // ================= Grafik Serangan Hama =================
                    const Center(child: SectionTitle(title: 'Serangan Hama')),
                    const SizedBox(height: 1),
                    const PestChart(),

                    const SizedBox(height: 32),
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

// ================= Komponen Reusable ===================

class WeatherCard extends StatelessWidget {
  final String label;
  final String description;

  const WeatherCard({
    required this.label,
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(description),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }
}

// ================= Grafik Serangan Hama ===================

class PestChart extends StatelessWidget {
  const PestChart({super.key});

  @override
  Widget build(BuildContext context) {
    final data = [22, 45, 17, 38, 28, 33, 41];
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 60,
          barGroups: List.generate(data.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data[index].toDouble(),
                  color: Colors.green,
                  width: 14,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      days[value.toInt()],
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
