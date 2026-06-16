import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final logoSize = context.scale(32);

    return Row(
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
                size: logoSize * 0.5,
              ),
            ),
          ),
        ),
        SizedBox(width: context.scale(8)),
        Text(
          'Dawak',
          style: TextStyle(
            fontSize: context.scale(18),
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
