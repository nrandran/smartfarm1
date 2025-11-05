import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:video_player/video_player.dart';
import 'NotificationPage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // ✅ Import intl
import 'package:firebase_auth/firebase_auth.dart';
import 'Pageawal.dart';

class HomePage extends StatefulWidget {
  final String? userName;
  final String? userLocation;

  const HomePage({super.key, this.userName, this.userLocation});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late VideoPlayerController _controller;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> lahanData = [];

  @override
  void initState() {
    super.initState();

    // 🎬 Inisialisasi video
    _controller = VideoPlayerController.asset('assets/video/sample.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller
          ..setLooping(true)
          ..setVolume(0.5)
          ..play();
      });
  }

  /// ✅ Fungsi menyimpan data suhu & kelembapan per jam
  Future<void> _simpanDataPerJam(Map<String, dynamic> data) async {
    final suhu = data['suhu'];
    final kelembaban = data['kelembaban_udara'];
    if (suhu == null || kelembaban == null) return;

    final now = DateTime.now();
    final jamKey = DateFormat('yyyy-MM-dd-HH:00').format(now);

    final ref = FirebaseDatabase.instance.ref("SmartFarm/Riwayat_Suhu/$jamKey");

    // ✅ Cegah duplikasi (1x per jam)
    final exists = (await ref.get()).exists;
    if (!exists) {
      await ref.set({
        'suhu': suhu,
        'kelembaban': kelembaban,
        'timestamp': now.toIso8601String(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference iotRef = _dbRef.child("SmartFarm/Data_Terbaru");

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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),

                  // 🔔 Tombol Notifikasi
                  IconButton(
                    tooltip: 'Lihat Notifikasi',
                    iconSize: 36,
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

                  const SizedBox(width: 8),

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
                                builder: (context) => const PageAwal(),
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
                    // ================= Suhu & Kelembapan =================
                    const Center(child: SectionTitle(title: 'Suhu Udara')),
                    const SizedBox(height: 10),

                    StreamBuilder(
                      stream: iotRef.onValue,
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

                    const SizedBox(height: 10),

                    // ================= Grafik Suhu per Jam =================
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Text(
                          "Grafik Suhu per Jam",
                          style: TextStyle(
                            fontSize: 20,
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
                          .ref("SmartFarm/Riwayat_Suhu")
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

                    // ================= parameter Suhu =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          WeatherCard(label: '<20°C', description: 'Dingin'),
                          WeatherCard(label: '25–30°C', description: 'Normal'),
                          WeatherCard(label: '>35°C', description: 'Panas'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ================= Kelembapan Tanah =================
                    const Center(
                      child: SectionTitle(title: 'Kelembapan Tanah'),
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

                        final kelembapanTanah =
                            data['kelembapan_tanah']?.toString() ?? "0";
                        final keteranganKelembapan =
                            data['keterangan_tanah']?.toString() ?? "Stabil";

                        return Column(
                          children: [
                            const SizedBox(height: 20),

                            Center(
                              child: Text(
                                "$kelembapanTanah %",
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
                                keteranganKelembapan,
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

                    const SizedBox(height: 32),

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
                    const SectionTitle(title: 'Serangan Hama'),
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
          fontSize: 20,
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
