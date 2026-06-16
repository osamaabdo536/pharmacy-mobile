import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';

class OnboardingDots extends StatelessWidget {
  final int pageCount;
  final int currentIndex;

  const OnboardingDots({
    super.key,
    required this.pageCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final activeWidth = context.scale(24);
    final inactiveSize = context.scale(8);
    final height = context.scale(8);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: context.scale(4)),
          width: isActive ? activeWidth : inactiveSize,
          height: height,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        );
      }),
    );
  }
}
