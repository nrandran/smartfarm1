import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_smart_farm/main.dart';

void main() {
  testWidgets('App loads StartSetupPage by default', (
    WidgetTester tester,
  ) async {
    // Bungkus MyApp dengan MaterialApp agar test punya context lengkap
    await tester.pumpWidget(
      MaterialApp(
        home: MyApp(
          isLoggedIn: false,
          userId: null,
          userName: null,
          userLocation: null,
        ),
      ),
    );

    // Cek apakah halaman StartSetupPage tampil
    expect(find.text('SMART FARM'), findsOneWidget);
    expect(find.text('DAFTAR'), findsOneWidget);
    expect(find.text('MASUK'), findsOneWidget);
  });
}
