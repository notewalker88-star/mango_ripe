import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mango_ripe/core/theme/app_theme.dart';
import 'package:mango_ripe/features/onboarding/onboarding_screen.dart';
import 'package:mango_ripe/features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Render straight away. SplashScreen runs the blocking setup (orientation,
  // system UI, Hive) and swaps in the real home once it is done, so the app
  // never opens on a blank white window.
  runApp(const ProviderScope(child: MangoRipeApp()));
}

class MangoRipeApp extends StatelessWidget {
  const MangoRipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MangoAI – Ripeness Detector',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(child: OnboardingScreen()),
    );
  }
}
