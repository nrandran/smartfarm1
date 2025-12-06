import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'Homepage.dart';

class NotificationPage extends StatefulWidget {
  final String userId; // <<<<<<<<<< TAMBAHKAN USER ID

  const NotificationPage({super.key, required this.userId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String? lastJudul;
  String? lastPesan;
  late final DatabaseReference dataTerbaruRef;
  late final DatabaseReference notifikasiRef;

  double? suhu;
  double? kelembapanUdara;
  double? tanah;
  double? cahaya;

  int cooldownMs = 60000; // 1 menit
  int? lastSentTime;

  @override
  void initState() {
    super.initState();

    // Path: SmartFarm/Data_Terbaru
    dataTerbaruRef = FirebaseDatabase.instance.ref("SmartFarm/Data_Terbaru");

    // Path notifikasi per user
    notifikasiRef = FirebaseDatabase.instance.ref(
      "SmartFarm/User/${widget.userId}/Notifikasi",
    );

    // Dengarkan perubahan dan buat notifikasi otomatis
    dataTerbaruRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      suhu = (data["suhu"] as num?)?.toDouble();
      tanah = (data["persentase_kelembapan_tanah"] as num?)?.toDouble();
      cahaya = (data["intensitas_cahaya"] as num?)?.toDouble();

      _cekDanSimpanNotifikasi(data);
    });
  }

  // ================================================================
  //        FUNGSI CEK & SIMPAN NOTIFIKASI
  // ================================================================
  Future<void> _cekDanSimpanNotifikasi(Map data) async {
    String? judul;
    String pesan = "";
    String warna = "grey";

    // ====================== CEK SUHU ======================
    if (suhu != null) {
      if (suhu! < 20) {
        judul = "Suhu Terlalu Rendah";
        pesan = "Suhu berada di bawah normal (${suhu}°C)";
        warna = "blue";
      } else if (suhu! > 35) {
        judul = "Suhu Terlalu Tinggi";
        pesan = "Suhu melebihi batas aman (${suhu}°C)";
        warna = "red";
      }
    }

    // ==================== CEK KELEMBAPAN TANAH ====================
    if (tanah != null) {
      if (tanah! < 30) {
        judul ??= "Tanah Kering";
        pesan += "\nKelembapan tanah rendah (${tanah}%)";
        warna = "red";
      } else if (tanah! > 60) {
        judul ??= "Tanah Terlalu Basah";
        pesan += "\nKelembapan tanah tinggi (${tanah}%)";
        warna = "blue";
      }
    }

    // ==================== CEK CAHAYA ====================
    if (cahaya != null) {
      if (cahaya! < 5000) {
        judul ??= "Intensitas Cahaya Rendah";
        pesan += "\nCahaya redup (${cahaya} lux)";
        warna = "blue";
      } else if (cahaya! > 50000) {
        judul ??= "Intensitas Cahaya Tinggi";
        pesan += "\nCahaya terlalu terang (${cahaya} lux)";
        warna = "red";
      }
    }

    // Jika normal → jangan buat notif
    if (judul == null) return;

    // ==================== 1. ANTI SPAM (JUDUL/PESAN SAMA) ====================
    if (lastJudul == judul && lastPesan == pesan.trim()) return;

    // ==================== 2. COOL-DOWN ====================
    final now = DateTime.now().millisecondsSinceEpoch;
    if (lastSentTime != null && now - lastSentTime! < cooldownMs) {
      return; // belum 1 menit → jangan spam
    }

    lastSentTime = now; // set waktu

    // Simpan sebagai notifikasi terakhir
    lastJudul = judul;
    lastPesan = pesan.trim();

    // Waktu teks
    final waktu = DateFormat('dd MMM yyyy, HH:mm:ss').format(DateTime.now());

    // ==================== 3. SIMPAN KE FIREBASE ====================
    await notifikasiRef.push().set({
      "judul": judul,
      "pesan": pesan.trim(),
      "warna": warna,
      "ikon": "assets/image/suhu.png",
      "waktu": waktu,
      "timestamp": ServerValue.timestamp,
    });
  }

  Future<void> _hapusNotifikasi(String key) async {
    await notifikasiRef.child(key).remove();
  }

  // ================================================================
  //        UI NOTIFIKASI
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Notifikasi SmartFarm",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset('assets/image/back.png', width: 24, height: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: StreamBuilder(
        stream: notifikasiRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Belum ada notifikasi."));
          }

          final raw = (snapshot.data!.snapshot.value as Map);

          final semuaData =
              raw.entries.map((entry) {
                final key = entry.key;
                final value = Map<String, dynamic>.from(entry.value);
                return {"key": key, ...value};
              }).toList()..sort(
                (a, b) => (b["timestamp"] ?? 0).compareTo(a["timestamp"] ?? 0),
              );

          return ListView.builder(
            itemCount: semuaData.length,
            itemBuilder: (context, index) {
              final notif = semuaData[index];

              return Card(
                margin: const EdgeInsets.all(10),
                color: _warnaCard(notif["warna"]),
                child: ListTile(
                  leading: Image.asset(
                    notif["ikon"] ?? "assets/image/logo.png",
                    width: 40,
                    height: 40,
                  ),
                  title: Text(
                    notif["judul"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notif["pesan"] ?? ""),
                      const SizedBox(height: 5),
                      Text(
                        "🕒 ${notif["waktu"] ?? ""}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Image.asset(
                      'assets/image/hapus.png', // pastikan path benar
                      width: 25,
                      height: 25,
                    ),
                    onPressed: () {
                      _hapusNotifikasi(notif["key"]);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // =================== WARNA CARD ===================
  Color _warnaCard(String? warna) {
    switch (warna) {
      case "red":
        return const Color(0xFFFFA5A5); // merah lembut
      case "blue":
        return const Color(0xFFA5C8FF); // biru soft
      case "green":
        return const Color(0xFFA5FFBE); // hijau soft
      default:
        return const Color(0xFF3A3A3A); // abu gelap
    }
  }
}
