import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mango_ripe/core/theme/app_colors.dart';
import 'package:mango_ripe/features/dashboard/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardPage> _pages = const [
    _OnboardPage(
      emoji: '🥭',
      imageAsset: 'assets/images/app_icon.png',
      title: 'Smart Mango\nRipeness Detection',
      subtitle:
          'Utilize advanced on-device Machine Learning to instantly identify mango ripeness stages with high precision.',
      gradient: [AppColors.mangoGreen, Color(0xFF0A1A0A)],
    ),
    _OnboardPage(
      emoji: '📸',
      title: 'Instant Scan &\nReal-Time AI',
      subtitle:
          'Snap a photo with the live camera or pick from your gallery. Runs 100% offline directly on your device.',
      gradient: [Color(0xFF1A3A00), Color(0xFF0A1A0A)],
    ),
    _OnboardPage(
      emoji: '📊',
      title: 'Actionable Insights &\nShelf Life Advice',
      subtitle:
          'Get scientific shelf-life estimations, storage recommendations, and nutritional profiles for peak flavor.',
      gradient: [Color(0xFF3A2000), Color(0xFF0A1A0A)],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToDashboard();
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (ctx, i) => _buildPage(_pages[i]),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardPage page) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: page.gradient,
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 140,
                height: 140,
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
                child: Center(
                  child: page.imageAsset != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            page.imageAsset!,
                            width: 130,
                            height: 130,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          page.emoji,
                          style: const TextStyle(fontSize: 64),
                        ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  page.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                ).animate().fadeIn(delay: 350.ms),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.bgDark.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Row(
        children: [
          // Dots
          Row(
            children: List.generate(_pages.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive ? AppColors.mangoAmber : Colors.white24,
                ),
              );
            }),
          ),
          const Spacer(),
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _navigateToDashboard,
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _nextPage,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.amberGradient,
              ),
              child: Icon(
                _currentPage == _pages.length - 1
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final String emoji;
  final String? imageAsset;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardPage({
    required this.emoji,
    this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
