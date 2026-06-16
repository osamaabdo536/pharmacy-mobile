import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/local_storage.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/onboarding_content.dart';
import 'widgets/onboarding_checklist.dart';
import 'widgets/onboarding_dots.dart';
import 'widgets/onboarding_header.dart';
import 'widgets/onboarding_image_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeAndGoLogin() async {
    await OnboardingStorage.setOnboardingCompleted();
    if (!mounted) return;
    context.go('/login');
  }

  void _onPrimaryPressed() {
    final isLastPage = _currentPage >= onboardingPages.length - 1;
    if (isLastPage) {
      _completeAndGoLogin();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: context.scale(16)),
            const OnboardingHeader(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: onboardingPages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(page: onboardingPages[index]);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.pagePadding,
                0,
                context.pagePadding,
                context.scale(8),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: context.maxContentWidth),
                  child: Column(
                    children: [
                      OnboardingDots(
                        pageCount: onboardingPages.length,
                        currentIndex: _currentPage,
                      ),
                      SizedBox(height: context.scale(20)),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AppButton(
                          label: onboardingPages[_currentPage].primaryButtonLabel,
                          onPressed: _onPrimaryPressed,
                        ),
                      ),
                      if (_currentPage == 0) ...[
                        SizedBox(height: context.scale(4)),
                        AppButton(
                          label: 'Skip',
                          variant: AppButtonVariant.text,
                          onPressed: _completeAndGoLogin,
                        ),
                      ] else
                        SizedBox(height: context.scale(48)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingPageData page;

  const _OnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        context.scale(20),
        context.pagePadding,
        context.scale(8),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingImageCard(page: page),
              SizedBox(height: context.scale(24)),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.scale(22),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: context.scale(10)),
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.scale(14),
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: context.scale(20)),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: context.scale(300)),
                  child: OnboardingChecklist(items: page.checklistItems),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
