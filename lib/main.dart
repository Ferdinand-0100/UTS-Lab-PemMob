import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/app.dart';

/// Entry point. Wraps the app in [ProviderScope] so Riverpod
/// providers are available throughout the widget tree.
void main() {
  runApp(
    const ProviderScope(
      child: QuizApp(),
    ),
  );
}
