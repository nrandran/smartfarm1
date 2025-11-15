import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // ✅ Untuk format waktu

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final DatabaseReference dataTerbaruRef =
      FirebaseDatabase.instance.ref("SmartFarm/Data_Terbaru");
  final DatabaseReference notifRef =
      FirebaseDatabase.instance.ref("SmartFarm/Notifikasi");
  final DatabaseReference riwayatSuhuRef =
      FirebaseDatabase.instance.ref("SmartFarm/User/Riwayat_Suhu");

  double? suhu;
  double? kelembaban;
  String? waktuTerakhir; // 🕒 Simpan waktu dari Riwayat_Suhu

  @override
  void initState() {
    super.initState();

    // 🔁 Dengarkan perubahan suhu & kelembaban terbaru
    dataTerbaruRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          suhu = (data["suhu"] as num?)?.toDouble();
          kelembaban = (data["kelembaban_udara"] as num?)?.toDouble();
        });
        _ambilWaktuTerbaru(); // Ambil waktu dari Riwayat_Suhu
      }
    });
  }

  Future<void> _ambilWaktuTerbaru() async {
    // Ambil data terakhir dari /SmartFarm/User/Riwayat_Suhu
    final snapshot = await riwayatSuhuRef.limitToLast(1).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      final lastEntry = data.values.first as Map;
      final waktu = lastEntry["waktu"] ?? DateTime.now().toIso8601String();

      setState(() {
        waktuTerakhir = waktu;
      });

      _updateNotification(waktu);
    }
  }

  Future<void> _updateNotification(String waktu) async {
    if (suhu == null || kelembaban == null) return;

    String? title;
    String message = "";
    String? color;
    String image = "assets/image/suhu.png";

    // 🔥 Logika suhu
    if (suhu! > 30) {
      title = "Peringatan Suhu Tinggi";
      message = "Suhu udara tinggi: ${suhu!.toStringAsFixed(1)}°C";
      color = "red";
    } else if (suhu! < 20) {
      title = "Suhu Rendah";
      message = "Suhu udara rendah: ${suhu!.toStringAsFixed(1)}°C";
      color = "blue";
    }

    // 💧 Logika kelembaban
    if (kelembaban! > 90) {
      message += "\nKelembaban tinggi: ${kelembaban!.toStringAsFixed(1)}%";
      title ??= "Peringatan Kelembaban";
      color ??= "red";
    } else if (kelembaban! < 40) {
      message += "\nKelembaban rendah: ${kelembaban!.toStringAsFixed(1)}%";
      title ??= "Kelembaban Rendah";
      color ??= "blue";
    }

    // 🚫 Jika semuanya normal → jangan simpan notifikasi
    if (title == null && message.isEmpty) return;

    // 🕒 Format waktu agar lebih mudah dibaca
    final formattedTime = DateFormat('dd MMM yyyy, HH:mm:ss')
        .format(DateTime.tryParse(waktu) ?? DateTime.now());

    // 💾 Simpan ke Firebase Realtime Database
    await notifRef.push().set({
      "title": title,
      "message": message,
      "color": color,
      "image": image,
      "timestamp": formattedTime, // ✅ waktu dari Riwayat_Suhu
    });
  }

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
        stream: notifRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Belum ada notifikasi."));
          }

          final data = (snapshot.data!.snapshot.value as Map).values
              .toList()
              .reversed
              .toList();

          return ListView.builder(
            reverse: true,
            itemCount: data.length,
            itemBuilder: (context, index) {
              final notif = Map<String, dynamic>.from(data[index]);
              return Card(
                margin: const EdgeInsets.all(10),
                color: _getColor(notif["color"]),
                child: ListTile(
                  leading: Image.asset(
                    notif["image"] ?? "assets/image/logo.png",
                    width: 40,
                    height: 40,
                  ),
                  title: Text(
                    notif["title"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notif["message"] ?? ""),
                      const SizedBox(height: 5),
                      Text(
                        "🕒 ${notif["timestamp"] ?? ''}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getColor(String? color) {
    switch (color) {
      case "red":
        return const Color.fromARGB(255, 255, 120, 120);
      case "blue":
        return const Color.fromARGB(255, 120, 180, 255);
      case "green":
        return const Color.fromARGB(255, 120, 255, 160);
      default:
        return const Color.fromARGB(255, 64, 64, 64);
    }
  }
}
