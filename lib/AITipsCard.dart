import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// =======================================
// Widget: AI Tips otomatis berdasarkan 3 sensor
// =======================================
class AITipsCard extends StatelessWidget {
  const AITipsCard({super.key});

  String _statusSuhu(double suhu) {
    if (suhu < 20) return 'Dingin';
    if (suhu > 35) return 'Panas';
    return 'Normal';
  }

  String _statusTanah(double vwc) {
    if (vwc < 30) return 'Kering';
    if (vwc > 60) return 'Basah';
    return 'Normal';
  }

  String _statusCahaya(double lux) {
    if (lux < 5000) return 'Redup';
    if (lux > 50000) return 'Terang';
    return 'Normal';
  }

  /// Menghasilkan kesimpulan berdasarkan 3 sensor.
  Map<String, String> _generateTip({
    required double suhu,
    required double kelembapanTanah,
    required double cahaya,
  }) {
    final sSuhu = _statusSuhu(suhu);
    final sTanah = _statusTanah(kelembapanTanah);
    final sCahaya = _statusCahaya(cahaya);

    final needsAuto =
        (sTanah == 'Kering') ||
        (sSuhu == 'Panas') ||
        (sCahaya == 'Redup') ||
        (sCahaya == 'Terang');

    // =============================
    // KESIMPULAN
    // =============================
    String conclusion;
    if (needsAuto) {
      final reasons = <String>[];
      if (sTanah == 'Kering') reasons.add('tanah kering → perlu penyiraman');
      if (sSuhu == 'Panas') reasons.add('suhu tinggi → risiko stres tanaman');
      if (sCahaya == 'Redup')
        reasons.add('cahaya kurang → tingkatkan pencahayaan');
      if (sCahaya == 'Terang')
        reasons.add('cahaya terlalu kuat → gunakan naungan');

      conclusion = 'Kesimpulan: ${reasons.join(', ')}.';
    } else {
      conclusion = 'Kesimpulan: Semua kondisi normal dan stabil.';
    }

    // =============================
    // Bagian angka + status sensor
    // =============================
    final sensorInfo = [
      'Suhu: ${suhu.toStringAsFixed(1)} °C ($sSuhu)',
      'Kelembapan Tanah: ${kelembapanTanah.toStringAsFixed(0)}% ($sTanah)',
      'Cahaya: ${cahaya.toStringAsFixed(0)} Lux ($sCahaya)',
    ].join('\n');

    return {
      'sensor': sensorInfo,
      'tip': conclusion,
      'decision': needsAuto ? 'AI' : 'Manual',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder(
        stream: FirebaseDatabase.instance.ref("SmartFarm/Data_Terbaru").onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Card(
              color: Colors.orange,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Belum ada data sensor untuk menghasilkan kesimpulan.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final suhu = double.tryParse(data['suhu']?.toString() ?? '') ?? 0.0;
          final tanah =
              double.tryParse(
                data['persentase_kelembapan_tanah']?.toString() ?? '',
              ) ??
              0.0;
          final cahaya =
              double.tryParse(data['intensitas_cahaya']?.toString() ?? '') ??
              0.0;

          final result = _generateTip(
            suhu: suhu,
            kelembapanTanah: tanah,
            cahaya: cahaya,
          );

          final sensorText = result['sensor']!;
          final tipText = result['tip']!;
          final decision = result['decision']!;

          final cardColor = decision == 'AI'
              ? Colors.red[600]
              : Colors.green[600];

          return Card(
            elevation: 3,
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                '$sensorText\n\n$tipText',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
