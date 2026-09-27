import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mango_ripe/core/theme/app_colors.dart';
import 'package:mango_ripe/core/constants/app_constants.dart';
import 'package:mango_ripe/core/widgets/app_thumbnail.dart';
import 'package:mango_ripe/data/models/scan_result.dart';
import 'package:mango_ripe/data/providers/app_providers.dart';
import 'package:mango_ripe/features/scan/camera_scan_screen.dart';
import 'package:mango_ripe/features/results/results_screen.dart';
import 'package:mango_ripe/features/history/history_screen.dart';
import 'package:mango_ripe/core/utils/image_utils.dart';
import 'package:mango_ripe/widgets/mango_analyzing_overlay.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedGalleryBytes;

  Color _ripeLabelColor(String label) {
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

  String _ripeEmoji(String label) {
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

  Future<void> _pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      // 1. Immediately activate loading overlay so UI responds with zero lag
      ref.read(isProcessingProvider.notifier).state = true;

      // 2. Read bytes and immediately show preview
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedGalleryBytes = bytes;
        });
      }

      // 3. Fast non-blocking center crop
      final cropped = await ImageUtils.centerCropAsync(bytes);
      if (mounted) {
        setState(() {
          _selectedGalleryBytes = cropped;
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
        ref.read(isProcessingProvider.notifier).state = false;
        ref.read(currentScanResultProvider.notifier).state = result;
        setState(() {
          _selectedGalleryBytes = null;
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResultsScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(isProcessingProvider.notifier).state = false;
        setState(() {
          _selectedGalleryBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.overripeColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(scanHistoryProvider);
    final isProcessing = ref.watch(isProcessingProvider);
    final mlInit = ref.watch(mlInitializedProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.bgDark,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroHeader(mlInit),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildStatsRow(history),
                    const SizedBox(height: 24),
                    _buildRecentScansHeader(history),
                    const SizedBox(height: 12),
                    if (history.isEmpty) _buildEmptyHistory(),
                    ...history.take(5).map((s) => _buildHistoryItem(s)),
                    if (history.length > 5)
                      Center(
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          ),
                          icon: const Icon(
                            Icons.history_rounded,
                            color: AppColors.mangoAmber,
                          ),
                          label: Text(
                            'View all ${history.length} scans',
                            style: GoogleFonts.poppins(
                              color: AppColors.mangoAmber,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildTipsCard(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
          if (isProcessing)
            Positioned.fill(
              child: MangoAnalyzingOverlay(
                imageBytes: _selectedGalleryBytes,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(AsyncValue<bool> mlInit) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.mangoAmber.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mangoAmber.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MangoAI',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mangoAmber,
                            ),
                          ),
                          Text(
                            'Ripeness Detector',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      mlInit.when(
                        data: (loaded) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: loaded
                                ? AppColors.unripeColor.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: loaded
                                  ? AppColors.unripeColor
                                  : Colors.orange,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: loaded
                                    ? AppColors.mangoGreenAccent
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                loaded ? 'AI Ready' : 'AI Offline (Demo)',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: loaded
                                      ? AppColors.mangoGreenAccent
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        loading: () => const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.mangoAmber,
                          ),
                        ),
                        error: (_, __) => const SizedBox(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.history_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Good ${_greeting()},',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white60),
              ),
              Text(
                'Ready to scan a mango?',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.camera_alt_rounded,
            label: 'Live Camera\nScan',
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF33691E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CameraScanScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.photo_library_rounded,
            label: 'Upload from\nGallery',
            gradient: const LinearGradient(
              colors: [Color(0xFF3A2000), Color(0xFFE65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: _pickFromGallery,
          ),
        ),
      ],
    ).animate().slideY(begin: 0.2, delay: 100.ms).fadeIn();
  }

  Widget _buildStatsRow(List<ScanResult> history) {
    final counts = <String, int>{};
    for (final s in history) {
      counts[s.label] = (counts[s.label] ?? 0) + 1;
    }

    return Row(
      children: [
        _StatChip(
          label: 'Total',
          value: history.length.toString(),
          color: AppColors.mangoAmber,
        ),
        const SizedBox(width: 8),
        _StatChip(
          label: 'Ripe',
          value: (counts['Fully Ripe'] ?? 0).toString(),
          color: AppColors.ripeColor,
        ),
        const SizedBox(width: 8),
        _StatChip(
          label: 'Unripe',
          value: (counts['Unripe'] ?? 0).toString(),
          color: AppColors.unripeColor,
        ),
        const SizedBox(width: 8),
        _StatChip(
          label: 'Overripe',
          value: (counts['Overripe'] ?? 0).toString(),
          color: AppColors.overripeColor,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildRecentScansHeader(List<ScanResult> history) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Scans',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (history.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
            child: Text(
              'See All',
              style: GoogleFonts.poppins(
                color: AppColors.mangoAmber,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Text('🥭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No scans yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan your first mango to view analysis and history!',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().scale(
          delay: 300.ms,
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildHistoryItem(ScanResult scan) {
    final color = _ripeLabelColor(scan.label);
    final emoji = _ripeEmoji(scan.label);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color.withValues(alpha: 0.15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AppThumbnail(
                imagePath: scan.imagePath,
                fallbackEmoji: emoji,
                emojiSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(scan.timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(scan.confidence * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2A1A), Color(0xFF0F1A0F)],
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
                'Storage & Ripening Tips',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...AppConstants.storageTips.take(3).map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: AppColors.mangoGreenAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tip,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
