import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';

enum NotificationIconType {
  warning,
  success,
  identity,
  error,
  promotion,
  defaultType,
}

NotificationIconType notificationIconTypeFrom(String? type) {
  switch (type) {
    case 'medication_expiring':
    case 'prescription_expiring':
      return NotificationIconType.warning;
    case 'reservation_confirmed':
    case 'pickup_confirmed':
      return NotificationIconType.success;
    case 'identity_verified':
      return NotificationIconType.identity;
    case 'reservation_expired':
    case 'reservation_cancelled':
      return NotificationIconType.error;
    case 'promotion':
      return NotificationIconType.promotion;
    default:
      return NotificationIconType.defaultType;
  }
}

class NotificationTypeIcon extends StatelessWidget {
  final NotificationIconType type;

  const NotificationTypeIcon({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final outerSize = context.scale(44);
    final innerSize = context.scale(22);

    switch (type) {
      case NotificationIconType.warning:
        return _CircleIcon(
          size: outerSize,
          background: AppColors.warningBg,
          child: Icon(
            Icons.warning_amber_rounded,
            size: context.scale(22),
            color: const Color(0xFFD97706),
          ),
        );
      case NotificationIconType.success:
        return _CircleIcon(
          size: outerSize,
          background: AppColors.successBg,
          child: Icon(
            Icons.check_circle,
            size: context.scale(22),
            color: AppColors.success,
          ),
        );
      case NotificationIconType.identity:
        return _CircleIcon(
          size: outerSize,
          background: AppColors.successBg,
          child: Icon(
            Icons.verified_user,
            size: context.scale(20),
            color: AppColors.success,
          ),
        );
      case NotificationIconType.error:
        return SizedBox(
          width: outerSize,
          height: outerSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: outerSize,
                height: outerSize,
                decoration: const BoxDecoration(
                  color: AppColors.errorBg,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: innerSize,
                height: innerSize,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: context.scale(14),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      case NotificationIconType.promotion:
        return _CircleIcon(
          size: outerSize,
          background: AppColors.primaryContainer,
          child: Icon(
            Icons.local_offer_outlined,
            size: context.scale(20),
            color: AppColors.info,
          ),
        );
      case NotificationIconType.defaultType:
        return _CircleIcon(
          size: outerSize,
          background: AppColors.primaryContainer,
          child: Icon(
            Icons.notifications_outlined,
            size: context.scale(20),
            color: AppColors.primary,
          ),
        );
    }
  }
}

class _CircleIcon extends StatelessWidget {
  final double size;
  final Color background;
  final Widget child;

  const _CircleIcon({
    required this.size,
    required this.background,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}
