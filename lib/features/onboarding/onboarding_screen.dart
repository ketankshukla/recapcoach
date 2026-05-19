import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/analytics/analytics.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass/glass_pill_button.dart';
import '../../core/widgets/glass/gradient_pill_button.dart';
import '../home/widgets/mesh_gradient_background.dart';
import 'onboarding_provider.dart';

/// Glass-themed onboarding carousel.
///
/// Three RecapCoach-specific pages -- value prop, monetization, privacy
/// -- each with a 132 dp amber-gradient hero disc, a 30 dp display
/// title, and a body paragraph. The carousel sits over
/// `MeshGradientBackground`; the skip button is a floating
/// `GlassPillButton` in the top-right corner; the bottom CTA is the
/// shared `GradientPillButton`.
///
/// On the last page the CTA copy switches to "Get started" and tapping
/// it persists `markComplete()` + routes to `/home`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardData(
      title: 'Recap any call instantly',
      body:
          'Record any conversation and get an AI summary, transcript, '
          'and action items in seconds — so you never miss a follow-up.',
      icon: Icons.graphic_eq_rounded,
    ),
    _OnboardData(
      title: 'Free to start',
      body:
          '5 recordings per month free. Upgrade to Pro any time for '
          '100 recordings + 8 hours of audio every month.',
      icon: Icons.lock_open_rounded,
    ),
    _OnboardData(
      title: 'Private by default',
      body:
          'Your audio lives on your device. We only see what you '
          'choose to transcribe, and you can delete your account any time.',
      icon: Icons.shield_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvents.onboardingStart);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      await _completeAndGoHome();
    }
  }

  Future<void> _skip() async => _completeAndGoHome();

  Future<void> _completeAndGoHome() async {
    await ref.read(onboardingControllerProvider).markComplete();
    if (!mounted) return;
    ref.read(analyticsProvider).track(AnalyticsEvents.onboardingComplete);
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted =
        isDark ? const Color(0xFFD8D4CB) : AppColors.slate500;
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MeshGradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Floating Skip pill in the top-right corner.
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: GlassPillButton(
                  label: 'Skip',
                  onPressed: _skip,
                ),
              ),

              Column(
                children: [
                  const SizedBox(height: 80), // leave room for floating Skip
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) {
                        final p = _pages[i];
                        return _OnboardingPage(
                          data: p,
                          fg: fg,
                          fgMuted: fgMuted,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Page indicator.
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length,
                    effect: const WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: AppColors.amber600,
                      dotColor: Color(0x55A8B0BF),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Primary CTA.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: GradientPillButton(
                      onPressed: _next,
                      label: isLast ? 'Get started' : 'Next',
                      icon: isLast
                          ? Icons.arrow_forward_rounded
                          : null,
                      expanded: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One onboarding page -- amber-gradient hero disc + title + body.
///
/// Each page is centered vertically inside the PageView. The hero
/// disc bloom uses the same amber halo vocabulary as the home FAB +
/// record-screen mic disc so the brand feels consistent before the
/// user has even seen those screens.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.fg,
    required this.fgMuted,
  });

  final _OnboardData data;
  final Color fg;
  final Color fgMuted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _HeroDisc(icon: data.icon),
          const SizedBox(height: AppSpacing.xl),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fgMuted,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDisc extends StatelessWidget {
  const _HeroDisc({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.amber600, AppColors.amber400],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber400.withValues(alpha: 0.40),
            blurRadius: 60,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: AppColors.amber600.withValues(alpha: 0.30),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 60),
    );
  }
}

class _OnboardData {
  const _OnboardData({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}
