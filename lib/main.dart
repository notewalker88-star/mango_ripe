import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:mango_ripe/core/constants/app_constants.dart';
import 'package:mango_ripe/core/theme/app_theme.dart';
import 'package:mango_ripe/data/models/scan_result.dart';
import 'package:mango_ripe/features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ScanResultAdapter());
  await Hive.openBox<ScanResult>(AppConstants.scanHistoryBox);

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
      home: const OnboardingScreen(),
    );
  }
}
