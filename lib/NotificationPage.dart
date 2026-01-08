import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  final String userId;

  const NotificationPage({super.key, required this.userId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late final DatabaseReference notifikasiRef;

  @override
  void initState() {
    super.initState();

    // 🔥 AKTIFKAN SERVICE (AMAN DARI DOUBLE LISTENER)
    NotificationService().start(widget.userId);

    notifikasiRef = FirebaseDatabase.instance.ref(
      "SmartFarm/User/${widget.userId}/Notifikasi",
    );
  }

  Future<void> _hapusNotifikasi(String key) async {
    await notifikasiRef.child(key).remove();
  }

  String _formatJamMenit(dynamic timestamp) {
    if (timestamp == null) return "";

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final jam = date.hour.toString().padLeft(2, '0');
    final menit = date.minute.toString().padLeft(2, '0');

    return "$jam:$menit";
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
          icon: Image.asset('assets/image/back.png', width: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: notifikasiRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Belum ada notifikasi."));
          }

          final raw = snapshot.data!.snapshot.value as Map;
          final data =
              raw.entries
                  .map(
                    (e) => {
                      "key": e.key,
                      ...Map<String, dynamic>.from(e.value),
                    },
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      (b["timestamp"] ?? 0).compareTo(a["timestamp"] ?? 0),
                );

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final notif = data[index];

              return Card(
                margin: const EdgeInsets.all(10),
                color: _warnaCard(notif["warna"]),
                child: ListTile(
                  leading: Image.asset(
                    notif["ikon"] ?? "assets/image/logo.png",
                    width: 40,
                  ),
                  title: Text(
                    notif["judul"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // ✅ SUBTITLE HANYA SATU (ISI PESAN + JAM)
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notif["pesan"] ?? ""),
                      const SizedBox(height: 4),
                      Text(
                        _formatJamMenit(notif["timestamp"]),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  trailing: IconButton(
                    icon: Image.asset('assets/image/hapus.png', width: 25),
                    onPressed: () => _hapusNotifikasi(notif["key"]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _warnaCard(String? warna) {
    switch (warna) {
      case "red":
        return const Color(0xFFFFA5A5);
      case "blue":
        return const Color(0xFFA5C8FF);
      default:
        return const Color(0xFFE0E0E0);
    }
  }
}
