import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        "title": "Suhu Tanah",
        "message":
            "Suhu saat ini 24°C, kondisi cerah berawan. Pastikan tanaman tidak kekurangan air.",
        "image": "assets/image/suhu.png",
        "color": Colors.orange,
      },
      {
        "title": "Serangan Hama",
        "message":
            "Tingkat serangan hama meningkat pada hari ini. Segera lakukan penyemprotan pestisida.",
        "image": "assets/image/hama.png",
        "color": Colors.red,
      },
      {
        "title": "Tips Pertanian",
        "message":
            "Jangan terlalu banyak air karena cuaca sering hujan. Periksa kondisi tanah sebelum menyiram.",
        "image": "assets/image/tips.png",
        "color": Colors.green,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Image.asset(
            "assets/image/back.png", // ganti dengan gambar panah back buatanmu
            width: 24,
            height: 24,
          ),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (notif["color"] as Color).withOpacity(0.2),
                radius: 26,
                child: Image.asset(
                  notif["image"] as String,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
              title: Text(
                notif["title"] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(notif["message"] as String),
            ),
          );
        },
      ),
    );
  }
}
