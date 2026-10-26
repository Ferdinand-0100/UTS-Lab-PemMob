import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/presentation/pages/home/home_page.dart';

void main() {
  testWidgets('HomePage renders app bar', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomePage())),
    );

    // Trigger a frame and let providers settle.
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('Quiz Master'), findsOneWidget);
  });
}
