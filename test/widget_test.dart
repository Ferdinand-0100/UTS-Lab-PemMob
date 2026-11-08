 import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/presentation/pages/home/home_page.dart';

void main() {
  testWidgets('HomePage renders the nav strip brand label', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomePage())),
    );

    // Trigger a frame and let providers settle.
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // The nav strip renders the brand as 'QUIZ MASTER' (all-caps Space Mono).
    expect(find.text('QUIZ MASTER'), findsOneWidget);
  });
}
