import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:video_player/video_player.dart';
import 'NotificationPage.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatefulWidget {
  final String? userName; // 👈 bisa null kalau tidak dikirim

  const HomePage({super.key, this.userName});

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
    // Video
    _controller = VideoPlayerController.asset('assets/video/sample.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.setVolume(0.5);
        _controller.play();
      });

    // Ambil data lahan dari Firebase
    _dbRef.child("lahan").onValue.listen((event) {
      if (event.snapshot.value != null) {
        final raw = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          lahanData = raw.values
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      } else {
        setState(() {
          lahanData = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference iotRef = _dbRef.child("iot_data");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
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
                    IconButton(
                      icon: Image.asset(
                        'assets/image/notif.jpg',
                        width: 28,
                        height: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Video
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

              // Sapaan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Halo, ${widget.userName ?? "Pak"} ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tips
              const SectionTitle(title: 'Tips'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  color: Color(0xFFE8F5E9),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Jangan terlalu banyak air karena cuaca sekarang sering hujan.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ),

              // Suhu Tanah (Realtime dari Firebase)
              const SectionTitle(title: 'Suhu Udara'),
              StreamBuilder(
                stream: iotRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    final data = snapshot.data!.snapshot.value as Map;
                    final suhu = data['suhu_tanah'] ?? 0;
                    final keterangan = data['keterangan'] ?? "-";

                    return Center(
                      child: Column(
                        children: [
                          Text(
                            "$suhu°",
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            keterangan,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Image.asset('assets/image/cuaca.png', width: 100),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(child: Text("Error ambil data"));
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),

              const SizedBox(height: 24),

              // Weather Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    WeatherCard(label: '<20°C', description: 'Dingin'),
                    WeatherCard(label: '25-30°C', description: 'Normal'),
                    WeatherCard(label: '>35°C', description: 'Panas'),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              //Kelembapan tanah
              const SectionTitle(title: 'Kelembapan Tanah'),
              StreamBuilder(
                stream: iotRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    final data = snapshot.data!.snapshot.value as Map;
                    final suhu = data['kelembapan_tanah'] ?? 0;
                    final keterangan = data['keterangan'] ?? "-";

                    return Center(
                      child: Column(
                        children: [
                          Text(
                            "$suhu°",
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            keterangan,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Image.asset('assets/image/cuaca.png', width: 100),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(child: Text("Error ambil data"));
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),

              const SizedBox(height: 24),

              // Weather Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    WeatherCard(label: '30% VWC', description: 'Kering'),
                    WeatherCard(label: '30% – 60% VWC', description: 'Normal'),
                    WeatherCard(label: '60% – 80% VWC', description: 'Basah'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              //intensitas cahaya
              const SectionTitle(title: 'Intensitas Cahaya'),
              StreamBuilder(
                stream: iotRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    final data = snapshot.data!.snapshot.value as Map;
                    final suhu = data['kelembapan_tanah'] ?? 0;
                    final keterangan = data['keterangan'] ?? "-";

                    return Center(
                      child: Column(
                        children: [
                          Text(
                            "$suhu°",
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            keterangan,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(child: Text("Error ambil data"));
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),

              const SizedBox(height: 32),

              // Grafik Hama
              const SectionTitle(title: 'Serangan Hama'),
              const PestChart(),

              const SizedBox(height: 16),
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

              const SizedBox(height: 32),

              // Data Lahan
              const SectionTitle(title: 'Lahan Sawah Anda'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: lahanData.isEmpty
                      ? [const Text("Belum ada data lahan")]
                      : lahanData.map((field) {
                          return FieldCard(
                            name: field['name'] ?? "-",
                            area: field['area'] ?? "-",
                            status: field['status'] ?? "-",
                            lokasi: field['lokasi'] ?? "-",
                          );
                        }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Aksi
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final newRef = _dbRef.child("lahan").push();
                      newRef.set({
                        "name": "Baru",
                        "area": "1000 m²",
                        "status": "Bagus",
                        "lokasi": "Belum diisi",
                      });
                    },
                    label: const Text('Tambah Lahan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= Komponen ===================

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

class FieldCard extends StatelessWidget {
  final String name;
  final String area;
  final String status;
  final String lokasi;

  const FieldCard({
    required this.name,
    required this.area,
    required this.status,
    required this.lokasi,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$area\nLokasi: $lokasi"),
        isThreeLine: true,
        trailing: Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: status.toLowerCase().contains('kurang')
                ? Colors.red
                : Colors.green,
          ),
        ),
      ),
    );
  }
}

// ================= Grafik ===================

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
        boxShadow: [
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
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
