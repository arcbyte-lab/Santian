import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santian/app.dart';

void main() {
  testWidgets('the app shows the home widget it is given', (tester) async {
    await tester.pumpWidget(const SantianApp(home: Scaffold(body: Text('hi'))));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('hi'), findsOneWidget);
  });
}
