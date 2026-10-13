import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mango_ripe/core/constants/app_constants.dart';
import 'package:mango_ripe/core/theme/app_colors.dart';
import 'package:mango_ripe/data/models/scan_result.dart';

/// Branded loading screen shown while the app boots.
///
/// [main] hands control to the widget tree immediately and the blocking setup
/// (orientation lock, system UI style, Hive) happens here, so the user never
/// sees a blank white window. Once bootstrap completes [child] is rendered in
/// place of the loading UI, without a route transition.
class SplashScreen extends StatefulWidget {
  final Widget child;

  const SplashScreen({super.key, required this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _bootstrap = _runBootstrap();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runBootstrap() {
    return Future.wait<void>([
      _setupPlatform(),
      _setupStorage(),
      // Keep the splash up long enough to read as a real loading state rather
      // than a flash, and to give the app fonts time to resolve.
      Future<void>.delayed(AppConstants.minSplashDuration),
    ]).whenComplete(() {
      // Runs on success and on failure. Stops the pulse so the error view is
      // not re-rendering at 60fps behind the message.
      if (mounted) _pulseController.stop();
    });
  }

  Future<void> _setupPlatform() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _setupStorage() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(ScanResultAdapter().typeId)) {
      Hive.registerAdapter(ScanResultAdapter());
    }
    await Hive.openBox<ScanResult>(AppConstants.scanHistoryBox);
  }

  void _retry() {
    _pulseController.repeat(reverse: true);
    setState(() {
      _bootstrap = _runBootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return _buildError(snapshot.error);
          }
          return widget.child;
        }
        return _buildLoading();
      },
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) => Transform.scale(
                      scale: 0.94 + _pulseController.value * 0.08,
                      child: child,
                    ),
                    child: _buildLogo(),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appTagline,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                const SizedBox(height: 48),
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.mangoAmber,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 20),
                Text(
                  'Preparing your ripeness scanner…',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.mangoAmber.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mangoAmber.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildError(Object? error) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: AppColors.overripeColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'Could not start MangoAI',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Local storage failed to open. $error',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
