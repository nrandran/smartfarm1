import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_smart_farm/main.dart';

void main() {
  testWidgets('App loads StartSetupPage by default', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    expect(find.text('SMART FARM'), findsOneWidget);
    expect(find.text('DAFTAR'), findsOneWidget);
    expect(find.text('MASUK'), findsOneWidget);
  });
}
