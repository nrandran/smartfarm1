import 'package:firebase_database/firebase_database.dart';

// SERVICE: DATA LOGGER SENSOR (Bertugas menyimpan data sensor user ke Firebase secara berkala)
class DataLoggerService {
  static Future<void> saveUserSensor(String userId) async {
    final dbRef = FirebaseDatabase.instance.ref();

    try {
      // Ambil data DeviceSensor user
      final snapshot = await dbRef
          .child("SmartFarm/User/$userId/DeviceSensor")
          .get();

      if (!snapshot.exists) return;

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      final suhu = double.tryParse(data['suhu'].toString()) ?? 0;
      final cahaya = double.tryParse(data['cahaya'].toString()) ?? 0;
      final tanah =
          double.tryParse(data['persentase_kelembapan_tanah'].toString()) ??
          0.0;

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Simpan ke History/Suhu, Cahaya, tanah
      await dbRef.child("SmartFarm/User/$userId/History/Suhu/$timestamp").set({
        'value': suhu,
        'time': DateTime.now().toIso8601String(),
      });
      await dbRef.child("SmartFarm/User/$userId/History/Cahaya/$timestamp").set(
        {'value': cahaya, 'time': DateTime.now().toIso8601String()},
      );
      await dbRef.child("SmartFarm/User/$userId/History/tanah/$timestamp").set({
        'value': tanah,
        'time': DateTime.now().toIso8601String(),
      });

      print("Sensor tersimpan: suhu=$suhu, cahaya=$cahaya, tanah=$tanah");
    } catch (e) {
      print("Gagal menyimpan sensor: $e");
    }
  }
}
