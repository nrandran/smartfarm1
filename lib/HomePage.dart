import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:video_player/video_player.dart';
import 'NotificationPage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // ✅ Import intl
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'HamaPage.dart';
import 'GrafikSensorPage.dart';

class HomePage extends StatefulWidget {
  final String? userName;
  final String? userLocation;
  const HomePage({super.key, this.userName, this.userLocation});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'Sensor Lahan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: Container(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Hamapage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
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
                                  fontSize: 10,
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
                        color: Colors.green,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Lakukan penyiraman secara rutin pada tanaman karna tanah ke keringan.',
                            style: TextStyle(
                              color: Color.fromARGB(221, 255, 255, 255),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ================= Suhu  =================
                    const Center(child: SectionTitle(title: 'Suhu Udara')),
                    const SizedBox(height: 1),
                    // ================= Grafik Suhu per Jam =================
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Text(
                          "Grafik Suhu per Jam",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 29, 29, 29),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    StreamBuilder(
                      stream: FirebaseDatabase.instance
                          .ref("SmartFarm/User/$userId/Riwayat_Suhu")
                          .onValue,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData ||
                            snapshot.data!.snapshot.value == null) {
                          return const Center(
                            child: Text("Belum ada data riwayat"),
                          );
                        }

                        final data = Map<String, dynamic>.from(
                          snapshot.data!.snapshot.value as Map,
                        );

                        final entries = data.entries.toList()
                          ..sort((a, b) => a.key.compareTo(b.key));

                        final suhuPoints = entries.map((e) {
                          final value = Map<String, dynamic>.from(e.value);
                          return FlSpot(
                            entries.indexOf(e).toDouble(),
                            double.tryParse(value['suhu'].toString()) ?? 0,
                          );
                        }).toList();

                        final labels = entries
                            .map((e) => e.key.split('-').last)
                            .toList();

                        return SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              borderData: FlBorderData(show: true),
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= labels.length) {
                                        return const Text('');
                                      }
                                      return Text(
                                        labels[index].replaceAll(':00', ''),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  spots: suhuPoints,
                                  barWidth: 3,
                                  color: Colors.green,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.green.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 5),

                    StreamBuilder(
                      stream: FirebaseDatabase.instance
                          .ref("SmartFarm/Data_Terbaru")
                          .onValue,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData ||
                            snapshot.data!.snapshot.value == null) {
                          return const Center(
                            child: Text(
                              "Belum ada data dari Firebase",
                              style: TextStyle(color: Colors.red, fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        final data = Map<String, dynamic>.from(
                          snapshot.data!.snapshot.value as Map,
                        );

                        final suhu =
                            double.tryParse(data['suhu'].toString()) ?? 0;
                        final kelembaban =
                            double.tryParse(
                              data['kelembaban_udara'].toString(),
                            ) ??
                            0;

                        // ✅ Simpan data ke riwayat per jam
                        _simpanDataPerJam(data);

                        return Column(
                          children: [
                            Center(
                              child: Text(
                                "$suhu °C",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                "Kelembapan Udara: $kelembaban %",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 5),
                    // ================= Parameter Suhu =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          WeatherCard(label: '<40 °C', description: 'Panas'),
                          WeatherCard(label: '20-40 °C', description: 'Normal'),
                          WeatherCard(label: '>20 °C', description: 'Dingin'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ================= Kelembapan Tanah =================
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SectionTitle(title: 'Kelembapan Tanah'),
                          const SizedBox(height: 10),
                          StreamBuilder(
                            stream: FirebaseDatabase.instance
                                .ref("SmartFarm/Data_Terbaru")
                                .onValue,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData ||
                                  snapshot.data!.snapshot.value == null) {
                                return const Text(
                                  "Belum ada data dari Firebase",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              }

                              final data = Map<String, dynamic>.from(
                                snapshot.data!.snapshot.value as Map,
                              );

                              final tanah =
                                  data['kelembaban_tanah']?.toString() ?? "0";
                              return Text(
                                "$tanah %",
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                    // ================= Parameter Kelembapan =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          WeatherCard(label: '<30% VWC', description: 'Kering'),
                          WeatherCard(
                            label: '30–60% VWC',
                            description: 'Normal',
                          ),
                          WeatherCard(label: '>60% VWC', description: 'Basah'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ================= Intensitas Cahaya =================
                    const Center(
                      child: SectionTitle(title: 'Intensitas Cahaya'),
                    ),

                    StreamBuilder(
                      stream: FirebaseDatabase.instance
                          .ref("SmartFarm/Data_Terbaru")
                          .onValue,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.snapshot.value == null) {
                          return const Center(
                            child: Text(
                              "Belum ada data dari Firebase",
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        final data = Map<String, dynamic>.from(
                          snapshot.data!.snapshot.value as Map,
                        );

                        final cahaya =
                            data['intensitas_cahaya']?.toString() ?? "0";
                        final keteranganCahaya =
                            data['keterangan_cahaya']?.toString() ?? "Terang";

                        return Column(
                          children: [
                            const SizedBox(height: 20),

                            Center(
                              child: Text(
                                "$cahaya Lux",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Center(
                              child: Text(
                                keteranganCahaya,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 5),

                    // ================= Parameter Cahaya =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          WeatherCard(label: '<1000 Lux', description: 'Redup'),
                          WeatherCard(
                            label: '1000–5000 Lux',
                            description: 'Normal',
                          ),
                          WeatherCard(
                            label: '>5000 Lux',
                            description: 'Terang',
                          ),
                        ],
                      ),
                    ),
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
