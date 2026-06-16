import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/local_storage.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/responsive.dart';
import 'widgets/splash_progress_bar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 1500);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _navigateAfterInit();
  }

  Future<void> _navigateAfterInit() async {
    await _controller.forward();
    if (!mounted) return;

    if (TokenStorage.hasToken()) {
      context.go('/search');
      return;
    }

    if (!OnboardingStorage.hasCompletedOnboarding()) {
      context.go('/onboarding');
      return;
    }

    context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = context.scale(88);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: context.maxContentWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(logoSize / 2),
                        child: Image.asset(
                          'assets/images/Dawak_Icon.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              color: Colors.white,
                              size: logoSize * 0.45,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.scale(16)),
                      Text(
                        'Dawak',
                        style: TextStyle(
                          fontSize: context.scale(28),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    children: [
                      SplashProgressBar(progress: _controller.value),
                      SizedBox(height: context.scale(10)),
                      Text(
                        'INITIALIZING',
                        style: TextStyle(
                          fontSize: context.scale(11),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: context.scale(24)),
            ],
          ),
        ),
      ),
    );
  }
}
