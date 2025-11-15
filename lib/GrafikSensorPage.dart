import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';

class GrafikSensorPage extends StatelessWidget {
  const GrafikSensorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Grafik Sensor Harian'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder(
          stream: FirebaseDatabase.instance
              .ref("/SmartFarm/User/Riwayat_Suhu")
              .onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData ||
                snapshot.data!.snapshot.value == null) {
              return const Center(
                child: Text(
                  "Belum ada data riwayat",
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              );
            }

            final data = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map,
            );

            // Urutkan berdasarkan waktu
            final entries = data.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));

            final suhuPoints = <FlSpot>[];
            final kelembapanPoints = <FlSpot>[];
            final cahayaPoints = <FlSpot>[];
            final labels = <String>[];

            for (int i = 0; i < entries.length; i++) {
              final value = Map<String, dynamic>.from(entries[i].value);
              final suhu = double.tryParse(value['suhu'].toString()) ?? 0;
              final kelembapan =
                  double.tryParse(value['kelembaban'].toString()) ?? 0;
              final cahaya =
                  double.tryParse(value['intensitas_cahaya'].toString()) ?? 0;

              suhuPoints.add(FlSpot(i.toDouble(), suhu));
              kelembapanPoints.add(FlSpot(i.toDouble(), kelembapan));
              cahayaPoints.add(FlSpot(i.toDouble(), cahaya));
              labels.add(entries[i].key.split('-').last.replaceAll(':00', ''));
            }

            return Column(
              children: [
                const Text(
                  "Grafik Sensor Harian (Suhu, Kelembapan, Cahaya)",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.black87,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              String label;
                              if (spot.barIndex == 0) {
                                label =
                                    'Suhu: ${spot.y.toStringAsFixed(1)} °C';
                              } else if (spot.barIndex == 1) {
                                label =
                                    'Kelembapan: ${spot.y.toStringAsFixed(1)} %';
                              } else {
                                label =
                                    'Cahaya: ${spot.y.toStringAsFixed(0)} Lux';
                              }
                              return LineTooltipItem(
                                label,
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 10,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 3,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index < 0 || index >= labels.length) {
                                return const SizedBox();
                              }
                              return Text(
                                labels[index],
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      lineBarsData: [
                        // Garis 1 - Suhu
                        LineChartBarData(
                          spots: suhuPoints,
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.red.withOpacity(0.1),
                          ),
                        ),
                        // Garis 2 - Kelembapan
                        LineChartBarData(
                          spots: kelembapanPoints,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                        // Garis 3 - Intensitas Cahaya
                        LineChartBarData(
                          spots: cahayaPoints,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.orange.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ Keterangan Warna
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    LegendItem(color: Colors.red, text: 'Suhu (°C)'),
                    LegendItem(color: Colors.blue, text: 'Kelembapan (%)'),
                    LegendItem(color: Colors.orange, text: 'Cahaya (Lux)'),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ✅ Widget kecil untuk keterangan legenda
class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 15, height: 15, color: color),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
