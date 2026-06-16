import 'package:flutter/material.dart';

import '../../data/onboarding_content.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';

class OnboardingImageCard extends StatelessWidget {
  final OnboardingPageData page;

  const OnboardingImageCard({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final imageHeight = (context.screenWidth * 0.55).clamp(200.0, 280.0);
    final borderRadius = context.scale(16);

    return Container(
      height: imageHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              page.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primaryContainer,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_outlined,
                  size: context.scale(48),
                  color: AppColors.primary,
                ),
              ),
            ),
            ...page.overlays.map(
              (overlay) => Positioned.fill(
                child: Align(
                  alignment: overlay.alignment,
                  child: Padding(
                    padding: EdgeInsets.all(context.scale(12)),
                    child: _OverlayWidget(type: overlay.type),
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

class _OverlayWidget extends StatelessWidget {
  final OnboardingOverlayType type;

  const _OverlayWidget({required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case OnboardingOverlayType.locationPill:
        return _OverlayPill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: context.scale(14),
                color: AppColors.primary,
              ),
              SizedBox(width: context.scale(4)),
              Text(
                '2.4km',
                style: TextStyle(
                  fontSize: context.scale(12),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      case OnboardingOverlayType.availabilityCard:
        return _OverlayCard(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.scale(28),
                height: context.scale(28),
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication_outlined,
                  size: context.scale(16),
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: context.scale(8)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Available',
                    style: TextStyle(
                      fontSize: context.scale(11),
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    '12 Pharmacies',
                    style: TextStyle(
                      fontSize: context.scale(12),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case OnboardingOverlayType.confirmedCard:
        return _OverlayCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CONFIRMED',
                style: TextStyle(
                  fontSize: context.scale(10),
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: context.scale(2)),
              Text(
                'Code: MC-8829',
                style: TextStyle(
                  fontSize: context.scale(13),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      case OnboardingOverlayType.discountPill:
        return _OverlayPill(
          child: Text(
            '15% Discount Applied',
            style: TextStyle(
              fontSize: context.scale(11),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        );
    }
  }
}

class _OverlayPill extends StatelessWidget {
  final Widget child;

  const _OverlayPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.scale(10),
        vertical: context.scale(6),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.scale(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OverlayCard extends StatelessWidget {
  final Widget child;

  const _OverlayCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.scale(10),
        vertical: context.scale(8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.scale(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
