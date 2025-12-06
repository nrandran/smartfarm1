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
  StreamSubscription? _historyListener;
  Timer? historyTimer;

  // Variabel Data Realtime
  double currentSuhu = 0;
  double currentCahaya = 0;
  double currentTanah = 0;
  String currentStatusSuhu = "Menunggu...";
  String currentStatusTanah = "Menunggu...";
  String currentWaktu = "";

  // List untuk Grafik (History)
  List<double> suhuList = [];
  List<double> cahayaList = [];
  List<double> tanahList = [];
  List<String> times = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadHistory();

    // 1. Inisialisasi Video Background
    _controller = VideoPlayerController.asset('assets/video/sample.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.setLooping(true);
          _controller.setVolume(0.0);
          _controller.play();
        }
      });

    // 2. LOAD HISTORY PERTAMA KALI (Agar grafik langsung muncul)

    // LISTENER REALTIME UNTUK HISTORY
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
    // 3. LISTEN DATA REALTIME (Update angka besar & grafik live)
    _listenDataTerbaru();

    // 4. AUTO SAVE TIMER (Simpan ke history setiap 100 detik)
    historyTimer = Timer.periodic(const Duration(seconds: 100), (_) {
      _saveCurrentDataToHistory();
    });
  }

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

  // --- FUNGSI 1: LOAD HISTORY (DARI SmartFarm/User/...) ---
  Future<void> _loadHistory() async {
    try {
      // PERBAIKAN PATH DI SINI
      final ref = FirebaseDatabase.instance
          .ref("SmartFarm/User/${widget.userId}/History")
          .orderByChild('waktu')
          .limitToLast(20); // Ambil 20 data terakhir

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
      debugPrint("Gagal load history: $e");
    }
  }

  // --- FUNGSI 2: LISTEN REALTIME (DARI SmartFarm/Data_Terbaru) ---
  void _listenDataTerbaru() {
    FirebaseDatabase.instance.ref("SmartFarm/Data_Terbaru").onValue.listen((
      event,
    ) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        setState(() {
          // Ambil Data
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

          // Update Grafik Realtime (tambah data baru ke ujung kanan)
          suhuList.add(currentSuhu);
          cahayaList.add(currentCahaya);
          tanahList.add(currentTanah);
          times.add(currentWaktu);

          // Batasi tampilan grafik maks 20 titik agar tidak menumpuk
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

  // --- FUNGSI 3: SIMPAN KE HISTORY (KE SmartFarm/User/...) ---
  Future<void> _saveCurrentDataToHistory() async {
    if (currentWaktu.isEmpty) return;

    try {
      // PERBAIKAN PATH DI SINI JUGA
      final historyRef = FirebaseDatabase.instance.ref(
        "SmartFarm/User/${widget.userId}/History",
      );

      // Push data baru dengan unique ID otomatis
      await historyRef.push().set({
        "suhu": currentSuhu,
        "cahaya": currentCahaya,
        "tanah": currentTanah,
        "waktu": currentWaktu,
      });
      // print("Data history tersimpan");
    } catch (e) {
      debugPrint("Error save history: $e");
    }
  }

  @override
  void dispose() {
    // Matikan timer penyimpan history
    historyTimer?.cancel();

    // Stop video
    _controller.dispose();

    // Hentikan listener Firebase
    _historyListener?.cancel();

    super.dispose();
  }

  Future<void> _clearAllCharts() async {
    // 1. Hapus data History di Firebase
    final ref = FirebaseDatabase.instance.ref(
      "SmartFarm/User/${widget.userId}/History",
    );

    await ref.remove();

    // 2. Hentikan listener history
    await _historyListener?.cancel();
    _historyListener = null;

    // 3. Hentikan autosave timer (agar tidak menambah data lagi)
    historyTimer?.cancel();
    historyTimer = null;

    // 4. Kosongkan grafik di UI
    if (mounted) {
      setState(() {
        suhuList.clear();
        cahayaList.clear();
        tanahList.clear();
        times.clear();
      });
    }

    // 5. (opsional) Tampilkan snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Grafik & History berhasil dihapus")),
    );
  }

  // Widget untuk grafik
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
                        // clamp index ke rentang valid
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
                    // Tampilkan titik pada setiap data point (sama seperti buildChart)
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3.5, // ukuran titik
                          color: Colors.white, // warna isi titik
                          strokeWidth: 2,
                          strokeColor: Colors
                              .orange, // outline agar terlihat di background
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

                  // 🔔 Tombol Notifikasi dengan Badge
                  StreamBuilder(
                    stream: FirebaseDatabase.instance
                        .ref("SmartFarm/User/${widget.userId}/Notifikasi")
                        .onValue,
                    builder: (context, snapshot) {
                      int jumlahNotif = 0;

                      if (snapshot.hasData &&
                          snapshot.data!.snapshot.value != null) {
                        final data = snapshot.data!.snapshot.value as Map;
                        jumlahNotif = data.length;
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

                          // 🔴 Badge merah kecil
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
