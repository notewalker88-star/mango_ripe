import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mango_ripe/core/theme/app_colors.dart';
import 'package:mango_ripe/core/constants/app_constants.dart';
import 'package:mango_ripe/core/widgets/app_thumbnail.dart';
import 'package:mango_ripe/data/models/scan_result.dart';
import 'package:mango_ripe/data/providers/app_providers.dart';
import 'package:mango_ripe/features/scan/camera_scan_screen.dart';
import 'package:mango_ripe/features/dashboard/dashboard_screen.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  Color _labelColor(String label) {
    switch (label) {
      case 'Unripe':
        return AppColors.unripeColor;
      case 'Partially Ripe':
        return AppColors.partiallyRipeColor;
      case 'Fully Ripe':
        return AppColors.ripeColor;
      case 'Overripe':
        return AppColors.overripeColor;
      default:
        return AppColors.mangoAmber;
    }
  }

  String _labelEmoji(String label) {
    switch (label) {
      case 'Unripe':
        return '🥑';
      case 'Partially Ripe':
        return '🍋';
      case 'Fully Ripe':
        return '🥭';
      case 'Overripe':
        return '🍯';
      default:
        return '🥭';
    }
  }

  String _labelDescription(String label) {
    switch (label) {
      case 'Unripe':
        return 'Firm texture, higher acidity, low sugar content. Green skin tone.';
      case 'Partially Ripe':
        return 'Transitioning from green to yellow/orange. Semi-sweet with balanced tartness.';
      case 'Fully Ripe':
        return 'Optimal aromatic sweetness, rich juicy golden pulp, peak eating experience!';
      case 'Overripe':
        return 'Soft flesh, deep sugar breakdown, developing brown spots. Use promptly.';
      default:
        return 'Classification analysis completed.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(currentScanResultProvider);
    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: Text(
            'No scan result available',
            style: GoogleFonts.poppins(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final color = _labelColor(result.label);
    final emoji = _labelEmoji(result.label);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, result, color, emoji),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMainResultCard(result, color, emoji),
                const SizedBox(height: 16),
                _buildConfidenceBar(result, color),
                const SizedBox(height: 16),
                _buildAllClassifications(result),
                const SizedBox(height: 16),
                _buildMetricsCard(result, color),
                const SizedBox(height: 16),
                _buildNutritionCard(result, color),
                const SizedBox(height: 16),
                _buildRecommendationCard(result, color, emoji),
                const SizedBox(height: 24),
                _buildActionButtons(context, ref, result),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ScanResult result,
    Color color,
    String emoji,
  ) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.bgDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (r) => false,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.4), AppColors.bgDark],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: AppThumbnail(
                      imagePath: result.imagePath,
                      fallbackEmoji: emoji,
                      emojiSize: 48,
                    ),
                  ),
                ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainResultCard(ScanResult result, Color color, String emoji) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Text(
                'AI Ripeness Classification',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.label,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _labelDescription(result.label),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildConfidenceBar(ScanResult result, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Model Confidence',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: CircularPercentIndicator(
              radius: 65,
              lineWidth: 10,
              percent: result.confidence.clamp(0.0, 1.0),
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(result.confidence * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    'accuracy match',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              progressColor: color,
              backgroundColor: color.withValues(alpha: 0.15),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 1200,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildAllClassifications(ScanResult result) {
    final labels = AppConstants.labels;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ripeness Probability Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(labels.length, (i) {
            final conf = i < result.allConfidences.length
                ? result.allConfidences[i]
                : 0.0;
            final color = _labelColor(labels[i]);
            final isTop = labels[i] == result.label;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        labels[i],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight:
                              isTop ? FontWeight.w600 : FontWeight.w400,
                          color: isTop ? color : AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(conf * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight:
                              isTop ? FontWeight.w600 : FontWeight.w400,
                          color: isTop ? color : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  LinearPercentIndicator(
                    lineHeight: 7,
                    percent: conf.clamp(0.0, 1.0),
                    progressColor: color,
                    backgroundColor: color.withValues(alpha: 0.12),
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                    animation: true,
                    animationDuration: 800,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildMetricsCard(ScanResult result, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ripeness Shelf-Life Metrics',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.schedule_rounded,
                  label: 'Est. Shelf Life',
                  value: result.shelfLife,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.eco_rounded,
                  label: 'Ripeness Stage',
                  value: result.label,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildNutritionCard(ScanResult result, Color color) {
    final nutrition = AppConstants.nutritionMap[result.label] ??
        {
          'Vitamin C': 'Rich in nutrients',
          'Sugar': 'Natural fruit sugars',
        };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🥗', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Nutritional Highlights (${result.label})',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...nutrition.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    e.value,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 220.ms);
  }

  Widget _buildRecommendationCard(
    ScanResult result,
    Color color,
    String emoji,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.bgCardLight, AppColors.bgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Usage & Preparation Advice',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.recommendation,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ScanResult result,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Save to History'),
            onPressed: () async {
              await ref.read(scanHistoryProvider.notifier).addScan(result);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Saved to scan history!',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.mangoGreenAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mangoAmber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Scan Another'),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CameraScanScreen(),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.mangoAmber,
                  side: const BorderSide(color: AppColors.mangoAmber),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Result'),
                onPressed: () {
                  Share.share(
                    '🥭 MangoAI Ripeness Detection Result\n\n'
                    'Stage: ${result.label}\n'
                    'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%\n'
                    'Est. Shelf Life: ${result.shelfLife}\n\n'
                    'Recommendation:\n${result.recommendation}',
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
