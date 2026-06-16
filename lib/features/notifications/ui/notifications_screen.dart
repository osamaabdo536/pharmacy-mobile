import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/responsive.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../data/models/notification_model.dart';
import '../data/notifications_repository.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => NotificationsRepository(),
      child: BlocProvider(
        create: (context) =>
            NotificationsCubit(context.read<NotificationsRepository>())
              ..loadNotifications(),
        child: const _NotificationsView(),
      ),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listenWhen: (previous, current) => previous.error != current.error,
      listener: (context, state) {
        final message = state.error;
        if (message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                context.read<NotificationsCubit>().clearError();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      },
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton(
                onPressed: state.hasUnread && !state.isMarkingAll
                    ? () => cubit.markAllAsRead()
                    : null,
                child: state.isMarkingAll
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                    : const Text('Mark all as read'),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.isLoading && state.notifications.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.notifications.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  ..._buildSections(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSections(
    BuildContext context,
    NotificationsState state,
  ) {
    final sections = state.sections;
    final widgets = <Widget>[];

    for (final section in sections) {
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.pagePadding,
              context.scale(16),
              context.pagePadding,
              context.scale(8),
            ),
            child: Text(
              section.label,
              style: TextStyle(
                fontSize: context.scale(14),
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      );

      widgets.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: context.pagePadding,
          ),
          sliver: SliverList.separated(
            itemCount: section.items.length,
            separatorBuilder: (_, __) => SizedBox(height: context.scale(8)),
            itemBuilder: (context, index) {
              final notification = section.items[index];
              return _NotificationCard(notification: notification);
            },
          ),
        ),
      );
    }

    return widgets;
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.isUnread;
    final created = notification.createdAt.toLocal();
    final timeLabel =
        '${_hourString(created.hour)}:${created.minute.toString().padLeft(2, '0')} ${created.hour >= 12 ? 'PM' : 'AM'}';

    final type = notification.type ?? '';
    final visual = _typeVisual(type);

    return InkWell(
      onTap: () =>
          context.read<NotificationsCubit>().markAsRead(notification.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(context.scale(12)),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: context.scale(36),
              height: context.scale(36),
              decoration: BoxDecoration(
                color: visual.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                visual.icon,
                size: context.scale(18),
                color: visual.color,
              ),
            ),
            SizedBox(width: context.scale(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.scale(14),
                      fontWeight:
                          isUnread ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: context.scale(4)),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.scale(13),
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: context.scale(6)),
                  Row(
                    children: [
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: context.scale(11),
                          color: AppColors.textHint,
                        ),
                      ),
                      if (isUnread) ...[
                        SizedBox(width: context.scale(8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.scale(8),
                            vertical: context.scale(3),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'New',
                            style: TextStyle(
                              fontSize: context.scale(10),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hourString(int hour) {
    final h = hour % 12;
    return (h == 0 ? 12 : h).toString().padLeft(2, '0');
  }

  _NotificationVisual _typeVisual(String type) {
    switch (type) {
      case 'reservation_confirmed':
        return const _NotificationVisual(
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          background: AppColors.successBg,
        );
      case 'reservation_cancelled':
        return const _NotificationVisual(
          icon: Icons.cancel_outlined,
          color: AppColors.error,
          background: AppColors.errorBg,
        );
      case 'promotion':
        return const _NotificationVisual(
          icon: Icons.local_offer_outlined,
          color: AppColors.info,
          background: AppColors.primaryContainer,
        );
      default:
        return const _NotificationVisual(
          icon: Icons.notifications_outlined,
          color: AppColors.primary,
          background: AppColors.primaryContainer,
        );
    }
  }
}

class _NotificationVisual {
  final IconData icon;
  final Color color;
  final Color background;

  const _NotificationVisual({
    required this.icon,
    required this.color,
    required this.background,
  });
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.pagePadding),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: context.scale(40),
              color: AppColors.textSecondary,
            ),
            SizedBox(height: context.scale(12)),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: context.scale(16),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: context.scale(6)),
            Text(
              'You will see important updates about your reservations and offers here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.scale(13),
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
