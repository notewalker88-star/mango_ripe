import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mango_ripe/core/constants/app_constants.dart';
import 'package:mango_ripe/core/theme/app_colors.dart';

/// Highly visual and interactive loading animation overlay for mango ripeness analysis.
///
/// Every animation is scoped to the smallest subtree that needs it and each
/// independently animating layer sits behind a [RepaintBoundary], so a 60fps
/// value change never rebuilds or re-rasterizes the captured image.
class MangoAnalyzingOverlay extends StatefulWidget {
  final Uint8List? imageBytes;
  final String? customMessage;
  final VoidCallback? onCancel;
  final Duration totalDuration;

  const MangoAnalyzingOverlay({
    super.key,
    this.imageBytes,
    this.customMessage,
    this.onCancel,
    this.totalDuration = AppConstants.minAnalyzeDuration,
  });

  @override
  State<MangoAnalyzingOverlay> createState() => _MangoAnalyzingOverlayState();
}

class _MangoAnalyzingOverlayState extends State<MangoAnalyzingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _laserController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  static const double _scannerSize = 230.0;
  static const double _viewportSize = _scannerSize - 20;
  static const double _beamHeight = 21;

  static const List<_AnalysisPhase> _phases = [
    _AnalysisPhase(
      title: 'Detecting Mango Geometry',
      subtitle: 'Scanning contours & bounding area...',
      icon: Icons.filter_center_focus_rounded,
      rangeStart: 0.0,
      rangeEnd: 0.22,
    ),
    _AnalysisPhase(
      title: 'Color Spectrum Analysis',
      subtitle: 'Extracting RGB & HSV peel chrominance...',
      icon: Icons.palette_outlined,
      rangeStart: 0.22,
      rangeEnd: 0.48,
    ),
    _AnalysisPhase(
      title: 'Texture & Firmness Index',
      subtitle: 'Evaluating skin consistency & sugar profile...',
      icon: Icons.bubble_chart_outlined,
      rangeStart: 0.48,
      rangeEnd: 0.74,
    ),
    _AnalysisPhase(
      title: 'MobileNetV2 Inference',
      subtitle: 'Classifying ripeness probability tensor...',
      icon: Icons.psychology_rounded,
      rangeStart: 0.74,
      rangeEnd: 0.94,
    ),
    _AnalysisPhase(
      title: 'Ripeness Profile Ready',
      subtitle: 'Synthesizing shelf-life & recommendations...',
      icon: Icons.verified_rounded,
      rangeStart: 0.94,
      rangeEnd: 1.0,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: widget.totalDuration,
    )..forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _laserController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  _AnalysisPhase _getCurrentPhase(double progress) {
    for (final phase in _phases) {
      if (progress >= phase.rangeStart && progress <= phase.rangeEnd) {
        return phase;
      }
    }
    return _phases.last;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        child: SafeArea(
          child: Stack(
            children: [
              // Ambient background glows
              Positioned.fill(child: _buildAmbientBackdrop()),

              // Main content column
              Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top badge
                      RepaintBoundary(child: _buildTopBadge()),

                      const SizedBox(height: 24),

                      // Center holographic scanner
                      RepaintBoundary(child: _buildHolographicScanner()),

                      const SizedBox(height: 32),

                      // Phase title & subtitle
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) =>
                              _buildPhaseInfo(_getCurrentPhase(_progressController.value)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Animated progress bar & percentage
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) => _buildProgressBar(_progressController.value),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Telemetry chips
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) => _buildTelemetryChips(_progressController.value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Optional close / cancel button
              if (widget.onCancel != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: widget.onCancel,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientBackdrop() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final pulse = _pulseController.value;
          return Stack(
            children: [
              // Top right amber glow
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mangoAmber.withValues(alpha: 0.12 + pulse * 0.05),
                  ),
                ),
              ),
              // Bottom left emerald green glow
              Positioned(
                bottom: -60,
                left: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mangoGreenAccent
                        .withValues(alpha: 0.10 + pulse * 0.05),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.mangoAmber.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mangoAmber.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.mangoAmber,
              boxShadow: [
                BoxShadow(
                  color: AppColors.mangoAmber.withValues(alpha: 0.8),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'AI NEURAL RIPENESS SCANNER',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.mangoAmberLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolographicScanner() {
    return SizedBox(
      width: _scannerSize + 40,
      height: _scannerSize + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsating radar wave ripples
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) => CustomPaint(
                size: const Size(_scannerSize + 40, _scannerSize + 40),
                painter: _RadarWavePainter(pulse: _pulseController.value),
              ),
            ),
          ),

          // Outer rotating tech dashed ring.
          // The ring is a `child` of the AnimatedBuilder, so it is built once
          // and only the parent transform is re-composited while spinning.
          AnimatedBuilder(
            animation: _rotationController,
            child: RepaintBoundary(
              child: CustomPaint(
                size: const Size(_scannerSize + 24, _scannerSize + 24),
                painter: const _TechRingPainter(
                  color: AppColors.mangoAmber,
                  dashCount: 24,
                ),
              ),
            ),
            builder: (context, ring) => Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: ring,
            ),
          ),

          // Inner counter-rotating segmented ring
          AnimatedBuilder(
            animation: _rotationController,
            child: RepaintBoundary(
              child: CustomPaint(
                size: const Size(_scannerSize + 6, _scannerSize + 6),
                painter: const _SegmentedArcPainter(color: AppColors.mangoGreenAccent),
              ),
            ),
            builder: (context, arcs) => Transform.rotate(
              angle: -_rotationController.value * 2 * math.pi * 1.5,
              child: arcs,
            ),
          ),

          // Target bounding box container.
          //
          // The viewport contents are handed to the AnimatedBuilder as its
          // `child`, so they are constructed once and reused verbatim. Only the
          // border/glow decoration is rebuilt per frame, and the contents sit
          // behind a RepaintBoundary so they are neither rebuilt nor
          // re-rasterized while the border pulses.
          AnimatedBuilder(
            animation: _pulseController,
            child: RepaintBoundary(child: _buildScannerViewport()),
            builder: (context, viewport) {
              final pulse = _pulseController.value;
              return Container(
                width: _viewportSize,
                height: _viewportSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: AppColors.bgCard.withValues(alpha: 0.85),
                  border: Border.all(
                    color: AppColors.mangoAmber.withValues(alpha: 0.4 + pulse * 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mangoAmber.withValues(alpha: 0.2 + pulse * 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: viewport,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScannerViewport() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Mango Image or Fallback Graphic
          RepaintBoundary(child: _buildScannerImage()),

          // Holographic mesh / dark tint overlay
          RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.mangoGreen.withValues(alpha: 0.15),
                    Colors.transparent,
                    AppColors.mangoAmber.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),

          // High-tech corner targeting brackets
          RepaintBoundary(
            child: CustomPaint(
              painter: _CornerBracketsPainter(
                color: AppColors.mangoAmberLight,
                bracketLength: 18,
                thickness: 2.5,
              ),
            ),
          ),

          // Sweeping laser scanner line
          RepaintBoundary(child: _buildLaserBeam()),

          // AI Detection targeting markers / crosshairs
          RepaintBoundary(child: _buildTargetMarkers()),
        ],
      ),
    );
  }

  Widget _buildScannerImage() {
    final bytes = widget.imageBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
    }
    return _buildFallbackMangoGraphic();
  }

  Widget _buildFallbackMangoGraphic() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.mangoAmber.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Text(
              '🥭',
              style: TextStyle(fontSize: 68),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PROCESSING TENSOR',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// Sweeping beam. The blurred beam is painted once and only translated, so
  /// the (expensive) shadow blur is not re-rasterized on every frame.
  Widget _buildLaserBeam() {
    final travel = _viewportSize - _beamHeight;
    return AnimatedBuilder(
      animation: _laserController,
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing beam gradient trail
            Container(
              height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.mangoAmber.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
            // Sharp laser horizontal bar
            Container(
              height: 2.5,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.mangoAmberLight,
                    Colors.white,
                    AppColors.mangoAmberLight,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mangoAmber.withValues(alpha: 0.9),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      builder: (context, beam) => Transform.translate(
        offset: Offset(0, _laserController.value * travel),
        child: beam!,
      ),
    );
  }

  Widget _buildTargetMarkers() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;
        return Stack(
          children: [
            Positioned(
              top: 30,
              right: 25,
              child: _buildMarkerChip('HSV: 42°', pulse),
            ),
            Positioned(
              bottom: 30,
              left: 25,
              child: _buildMarkerChip('Brix: Calc...', 1.0 - pulse),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarkerChip(String text, double pulse) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.mangoGreenAccent.withValues(alpha: 0.4 + pulse * 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.mangoGreenAccent,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseInfo(_AnalysisPhase phase) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              phase.icon,
              size: 20,
              color: AppColors.mangoAmber,
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.2),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                phase.title,
                key: ValueKey(phase.title),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            phase.subtitle,
            key: ValueKey(phase.subtitle),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    final pct = (progress * 100).clamp(0, 100).toInt();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Analyzing ripeness markers...',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            Text(
              '$pct%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.mangoAmber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.01, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.mangoGreenAccent,
                    AppColors.mangoAmber,
                    AppColors.mangoOrange,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mangoAmber.withValues(alpha: 0.6),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryChips(double progress) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildMiniBadge(
          icon: Icons.grid_view_rounded,
          text: '224x224 Tensor',
          active: progress > 0.1,
        ),
        _buildMiniBadge(
          icon: Icons.memory_rounded,
          text: 'TFLite Model',
          active: progress > 0.45,
        ),
        _buildMiniBadge(
          icon: Icons.auto_graph_rounded,
          text: 'Brix & Ripeness',
          active: progress > 0.75,
        ),
      ],
    );
  }

  Widget _buildMiniBadge({
    required IconData icon,
    required String text,
    required bool active,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? AppColors.mangoAmber.withValues(alpha: 0.12)
            : AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppColors.mangoAmber.withValues(alpha: 0.35)
              : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: active ? AppColors.mangoAmberLight : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: active ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisPhase {
  final String title;
  final String subtitle;
  final IconData icon;
  final double rangeStart;
  final double rangeEnd;

  const _AnalysisPhase({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.rangeStart,
    required this.rangeEnd,
  });
}

/// Custom painter for tech dashed rings
class _TechRingPainter extends CustomPainter {
  final Color color;
  final int dashCount;

  const _TechRingPainter({
    required this.color,
    this.dashCount = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepAngle = (2 * math.pi) / dashCount;
    final arcLength = sweepAngle * 0.6;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * sweepAngle, arcLength, false, paint);
    }
  }

  @override
  bool shouldRepaint(_TechRingPainter oldDelegate) => color != oldDelegate.color;
}

/// Custom painter for segmented tech arcs
class _SegmentedArcPainter extends CustomPainter {
  final Color color;

  const _SegmentedArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw 3 prominent segmented curved brackets
    canvas.drawArc(rect, 0, math.pi * 0.35, false, paint);
    canvas.drawArc(rect, math.pi * 0.7, math.pi * 0.35, false, paint);
    canvas.drawArc(rect, math.pi * 1.4, math.pi * 0.35, false, paint);

    // Draw small dot anchors
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final angle = i * (math.pi * 2 / 3);
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_SegmentedArcPainter oldDelegate) => color != oldDelegate.color;
}

/// Custom painter for pulsating radar wave ripples
class _RadarWavePainter extends CustomPainter {
  final double pulse;

  const _RadarWavePainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width - 30) / 2;

    // 2 expanding wave rings
    for (int i = 0; i < 2; i++) {
      final offsetPulse = (pulse + (i * 0.5)) % 1.0;
      final currentRadius = baseRadius + (offsetPulse * 18);
      final alpha = ((1.0 - offsetPulse) * 0.25).clamp(0.0, 1.0);

      final wavePaint = Paint()
        ..color = AppColors.mangoAmber.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(center, currentRadius, wavePaint);
    }
  }

  @override
  bool shouldRepaint(_RadarWavePainter oldDelegate) => pulse != oldDelegate.pulse;
}

/// Custom painter for corner holographic brackets
class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double bracketLength;
  final double thickness;

  const _CornerBracketsPainter({
    required this.color,
    this.bracketLength = 16,
    this.thickness = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    const pad = 6.0;

    // Top-Left
    canvas.drawLine(const Offset(pad, pad + 16), const Offset(pad, pad), paint);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad + 16, pad), paint);

    // Top-Right
    canvas.drawLine(Offset(w - pad - 16, pad), Offset(w - pad, pad), paint);
    canvas.drawLine(Offset(w - pad, pad), Offset(w - pad, pad + 16), paint);

    // Bottom-Left
    canvas.drawLine(Offset(pad, h - pad - 16), Offset(pad, h - pad), paint);
    canvas.drawLine(Offset(pad, h - pad), Offset(pad + 16, h - pad), paint);

    // Bottom-Right
    canvas.drawLine(Offset(w - pad - 16, h - pad), Offset(w - pad, h - pad), paint);
    canvas.drawLine(Offset(w - pad, h - pad), Offset(w - pad, h - pad - 16), paint);
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter oldDelegate) =>
      color != oldDelegate.color ||
      bracketLength != oldDelegate.bracketLength ||
      thickness != oldDelegate.thickness;
}
