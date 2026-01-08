  import 'package:flutter/material.dart';
  import 'package:firebase_database/firebase_database.dart';

  class AITipsCard extends StatelessWidget {
    const AITipsCard({super.key});

    // Mengelompokkan nilai s
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

    Map<String, String> _generateTip({
      required double suhu,
      required double kelembapanTanah,
      required double cahaya,
    }) {
      final sSuhu = _statusSuhu(suhu);
      final sTanah = _statusTanah(kelembapanTanah);
      final sCahaya = _statusCahaya(cahaya);

      final needsAuto =
          sTanah == 'Kering' ||
          sSuhu == 'Panas' ||
          sCahaya == 'Redup' ||
          sCahaya == 'Terang';

      // Kumpulkan  rekomendasi
      String conclusion;
      if (needsAuto) {
        final reasons = <String>[];
        if (sTanah == 'Kering') reasons.add('tanah kering → perlu penyiraman');
        if (sSuhu == 'Panas') reasons.add('suhu tinggi → risiko stres tanaman');
        if (sCahaya == 'Redup') reasons.add('cahaya kurang');
        if (sCahaya == 'Terang') reasons.add('cahaya terlalu kuat');

        conclusion = reasons.join(', ');
      } else {
        conclusion = 'Semua kondisi normal dan stabil.';
      }

      return {'tip': conclusion, 'decision': needsAuto ? 'AI' : 'Manual'};
    }

    // WIDGET BARIS SENSOR
    Widget _sensorRow(Widget iconWidget, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white70)),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // UI TIPS
    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: StreamBuilder(
          stream: FirebaseDatabase.instance.ref("SmartFarm/Data_Terbaru").onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Belum ada data sensor untuk menghasilkan kesimpulan.',
                  style: TextStyle(color: Colors.white),
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

            final isAI = result['decision'] == 'AI';

            // TAMPILAN  REKOMENDASI
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAI
                      ? [Colors.red.shade600, Colors.red.shade400]
                      : [Colors.green.shade600, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAI ? 'Rekomendasi ' : '✅ Kondisi Normal',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _sensorRow(
                    Image.asset('assets/image/suhu.png', width: 20, height: 20),
                    'Suhu',
                    '${suhu.toStringAsFixed(1)} °C',
                  ),

                  _sensorRow(
                    Image.asset('assets/image/tanah.png', width: 20, height: 20),
                    'Kelembapan Tanah',
                    '${tanah.toStringAsFixed(0)} %',
                  ),

                  _sensorRow(
                    Image.asset('assets/image/cahaya.png', width: 20, height: 20),
                    'Cahaya',
                    '${cahaya.toStringAsFixed(0)} Lux',
                  ),

                  const Divider(color: Colors.white54, height: 24),

                  Text(
                    result['tip']!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }
