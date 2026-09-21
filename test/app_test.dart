import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santian/app.dart';

void main() {
  testWidgets('the app builds an empty MaterialApp', (tester) async {
    await tester.pumpWidget(const SantianApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
