import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'HomePage.dart';

class DeviceControlPage extends StatefulWidget {
  final String? userName;
  final String? userLocation;
  final String userId;

  const DeviceControlPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userLocation,
  });

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  late DatabaseReference controlRef;

  bool suhuOn = true;
  bool tanahOn = true;
  bool cahayaOn = true;

  @override
  void initState() {
    super.initState();

    void listenSensorControl() {
      FirebaseDatabase.instance
          .ref("SmartFarm/User/${widget.userId}/Sensor_Control")
          .onValue
          .listen((event) {
            if (event.snapshot.value == null) return;

            final data = Map<String, dynamic>.from(event.snapshot.value as Map);

            setState(() {
              suhuOn = data["suhu_on"] ?? true;
              tanahOn = data["tanah_on"] ?? true;
              cahayaOn = data["cahaya_on"] ?? true;
            });
          });
    }

    listenSensorControl();

    /// 🔥 Set path sensor control khusus user
    controlRef = FirebaseDatabase.instance.ref(
      "SmartFarm/User/${widget.userId}/Sensor_Control",
    );

    _loadStatus();
  }

  void _loadStatus() async {
    final snap = await controlRef.get();

    if (snap.exists) {
      final data = Map<String, dynamic>.from(snap.value as Map);

      setState(() {
        suhuOn = data["suhu_on"] ?? true;
        tanahOn = data["tanah_on"] ?? true;
        cahayaOn = data["cahaya_on"] ?? true;
      });
    }
  }

  void updateSensor(String key, bool val) {
    controlRef.update({key: val});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Kontrol Sensor",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset('assets/image/back.png', width: 24, height: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            switchTile("Sensor Suhu Udara", suhuOn, (v) {
              setState(() => suhuOn = v);
              updateSensor("suhu_on", v);
            }),

            switchTile("Sensor Kelembaban Tanah", tanahOn, (v) {
              setState(() => tanahOn = v);
              updateSensor("tanah_on", v);
            }),

            switchTile("Sensor Intensitas Cahaya", cahayaOn, (v) {
              setState(() => cahayaOn = v);
              updateSensor("cahaya_on", v);
            }),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomePage(
                        userId: widget.userId,
                        userName: widget.userName,
                        userLocation: widget.userLocation,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Lanjut ke Home",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget switchTile(String title, bool value, Function(bool) onChange) {
    return Card(
      elevation: 3,
      child: ListTile(
        title: Text(title),
        trailing: Switch(
          value: value,
          activeColor: Colors.green,
          onChanged: onChange,
        ),
      ),
    );
  }
}
