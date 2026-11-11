import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Minimum duration of the CRT boot loading screen shown between
/// intentional navigations (e.g. tapping a quiz card, pressing back).
///
/// This makes every screen transition feel like the CRT is "switching
/// channels" rather than loading instantly, keeping the hardware illusion.
const Duration kNavLoadDuration = Duration(milliseconds: 900);

/// Navigate to [path] after showing the CRT loading screen for at
/// least [kNavLoadDuration].  Any real async work in [onNavigate] runs
/// in parallel — so if the data takes longer, we still wait for it.
///
/// Usage:
/// ```dart
/// await navigateWithLoad(context, () => context.push(AppRouter.friends));
/// ```
Future<void> navigateWithLoad(
  BuildContext context,
  VoidCallback onNavigate,
) async {
  // Minimum artificial delay so the boot screen is always visible
  await Future.delayed(kNavLoadDuration);
  if (context.mounted) onNavigate();
}

/// Same as [navigateWithLoad] but also runs an async [work] function in
/// parallel (e.g. pre-loading data).  Waits for whichever finishes last.
Future<void> navigateWithLoadAndWork(
  BuildContext context,
  Future<void> Function() work,
  VoidCallback onNavigate,
) async {
  await Future.wait([
    Future.delayed(kNavLoadDuration),
    work(),
  ]);
  if (context.mounted) onNavigate();
}
