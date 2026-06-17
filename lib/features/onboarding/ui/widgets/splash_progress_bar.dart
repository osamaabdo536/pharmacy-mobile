import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';

class SplashProgressBar extends StatelessWidget {
  final double progress;

  const SplashProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final height = context.scale(4, min: 0.9, max: 1.1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.border),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
