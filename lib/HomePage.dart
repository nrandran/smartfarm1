import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';

import 'NotificationPage.dart';
import 'ProfilPage.dart';
import 'AITipsCard.dart';

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

// STATE HOME PAGE
class _HomePageState extends State<HomePage> {
  late VideoPlayerController _controller;
  late DatabaseReference forecastRef;
  late final StreamSubscription<DatabaseEvent> dataSub;

  String userName = "";
  String userLocation = "";

  StreamSubscription? _historyListener;
  Timer? historyTimer;

  // VARIABEL DATA REALTIME
  double currentSuhu = 0;
  double currentCahaya = 0;
  double currentTanah = 0;
  String currentStatusSuhu = "Menunggu...";
  String currentStatusTanah = "Menunggu...";
  String currentWaktu = "";

  // DATA GRAFIK (HISTORY)
  List<double> suhuList = [];
  List<double> cahayaList = [];
  List<double> tanahList = [];
  List<String> times = [];

  // INIT STATE
  @override
  void initState() {
    super.initState();
    NotificationService().start(widget.userId);

    forecastRef = FirebaseDatabase.instance.ref(
      "SmartFarm/User/${widget.userId}/Forecast",
    );

    _loadUserData();
    _loadHistory();

    // INISIALISASI VIDEO BACKGROUND
    _controller = VideoPlayerController.asset('assets/video/sample.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.setLooping(true);
          _controller.setVolume(0.0);
          _controller.play();
        }
      });

    // LISTENER DATA HISTORY (REALTIME)
    void _startHistoryListener() {
      final dbRef = FirebaseDatabase.instance.ref(
        "SmartFarm/User/${widget.userId}/History",
      );

      _historyListener = dbRef.onValue.listen((event) {
        if (!event.snapshot.exists) return;

        final List<double> tmpSuhu = [];
        final List<double> tmpCahaya = [];
        final List<double> tmpTanah = [];
        final List<String> tmpTimes = [];

        for (var child in event.snapshot.children) {
          final val = Map<String, dynamic>.from(child.value as Map);

          tmpSuhu.add(double.tryParse(val['suhu'].toString()) ?? 0);
          tmpCahaya.add(double.tryParse(val['cahaya'].toString()) ?? 0);
          tmpTanah.add(double.tryParse(val['tanah'].toString()) ?? 0);
          tmpTimes.add(val['waktu'].toString());
        }

        if (mounted) {
          setState(() {
            suhuList = tmpSuhu;
            cahayaList = tmpCahaya;
            tanahList = tmpTanah;
            times = tmpTimes;
          });
        }
      });
    }

    _startHistoryListener();
    _listenDataTerbaru();

    // TIMER PENYIMPANAN OTOMATIS KE HISTORY
    historyTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _saveCurrentDataToHistory();
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        userName =
            prefs.getString("userName") ?? widget.userName ?? "Petani Cerdas";
        userLocation =
            prefs.getString("userLocation") ??
            widget.userLocation ??
            "Lokasi Belum Diatur";
      });
    }
  }

  // LOAD DATA HISTORY (DATABASE)
  Future<void> _loadHistory() async {
    try {
      final ref = FirebaseDatabase.instance
          .ref("SmartFarm/User/${widget.userId}/History")
          .orderByChild('waktu')
          .limitToLast(20);

      final snapshot = await ref.get();

      if (snapshot.exists) {
        final List<double> tmpSuhu = [];
        final List<double> tmpCahaya = [];
        final List<double> tmpTanah = [];
        final List<String> tmpTimes = [];

        for (var child in snapshot.children) {
          final val = Map<String, dynamic>.from(child.value as Map);

          tmpSuhu.add(double.tryParse(val['suhu'].toString()) ?? 0);
          tmpCahaya.add(double.tryParse(val['cahaya'].toString()) ?? 0);
          tmpTanah.add(double.tryParse(val['tanah'].toString()) ?? 0);
          tmpTimes.add(val['waktu'].toString());
        }

        if (mounted) {
          setState(() {
            suhuList = tmpSuhu;
            cahayaList = tmpCahaya;
            tanahList = tmpTanah;
            times = tmpTimes;
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat data history: $e");
    }
  }

  // LISTEN DATA TERBARU (REALTIME DATABASE)
  void _listenDataTerbaru() {
    FirebaseDatabase.instance.ref("SmartFarm/Data_Terbaru").onValue.listen((
      event,
    ) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        setState(() {
          currentSuhu = double.tryParse(data['suhu']?.toString() ?? '0') ?? 0;
          currentCahaya =
              double.tryParse(data['intensitas_cahaya']?.toString() ?? '0') ??
              0;
          currentTanah =
              double.tryParse(
                data['persentase_kelembapan_tanah']?.toString() ?? '0',
              ) ??
              0.0;

          currentStatusSuhu = data['suhu_status'] ?? "-";
          currentStatusTanah = data['kelembapan_tanah_status'] ?? "-";
          currentWaktu = data['waktu'] ?? DateTime.now().toString();

          suhuList.add(currentSuhu);
          cahayaList.add(currentCahaya);
          tanahList.add(currentTanah);
          times.add(currentWaktu);

          if (suhuList.length > 20) {
            suhuList.removeAt(0);
            cahayaList.removeAt(0);
            tanahList.removeAt(0);
            times.removeAt(0);
          }
        });
      }
    });
  }

  // SIMPAN DATA KE HISTORY
  Future<void> _saveCurrentDataToHistory() async {
    if (currentWaktu.isEmpty) return;

    try {
      final historyRef = FirebaseDatabase.instance.ref(
        "SmartFarm/User/${widget.userId}/History",
      );

      await historyRef.push().set({
        "suhu": currentSuhu,
        "cahaya": currentCahaya,
        "tanah": currentTanah,
        "waktu": currentWaktu,
      });
    } catch (e) {
      debugPrint("Gagal menyimpan data history: $e");
    }
  }

  //
  @override
  void dispose() {
    historyTimer?.cancel();
    _controller.dispose();
    _historyListener?.cancel();
    super.dispose();
  }

  // MENGHAPUS SELURUH DATA GRAFIK DAN RIWAYAT
  Future<void> _clearAllCharts() async {
    final ref = FirebaseDatabase.instance.ref(
      "SmartFarm/User/${widget.userId}/History",
    );

    await ref.remove();

    await _historyListener?.cancel();
    _historyListener = null;

    historyTimer?.cancel();
    historyTimer = null;

    if (mounted) {
      setState(() {
        suhuList.clear();
        cahayaList.clear();
        tanahList.clear();
        times.clear();
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Grafik & History berhasil dihapus")),
    );
  }

  // WIDGET GRAFIK  (DIGUNAKAN UNTUK SUHU & KELEMBAPAN TANAH)
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
                      getTitlesWidget: (value, meta) {
                        int index = value.round();
                        if (dataList.isEmpty) return const SizedBox();
                        if (index < 0) index = 0;
                        if (index >= times.length) index = times.length - 1;
                        if (index < 0 || index >= times.length)
                          return const SizedBox();

                        final txt = times[index];
                        if (txt.length < 16) return const SizedBox();

                        return Text(
                          txt.substring(11, 16),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      interval: 1,
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

  // WIDGET GRAFIK  INTENSITAS CAHAYA
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
                maxY: 60000,
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
                      getTitlesWidget: (value, meta) {
                        if (dataList.isEmpty) return const SizedBox();
                        int index = value.round();
                        if (index < 0) index = 0;
                        if (index >= times.length) index = times.length - 1;
                        if (index < 0 || index >= times.length)
                          return const SizedBox();

                        final txt = times[index];
                        if (txt.length < 16) return const SizedBox();

                        return Text(
                          txt.substring(11, 16),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      interval: 1,
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
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3.5,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.orange,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET KARTU PREDIKSI (FORECAST) DATA HARIAN
  Widget buildForecastCard() {
    return StreamBuilder(
      stream: forecastRef.onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              " Prediksi belum tersedia\nMenunggu data mencukupi...",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final data = Map<String, dynamic>.from(
          snapshot.data!.snapshot.value as Map,
        );

        final harian = Map<String, dynamic>.from(data['harian']);
        final day1 = Map<String, dynamic>.from(harian['day_1']);
        final day2 = Map<String, dynamic>.from(harian['day_2']);
        final day3 = Map<String, dynamic>.from(harian['day_3']);
        final day4 = Map<String, dynamic>.from(harian['day_4']);
        final day5 = Map<String, dynamic>.from(harian['day_5']);

        Widget forecastRow(String label, Map day) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Row(
                  children: [
                    Image.asset('assets/image/suhu.png', width: 18, height: 18),
                    Text(
                      " ${day['suhu']}°C",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      'assets/image/tanah.png',
                      width: 18,
                      height: 18,
                    ),
                    Text(
                      " ${day['tanah']}%",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🌱 Ramalan Kondisi Lingkungan 5 Hari",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),

              forecastRow("Hari ini", day1),
              forecastRow("Hari ke 2", day2),
              forecastRow("Hari ke 3", day3),
              forecastRow("Hari ke 4", day4),
              forecastRow("Hari ke 5", day5),

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "📅 ${day1['tanggal']}",
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
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

                  // BUTTON NOTIFIKASI DENGAN INDIKATOR JUMLAH PESAN
                  StreamBuilder(
                    stream: FirebaseDatabase.instance
                        .ref("SmartFarm/User/${widget.userId}/Notifikasi")
                        .onValue,
                    builder: (context, snapshot) {
                      int jumlahNotif = 0;

                      if (snapshot.hasData &&
                          snapshot.data!.snapshot.value != null) {
                        final data = snapshot.data!.snapshot.value as Map;
                        jumlahNotif = data.length; // HITUNG SEMUA NOTIFIKASI
                      }

                      return Stack(
                        children: [
                          IconButton(
                            tooltip: 'Lihat Notifikasi',
                            iconSize: 28,
                            icon: Image.asset(
                              'assets/image/notif.png',
                              width: 35,
                              height: 35,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      NotificationPage(userId: widget.userId),
                                ),
                              );
                            },
                          ),

                          if (jumlahNotif > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  jumlahNotif > 9
                                      ? "9+"
                                      : jumlahNotif.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(width: 1),

                  // TOMBOL MENUJU HALAMAN PROFIL PENGGUNA
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

            // BAGIAN KONTEN UTAMA (SCROLLABLE)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    // BAGIAN TIPS
                    const SectionTitle(title: 'Tips'),
                    const SizedBox(height: 10),
                    const AITipsCard(),
                    const SizedBox(height: 10),

                    // BAGIAN PREDIKSI
                    const SectionTitle(title: 'Prediksi'),
                    buildForecastCard(),
                    const SizedBox(height: 5),

                    // BAGIAN MONITORING KONDISI LINGKUNGAN

                    //  MONITORING SUHU UDARA
                    const Center(child: SectionTitle(title: 'Suhu Udara')),
                    const SizedBox(height: 5),

                    // PENGECEKAN STATUS SENSOR SUHU (AKTIF / NONAKTIF)
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

                                // VISUALISASI DATA SUHU DALAM BENTUK GRAFIK
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

                                //PARAMETER
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

                    // SUBBAGIAN MONITORING KELEMBAPAN TANAH
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SectionTitle(title: 'Kelembaban Tanah'),
                          const SizedBox(height: 10),

                          // PENGECEKAN SENSOR KELEMBAPAN TANAH (AKTIF / NONAKTIF)
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

                                      Text(
                                        "Status: $tanahStatus",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),

                                      const SizedBox(height: 20),

                                      // GRAFIK KELEMBAPAN TANAH
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

                    //  MONITORING INTENSITAS CAHAYA
                    const Center(
                      child: SectionTitle(title: 'Intensitas Cahaya'),
                    ),
                    const SizedBox(height: 10),

                    // PENGECEKAN STATUS SENSOR CAHAYA (AKTIF / NONAKTIF)
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

                                // GRAFIK INTENSITAS CAHAYA
                                Column(
                                  children: [
                                    buildCahayaChart(
                                      "Intensitas Cahaya (lux)",
                                      cahayaList,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: const [
                                      WeatherCard(
                                        label: '<5000 Lux',
                                        description: 'Redup',
                                      ),
                                      WeatherCard(
                                        label: '10000–50000 Lux',
                                        description: 'Normal',
                                      ),
                                      WeatherCard(
                                        label: '>50000 Lux',
                                        description: 'Terang',
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 32),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ),
                                  ),
                                  onPressed: _clearAllCharts,
                                  child: const Text(
                                    "Hapus Grafik & Data History",
                                  ),
                                ),
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
                fontSize: 12,
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
