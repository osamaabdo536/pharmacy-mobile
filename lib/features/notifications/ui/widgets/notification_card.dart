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
