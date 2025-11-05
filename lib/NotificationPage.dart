import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref(
    "SmartFarm/Data_Terbaru/Notifikasi",
  );
  double? suhu;
  double? kelembaban;
  String? status;

  @override
  void initState() {
    super.initState();
    // Dengarkan perubahan di Data_Terbaru
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          suhu = (data["suhu"] as num).toDouble();
          kelembaban = (data["kelembaban_udara"] as num).toDouble();
        });
        _updateNotification(); // perbarui notifikasi otomatis
      }
    });
  }

  void _updateNotification() async {
    if (suhu == null || kelembaban == null) return;

    String title = "";
    String message = "";
    String color = "";
    String image = "";

    if (suhu! > 30) {
      title = "Peringatan Suhu";
      message = "Suhu udara tinggi: ${suhu!.toStringAsFixed(1)}°C";
      color = "red";
      image = "assets/image/suhu.png";
    } else if (suhu! < 20) {
      title = "Suhu Rendah";
      message = "Suhu udara rendah: ${suhu!.toStringAsFixed(1)}°C";
      color = "blue";
      image = "assets/image/suhu.png";
    } else {
      title = "Suhu Normal";
      message = "Suhu stabil pada ${suhu!.toStringAsFixed(1)}°C";
      color = "green";
      image = "assets/image/suhu.png";
    }

    if (kelembaban! > 90) {
      message += "\nKelembaban tinggi: ${kelembaban!.toStringAsFixed(1)}%";
    } else if (kelembaban! < 40) {
      message += "\nKelembaban rendah: ${kelembaban!.toStringAsFixed(1)}%";
    }

    // Simpan notifikasi ke Firebase
    DatabaseReference notifRef = FirebaseDatabase.instance
        .ref("SmartFarm/Notifikasi")
        .push();
    await notifRef.set({
      "title": title,
      "message": message,
      "color": color,
      "image": image,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/image/back.png', // pastikan file ini ada di folder assets/image/
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Navigator.pop(context); // kembali ke halaman sebelumnya
          },
        ),
        title: const Text(
          "Notifikasi SmartFarm",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref("SmartFarm/Notifikasi").onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Belum ada notifikasi."));
          }

          final data = (snapshot.data!.snapshot.value as Map).values.toList();

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final notif = Map<String, dynamic>.from(data[index]);
              return Card(
                margin: const EdgeInsets.all(10),
                color: _getColor(notif["color"]),
                child: ListTile(
                  leading: Image.asset(
                    notif["image"] ?? "assets/image/logo.png",
                  ),
                  title: Text(
                    notif["title"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(notif["message"] ?? ""),
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
        return const Color.fromARGB(255, 255, 0, 25);
      case "blue":
        return const Color.fromARGB(255, 0, 140, 255);
      case "green":
        return const Color.fromARGB(255, 0, 251, 8);
      default:
        return const Color.fromARGB(255, 140, 137, 137);
    }
  }
}
