import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mango_ripe/core/theme/app_colors.dart';
import 'package:mango_ripe/core/widgets/app_thumbnail.dart';
import 'package:mango_ripe/data/models/scan_result.dart';
import 'package:mango_ripe/data/providers/app_providers.dart';
import 'package:mango_ripe/features/results/results_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  ScanFilter _selectedFilter = ScanFilter.all;

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

  List<ScanResult> _filteredScans(List<ScanResult> scans) {
    switch (_selectedFilter) {
      case ScanFilter.unripe:
        return scans.where((s) => s.label == 'Unripe').toList();
      case ScanFilter.partiallyRipe:
        return scans.where((s) => s.label == 'Partially Ripe').toList();
      case ScanFilter.ripe:
        return scans.where((s) => s.label == 'Fully Ripe').toList();
      case ScanFilter.overripe:
        return scans.where((s) => s.label == 'Overripe').toList();
      default:
        return scans;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allScans = ref.watch(scanHistoryProvider);
    final filtered = _filteredScans(allScans);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Column(
          children: [
            Text(
              'Scan History',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${allScans.length} total saved scans',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (allScans.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.overripeColor,
              ),
              onPressed: _showClearDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          const SizedBox(height: 4),
          if (filtered.isEmpty)
            Expanded(child: _buildEmptyState())
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _buildHistoryCard(filtered[i], i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      (ScanFilter.all, '✨ All', AppColors.mangoAmber),
      (ScanFilter.unripe, '🥑 Unripe', AppColors.unripeColor),
      (ScanFilter.partiallyRipe, '🍋 Partial', AppColors.partiallyRipeColor),
      (ScanFilter.ripe, '🥭 Ripe', AppColors.ripeColor),
      (ScanFilter.overripe, '🍯 Overripe', AppColors.overripeColor),
    ];

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final (filter, label, color) = filters[i];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(ScanResult scan, int index) {
    final color = _ripeLabelColor(scan.label);
    final emoji = _ripeEmoji(scan.label);
    return Dismissible(
      key: Key(scan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.overripeColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.overripeColor),
      ),
      onDismissed: (_) async {
        await ref.read(scanHistoryProvider.notifier).deleteScan(scan.id);
      },
      child: GestureDetector(
        onTap: () {
          ref.read(currentScanResultProvider.notifier).state = scan;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResultsScreen()),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AppThumbnail(
                    imagePath: scan.imagePath,
                    fallbackEmoji: emoji,
                    emojiSize: 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            scan.label,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(scan.confidence * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('EEE, MMM dd yyyy').format(scan.timestamp),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(scan.timestamp),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shelf life: ${scan.shelfLife}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 40)).slideX(begin: 0.1);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🥭', style: TextStyle(fontSize: 64))
              .animate()
              .scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'No scans found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == ScanFilter.all
                ? 'Start scanning mangoes to build your history log'
                : 'No ${_selectedFilter.name} mangoes found in history',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear All History?',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This action cannot be undone. All saved mango scans will be removed.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(scanHistoryProvider.notifier).clearAll();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.overripeColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
