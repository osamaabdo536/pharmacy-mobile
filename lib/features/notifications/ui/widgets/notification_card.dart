import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../cubit/notifications_cubit.dart';
import '../../data/models/notification_model.dart';
import 'notification_time_utils.dart';
import 'notification_type_icon.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final iconType = notificationIconTypeFrom(notification.type);
    final timeLabel = formatRelativeTime(notification.createdAt);
    final primaryAction = notification.primaryActionLabel;
    final secondaryAction = notification.secondaryActionLabel;
    final hasActions = primaryAction != null || secondaryAction != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _markReadIfNeeded(context),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.all(context.scale(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NotificationTypeIcon(type: iconType),
                SizedBox(width: context.scale(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.scale(15),
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(width: context.scale(6)),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: context.scale(11),
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          _MoreMenu(notification: notification),
                        ],
                      ),
                      SizedBox(height: context.scale(8)),
                      Text(
                        notification.body,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.scale(13),
                          color: AppColors.textSecondary,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (hasActions) ...[
                        SizedBox(height: context.scale(14)),
                        _ActionRow(
                          primaryLabel: primaryAction,
                          secondaryLabel: secondaryAction,
                          primaryIsOutlined: notification.primaryActionIsOutlined,
                          onPrimary: () => _onPrimaryAction(context),
                          onSecondary: () => _onSecondaryAction(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _markReadIfNeeded(BuildContext context) {
    if (notification.isUnread) {
      context.read<NotificationsCubit>().markAsRead(notification.id);
    }
  }

  void _onPrimaryAction(BuildContext context) {
    _markReadIfNeeded(context);
  }

  void _onSecondaryAction(BuildContext context) {
    _markReadIfNeeded(context);
  }
}

class _ActionRow extends StatelessWidget {
  final String? primaryLabel;
  final String? secondaryLabel;
  final bool primaryIsOutlined;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _ActionRow({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.primaryIsOutlined,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    if (primaryLabel != null && secondaryLabel == null) {
      return _ActionButton(
        label: primaryLabel!,
        isPrimary: !primaryIsOutlined,
        icon: primaryIsOutlined ? null : Icons.autorenew,
        onPressed: onPrimary,
        fullWidth: true,
      );
    }

    if (secondaryLabel != null && primaryLabel == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _ActionButton(
          label: secondaryLabel!,
          isPrimary: false,
          onPressed: onSecondary,
          fullWidth: false,
        ),
      );
    }

    return Row(
      children: [
        if (primaryLabel != null)
          Expanded(
            child: _ActionButton(
              label: primaryLabel!,
              isPrimary: true,
              icon: Icons.autorenew,
              onPressed: onPrimary,
              fullWidth: true,
            ),
          ),
        if (primaryLabel != null && secondaryLabel != null)
          SizedBox(width: context.scale(8)),
        if (secondaryLabel != null)
          Expanded(
            child: _ActionButton(
              label: secondaryLabel!,
              isPrimary: false,
              onPressed: onSecondary,
              fullWidth: true,
            ),
          ),
      ],
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final NotificationModel notification;

  const _MoreMenu({required this.notification});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 140),
      icon: Icon(
        Icons.more_horiz,
        size: context.scale(20),
        color: AppColors.textHint,
      ),
      onSelected: (value) {
        if (value == 'read' && notification.isUnread) {
          context.read<NotificationsCubit>().markAsRead(notification.id);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'read',
          enabled: notification.isUnread,
          child: Text(
            notification.isUnread ? 'Mark as read' : 'Already read',
            style: TextStyle(
              color: notification.isUnread
                  ? AppColors.textPrimary
                  : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool fullWidth;
  final IconData? icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final height = context.scale(38);
    final textStyle = TextStyle(
      fontSize: context.scale(13),
      fontWeight: FontWeight.w600,
    );

    Widget button;
    if (isPrimary) {
      button = FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size(fullWidth ? double.infinity : 0, height),
          padding: EdgeInsets.symmetric(horizontal: context.scale(16)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textStyle,
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            if (icon != null) ...[
              SizedBox(width: context.scale(6)),
              Icon(icon, size: context.scale(15)),
            ],
          ],
        ),
      );
    } else {
      button = OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.border),
          minimumSize: Size(fullWidth ? double.infinity : 0, height),
          padding: EdgeInsets.symmetric(horizontal: context.scale(20)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textStyle,
        ),
        child: Text(label),
      );
    }

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
