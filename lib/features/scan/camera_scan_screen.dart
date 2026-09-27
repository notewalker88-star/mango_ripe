import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mango_ripe/core/theme/app_colors.dart';
import 'package:mango_ripe/data/models/scan_result.dart';
import 'package:mango_ripe/data/providers/app_providers.dart';
import 'package:mango_ripe/core/utils/image_utils.dart';
import 'package:mango_ripe/features/results/results_screen.dart';
import 'package:mango_ripe/widgets/mango_analyzing_overlay.dart';

class CameraScanScreen extends ConsumerStatefulWidget {
  const CameraScanScreen({super.key});

  @override
  ConsumerState<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends ConsumerState<CameraScanScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  Uint8List? _capturedImageBytes;
  String? _cameraErrorMessage;
  int _cameraIndex = 0;
  late AnimationController _scanLineController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraErrorMessage = 'No physical camera detected on device.';
          });
        }
        return;
      }
      await _startCamera(_cameras[_cameraIndex]);
    } catch (e) {
      debugPrint('Camera discovery error: $e');
      if (mounted) {
        setState(() {
          _cameraErrorMessage = 'Unable to initialize camera: $e';
        });
      }
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isInitialized = true;
          _cameraErrorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() {
          _cameraErrorMessage = 'Failed to start camera feed: $e';
        });
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _cameraController?.dispose();
    setState(() {
      _isInitialized = false;
    });
    await _startCamera(_cameras[_cameraIndex]);
  }

  Future<void> _captureAndAnalyze() async {
    if (_isCapturing) return;

    // If on emulator/device without physical camera stream
    if (!_isInitialized || _cameraController == null) {
      setState(() {
        _isCapturing = true;
        _capturedImageBytes = null;
      });
      try {
        final mlService = ref.read(mlServiceProvider);
        // Fallback simulation for testing
        final dummyBytes = Uint8List(224 * 224 * 3);
        final results = await Future.wait([
          mlService.classifyImage(dummyBytes),
          Future.delayed(const Duration(milliseconds: 2200)),
        ]);
        final result = results[0] as ScanResult;

        if (mounted) {
          ref.read(currentScanResultProvider.notifier).state = result;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ResultsScreen()),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isCapturing = false;
            _capturedImageBytes = null;
          });
        }
      }
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await _cameraController!.takePicture();
      final bytes = await photo.readAsBytes();
      if (mounted) {
        setState(() {
          _capturedImageBytes = bytes;
        });
      }

      final cropped = await ImageUtils.centerCropAsync(bytes);
      if (mounted) {
        setState(() {
          _capturedImageBytes = cropped;
        });
      }

      final mlService = ref.read(mlServiceProvider);
      final results = await Future.wait([
        mlService.classifyImage(cropped),
        Future.delayed(const Duration(milliseconds: 2000)),
      ]);
      ScanResult result = results[0] as ScanResult;
      final thumbPath = await ImageUtils.saveThumbnail(cropped, result.id);
      result = result.copyWith(imagePath: thumbPath);

      if (mounted) {
        ref.read(currentScanResultProvider.notifier).state = result;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResultsScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: $e'),
            backgroundColor: AppColors.overripeColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _capturedImageBytes = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview or Fallback
          if (_isInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else if (_cameraErrorMessage != null)
            _buildCameraFallback()
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.mangoAmber),
            ),

          // Overlay gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.scanOverlayGradient,
            ),
          ),

          // Scan Frame
          Center(child: _buildScanFrame()),

          // Top Bar
          _buildTopBar(),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),

          // High-Tech Analyzing Loading Animation Overlay
          if (_isCapturing)
            Positioned.fill(
              child: MangoAnalyzingOverlay(
                imageBytes: _capturedImageBytes,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraFallback() {
    return Container(
      color: AppColors.bgDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera Feed Unavailable',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _cameraErrorMessage ?? 'Using simulated scanner mode.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanFrame() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        return Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.mangoAmber.withValues(
                alpha: 0.5 + _pulseController.value * 0.5,
              ),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Corner decorations
              ..._buildCorners(),
              // Scan line
              AnimatedBuilder(
                animation: _scanLineController,
                builder: (_, __) {
                  return Positioned(
                    top: _scanLineController.value * 240,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.mangoAmber.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCorners() {
    const size = 20.0;
    const thickness = 3.0;
    const color = AppColors.mangoAmber;

    Widget corner({
      required AlignmentGeometry alignment,
      double rotationTurns = 0,
    }) {
      return Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: color, width: thickness),
              left: const BorderSide(color: color, width: thickness),
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6)),
          ),
        ),
      );
    }

    return [
      corner(alignment: Alignment.topLeft),
      Transform.rotate(
        angle: 1.5708,
        child: corner(alignment: Alignment.topRight),
      ),
      Transform.rotate(
        angle: 3.1416,
        child: corner(alignment: Alignment.bottomRight),
      ),
      Transform.rotate(
        angle: -1.5708,
        child: corner(alignment: Alignment.bottomLeft),
      ),
    ];
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const Spacer(),
            Text(
              'Scan Mango',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            if (_cameras.length > 1)
              IconButton(
                icon: const Icon(
                  Icons.flip_camera_ios_rounded,
                  color: Colors.white,
                ),
                onPressed: _flipCamera,
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ).animate().fadeIn(),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Position the mango inside the frame and tap scan',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Capture Button
              GestureDetector(
                onTap: _captureAndAnalyze,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mangoAmber.withValues(
                            alpha: 0.3 + _pulseController.value * 0.2,
                          ),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.amberGradient,
                      ),
                      child: _isCapturing
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.black,
                              size: 28,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3).fadeIn(delay: 200.ms);
  }
}
