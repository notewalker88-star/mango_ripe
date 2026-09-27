import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mango_ripe/core/theme/app_colors.dart';

/// Highly visual and interactive loading animation overlay for mango ripeness analysis.
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
    this.totalDuration = const Duration(milliseconds: 2200),
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
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _rotationController,
            _laserController,
            _pulseController,
            _progressController,
          ]),
          builder: (context, _) {
            final progress = _progressController.value;
            final currentPhase = _getCurrentPhase(progress);

            return Stack(
              children: [
                // Ambient background glows
                Positioned.fill(
                  child: _buildAmbientBackdrop(),
                ),

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
                        _buildTopBadge(progress),

                        const SizedBox(height: 24),

                        // Center holographic scanner
                        _buildHolographicScanner(),

                        const SizedBox(height: 32),

                        // Phase title & subtitle
                        _buildPhaseInfo(currentPhase),

                        const SizedBox(height: 20),

                        // Animated progress bar & percentage
                        _buildProgressBar(progress),

                        const SizedBox(height: 24),

                        // Telemetry chips
                        _buildTelemetryChips(progress),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildAmbientBackdrop() {
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
              color: AppColors.mangoGreenAccent.withValues(alpha: 0.10 + pulse * 0.05),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBadge(double progress) {
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
    const size = 230.0;
    final pulse = _pulseController.value;
    final rotation = _rotationController.value * 2 * math.pi;

    return SizedBox(
      width: size + 40,
      height: size + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsating radar wave ripples
          CustomPaint(
            size: const Size(size + 40, size + 40),
            painter: _RadarWavePainter(pulse: pulse),
          ),

          // Outer rotating tech dashed ring
          Transform.rotate(
            angle: rotation,
            child: CustomPaint(
              size: const Size(size + 24, size + 24),
              painter: _TechRingPainter(
                color: AppColors.mangoAmber.withValues(alpha: 0.5),
                isDashed: true,
                dashCount: 24,
              ),
            ),
          ),

          // Inner counter-rotating segmented ring
          Transform.rotate(
            angle: -rotation * 1.5,
            child: CustomPaint(
              size: const Size(size + 6, size + 6),
              painter: _SegmentedArcPainter(
                color: AppColors.mangoGreenAccent.withValues(alpha: 0.6),
              ),
            ),
          ),

          // Target bounding box container
          Container(
            width: size - 20,
            height: size - 20,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Mango Image or Fallback Graphic
                  if (widget.imageBytes != null && widget.imageBytes!.isNotEmpty)
                    Image.memory(
                      widget.imageBytes!,
                      fit: BoxFit.cover,
                    )
                  else
                    _buildFallbackMangoGraphic(),

                  // Holographic mesh / dark tint overlay
                  Container(
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

                  // High-tech corner targeting brackets
                  CustomPaint(
                    painter: _CornerBracketsPainter(
                      color: AppColors.mangoAmberLight,
                      bracketLength: 18,
                      thickness: 2.5,
                    ),
                  ),

                  // Sweeping laser scanner line
                  _buildLaserBeam(size - 20),

                  // AI Detection targeting markers / crosshairs
                  _buildTargetMarkers(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildLaserBeam(double containerHeight) {
    final laserPos = _laserController.value * (containerHeight - 10);

    return Positioned(
      top: laserPos,
      left: 0,
      right: 0,
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
    );
  }

  Widget _buildTargetMarkers() {
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMiniBadge(
          icon: Icons.grid_view_rounded,
          text: '224x224 Tensor',
          active: progress > 0.1,
        ),
        const SizedBox(width: 8),
        _buildMiniBadge(
          icon: Icons.memory_rounded,
          text: 'TFLite Model',
          active: progress > 0.45,
        ),
        const SizedBox(width: 8),
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
  final bool isDashed;
  final int dashCount;

  const _TechRingPainter({
    required this.color,
    this.isDashed = true,
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

    if (!isDashed) {
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final sweepAngle = (2 * math.pi) / dashCount;
    final arcLength = sweepAngle * 0.6;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * sweepAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        arcLength,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TechRingPainter oldDelegate) =>
      color != oldDelegate.color || isDashed != oldDelegate.isDashed;
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
