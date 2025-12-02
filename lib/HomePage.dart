import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'DeviceControlPage.dart';
import 'NotificationPage.dart';
import 'ProfilPage.dart';
import 'AITipsCard.dart';
import 'data_logger_service.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? userLocation;

  const HomePage({
    super.key,
    required this.userId,
    this.userName,
    this.userLocation,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late VideoPlayerController _controller;

  String userName = "";
  String userLocation = "";

  Timer? historyTimer;

  List<double> suhuList = [];
  List<double> cahayaList = [];
  List<double> tanahList = [];
  List<String> times = [];

  @override
  void initState() {
    super.initState();

    loadUserData();
    loadHistory();

    // ================== TIMER SIMPAN RIWAYAT SETIAP 60 DETIK ==================
    historyTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      saveUserSensorHistory();
      await loadHistory();
    });

    // ================== INISIALISASI VIDEO ==================
    _controller = VideoPlayerController.asset('assets/video/sample.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller
            ..setLooping(true)
            ..setVolume(0.0)
            ..play();
        }
      });

    // ================== LISTEN DATA SENSOR TERBARU ==================
    listenDataTerbaru();
  }

  // ================== BAGIAN: LOAD USER DATA ==================
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString("userName") ?? widget.userName ?? "";
      userLocation =
          prefs.getString("userLocation") ?? widget.userLocation ?? "";
    });
  }

  // ================== BAGIAN: LISTEN DATA SENSOR REALTIME ==================
  void listenDataTerbaru() {
    FirebaseDatabase.instance.ref("SmartFarm/Data_Terbaru").onValue.listen((
      event,
    ) {
      if (event.snapshot.value == null) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      final suhu = double.tryParse(data['suhu'].toString()) ?? 0;
      final cahaya = double.tryParse(data['intensitas_cahaya'].toString()) ?? 0;
      final tanah =
          double.tryParse(data['persentase_kelembapan_tanah'].toString()) ?? 0;
      final waktu = data['waktu']?.toString() ?? "";

      setState(() {
        suhuList.add(suhu);
        cahayaList.add(cahaya);
        tanahList.add(tanah);
        times.add(waktu);

        // Batasi maksimal 20 data
        if (suhuList.length > 20) {
          suhuList.removeAt(0);
          cahayaList.removeAt(0);
          tanahList.removeAt(0);
          times.removeAt(0);
        }
      });
    });
  }

  // ================== BAGIAN: LOAD DATA RIWAYAT ==================
  Future<void> loadHistory() async {
    final ref = FirebaseDatabase.instance.ref(
      "SmartFarm/User/${widget.userId}/History",
    );

    final snapshot = await ref.limitToLast(20).get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    suhuList.clear();
    cahayaList.clear();
    tanahList.clear();
    times.clear();

    data.forEach((key, value) {
      final item = Map<String, dynamic>.from(value);

      suhuList.add(double.tryParse(item['suhu'].toString()) ?? 0);
      cahayaList.add(double.tryParse(item['cahaya'].toString()) ?? 0);
      tanahList.add(double.tryParse(item['tanah'].toString()) ?? 0);
      times.add(item['waktu']?.toString() ?? "");
    });

    setState(() {});
  }

  // ================== BAGIAN: SIMPAN RIWAYAT SENSOR ==================
  void saveUserSensorHistory() {
    DataLoggerService.saveUserSensor(widget.userId, null);
  }

  // ================== BAGIAN: BAGIAN PEMBUAT GRAFIK ==================
  Widget buildChart(String title, List<double> dataList, Color lineColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) =>
                          buildTimeTitle(value.toInt()),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      dataList.length,
                      (i) => FlSpot(i.toDouble(), dataList[i]),
                    ),
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== BAGIAN: GRAFIK INTENSITAS CAHAYA (0–10000) ==================
  Widget buildCahayaChart(String title, List<double> dataList) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 10000,

                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 5000,
                      color: Colors.grey,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => "5000",
                        alignment: Alignment.centerRight,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                gridData: FlGridData(show: true),

                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) =>
                          buildTimeTitle(value.toInt()),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 5000 || value == 10000) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),

                borderData: FlBorderData(show: false),

                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      dataList.length,
                      (i) => FlSpot(i.toDouble(), dataList[i]),
                    ),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== BAGIAN: FORMAT TEKS WAKTU ==================
  Widget buildTimeTitle(int index) {
    if (index < 0 || index >= times.length) return const SizedBox();
    if (times[index].length < 16) return const SizedBox();
    return Text(
      times[index].substring(11, 16),
      style: const TextStyle(fontSize: 10),
    );
  }

  // ================== BAGIAN: HAPUS RIWAYAT ==================
  Future<void> clearSuhuHistory() async {
    try {
      await FirebaseDatabase.instance
          .ref("SmartFarm/User/${widget.userId}/History")
          .remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Riwayat grafik berhasil dihapus")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menghapus: $e")));
    }
  }

  @override
  void dispose() {
    historyTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          builder: (context) =>
                              NotificationPage(userId: widget.userId),
                        ),
                      );
                    },
                    icon: const CircleAvatar(
                      backgroundImage: AssetImage('assets/image/notif.png'),
                      backgroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 1),

                  // 🔄 Tombol ke Halaman Profil
                  IconButton(
                    tooltip: 'Lihat Profil',
                    iconSize: 32,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilPage(
                            userId: widget.userId,
                            userName: widget.userName,
                            userLocation: widget.userLocation,
                          ),
                        ),
                      );
                    },
                    icon: Image.asset(
                      'assets/image/user.png',
                      width: 45,
                      height: 45,
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
                                'Halo, $userName',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          // Lokasi container
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
                                  'assets/image/lokasi.png',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  userLocation,
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

                    // ================= Tips Tambahan =================
                    const SectionTitle(title: 'Tips'),
                    const SizedBox(height: 10),
                    const AITipsCard(),
                    const SizedBox(height: 10),

                    // ================= Suhu =================
                    const Center(child: SectionTitle(title: 'Suhu Udara')),
                    const SizedBox(height: 5),

                    // ====== Cek apakah sensor ON atau OFF ======
                    StreamBuilder(
                      stream: FirebaseDatabase.instance
                          .ref(
                            "SmartFarm/User/${widget.userId}/Sensor_Control/suhu_on",
                          )
                          .onValue,
                      builder: (context, controlSnap) {
                        if (!controlSnap.hasData) {
                          return const SizedBox();
                        }

                        final sensorOn =
                            controlSnap.data!.snapshot.value ?? true;

                        // Jika sensor dimatikan → tampilkan pesan, sembunyikan data
                        if (sensorOn == false) {
                          return const Center(
                            child: Text(
                              "Sensor Suhu Dimatikan",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        // ====== Sensor HIDUP → Ambil Data Terbaru ======
                        return StreamBuilder(
                          stream: FirebaseDatabase.instance
                              .ref("SmartFarm/Data_Terbaru")
                              .onValue,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.data!.snapshot.value == null) {
                              return const Center(
                                child: Text(
                                  "Tidak Ada Data",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                  ),
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
                                  data['kelembapan_udara'].toString(),
                                ) ??
                                0;
                            final suhu_status =
                                data['suhu_status']?.toString() ??
                                "Tidak ada data";

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
                                const SizedBox(height: 10),
                                Center(
                                  child: Text(
                                    "Status: $suhu_status",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ====== GRAFIK SUHU (muncul hanya jika sensor ON) ======
                                Column(
                                  children: [
                                    buildChart(
                                      "Suhu (°C)",
                                      suhuList,
                                      Colors.red,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // ====== Parameter suhu ======
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: const [
                                      WeatherCard(
                                        label: '<20 °C',
                                        description: 'Dingin',
                                      ),
                                      WeatherCard(
                                        label: '20-40 °C',
                                        description: 'Normal',
                                      ),
                                      WeatherCard(
                                        label: '>35 °C',
                                        description: 'Panas',
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 30),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    // ================= Kelembapan Tanah =================
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SectionTitle(title: 'Kelembaban Tanah'),
                          const SizedBox(height: 10),

                          // ====== StreamBuilder Kontrol Sensor ======
                          StreamBuilder(
                            stream: FirebaseDatabase.instance
                                .ref(
                                  "SmartFarm/User/${widget.userId}/Sensor_Control/tanah_on",
                                )
                                .onValue,
                            builder: (context, controlSnap) {
                              if (!controlSnap.hasData) return const SizedBox();

                              final sensorOn =
                                  controlSnap.data!.snapshot.value ?? true;

                              // Jika sensor OFF → matikan tampilan data + grafik
                              if (sensorOn == false) {
                                return const Text(
                                  "Sensor tanah Dimatikan",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              }

                              // ====== Sensor ON → Ambil Data Terbaru ======
                              return StreamBuilder(
                                stream: FirebaseDatabase.instance
                                    .ref("SmartFarm/Data_Terbaru")
                                    .onValue,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      snapshot.data!.snapshot.value == null) {
                                    return const Text(
                                      "Tidak Ada Data",
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
                                      double.tryParse(
                                        data['persentase_kelembapan_tanah']
                                            .toString(),
                                      ) ??
                                      0.0;

                                  final tanahStatus =
                                      data['kelembapan_tanah_status']
                                          ?.toString() ??
                                      "Tidak ada data";

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Persentase nilai
                                      Text(
                                        "$tanah %",
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),

                                      const SizedBox(height: 10),

                                      // Status
                                      Text(
                                        "Status: $tanahStatus",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),

                                      const SizedBox(height: 20),

                                      // ================= Grafik Kelembapan Tanah =================
                                      Column(
                                        children: [
                                          buildChart(
                                            "Kelembapan Tanah (%)",
                                            tanahList,
                                            Colors.blue,
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      // ================= Parameter Kelembapan =================
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: const [
                                            WeatherCard(
                                              label: '<30% VWC',
                                              description: 'Kering',
                                            ),
                                            WeatherCard(
                                              label: '30–60% VWC',
                                              description: 'Normal',
                                            ),
                                            WeatherCard(
                                              label: '>60% VWC',
                                              description: 'Basah',
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 30),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // ================= Intensitas Cahaya =================
                    const Center(
                      child: SectionTitle(title: 'Intensitas Cahaya'),
                    ),
                    const SizedBox(height: 10),

                    // ===== StreamBuilder Kontrol Sensor Cahaya =====
                    StreamBuilder(
                      stream: FirebaseDatabase.instance
                          .ref(
                            "SmartFarm/User/${widget.userId}/Sensor_Control/cahaya_on",
                          )
                          .onValue,
                      builder: (context, controlSnap) {
                        if (!controlSnap.hasData) return const SizedBox();

                        final sensorOn =
                            controlSnap.data!.snapshot.value ?? true;

                        // Sensor OFF → matikan data + grafik
                        if (sensorOn == false) {
                          return const Center(
                            child: Text(
                              "Sensor Cahaya Dimatikan",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        // ===== Sensor ON → Ambil data intensitas cahaya =====
                        return StreamBuilder(
                          stream: FirebaseDatabase.instance
                              .ref("SmartFarm/Data_Terbaru")
                              .onValue,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.data!.snapshot.value == null) {
                              return const Center(
                                child: Text(
                                  "Tidak Ada Data",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            final data = Map<String, dynamic>.from(
                              snapshot.data!.snapshot.value as Map,
                            );

                            final cahaya =
                                double.tryParse(
                                  data['intensitas_cahaya'].toString(),
                                ) ??
                                0.0;

                            final cahayaStatus =
                                data['intensitas_cahaya_status']?.toString() ??
                                "Tidak ada data";

                            return Column(
                              children: [
                                const SizedBox(height: 20),

                                // Nilai angka Lux
                                Center(
                                  child: Text(
                                    "${cahaya.toStringAsFixed(0)} Lux",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                // Status cahaya
                                Center(
                                  child: Text(
                                    "Status: $cahayaStatus",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ===== Grafik Intensitas Cahaya =====
                                Column(
                                  children: [
                                    buildCahayaChart(
                                      "Intensitas Cahaya (lux)",
                                      cahayaList,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // ===== Parameter Cahaya =====
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: const [
                                      WeatherCard(
                                        label: '<1000 Lux',
                                        description: 'Redup',
                                      ),
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
                            );
                          },
                        );
                      },
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
