import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;
  NotificationService._internal();

  StreamSubscription<DatabaseEvent>? _sub;

  String? _lastJudul;
  String? _lastPesan;
  int _cooldownMs = 10000;
  int? _lastSentTime;

  void start(String userId) {
    if (_sub != null) return;

    final dataRef = FirebaseDatabase.instance.ref("SmartFarm/Data_Terbaru");

    final notifRef = FirebaseDatabase.instance.ref(
      "SmartFarm/User/$userId/Notifikasi",
    );

    _sub = dataRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      _cekDanSimpanNotifikasi(data, notifRef);
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _cekDanSimpanNotifikasi(
    Map data,
    DatabaseReference notifRef,
  ) async {
    String? judul;
    String pesan = "";
    String warna = "grey";
    String ikon = "assets/image/notif.png";

    final suhu = (data["suhu"] as num?)?.toDouble();
    final tanah = (data["persentase_kelembapan_tanah"] as num?)?.toDouble();
    final cahaya = (data["intensitas_cahaya"] as num?)?.toDouble();

    // === SUHU ===
    if (suhu != null) {
      if (suhu < 20) {
        judul = "Suhu Terlalu Rendah";
        pesan = "Suhu di bawah normal (${suhu}°C)";
        warna = "blue";
        ikon = "assets/image/suhu.png";
      } else if (suhu > 35) {
        judul = "Suhu Terlalu Tinggi";
        pesan = "Suhu melebihi batas aman (${suhu}°C)";
        warna = "red";
        ikon = "assets/image/suhu.png";
      }
    }

    // === TANAH ===
    if (tanah != null) {
      if (tanah < 30) {
        judul ??= "Tanah Kering";
        pesan += "\nKelembapan tanah rendah (${tanah}%)";
        warna = "red";
        ikon = "assets/image/tanah.png";
      } else if (tanah > 80) {
        judul ??= "Tanah Terlalu Basah";
        pesan += "\nKelembapan tanah tinggi (${tanah}%)";
        warna = "blue";
        ikon = "assets/image/tanah.png";
      }
    }

    // === CAHAYA ===
    if (cahaya != null) {
      if (cahaya < 5000) {
        judul ??= "Cahaya Rendah";
        pesan += "\nCahaya redup (${cahaya} lux)";
        warna = "blue";
        ikon = "assets/image/cahaya.png";
      } else if (cahaya > 50000) {
        judul ??= "Cahaya Tinggi";
        pesan += "\nCahaya terlalu terang (${cahaya} lux)";
        warna = "red";
        ikon = "assets/image/cahaya.png";
      }
    }

    if (judul == null) return;

    // Cegah duplikat
    if (_lastJudul == judul && _lastPesan == pesan.trim()) return;

    //Cooldown
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastSentTime != null && now - _lastSentTime! < _cooldownMs) return;

    _lastJudul = judul;
    _lastPesan = pesan.trim();
    _lastSentTime = now;

    await notifRef.push().set({
      "judul": judul,
      "pesan": pesan.trim(),
      "warna": warna,
      "ikon": ikon,
      "timestamp": ServerValue.timestamp,
    });
  }
}
