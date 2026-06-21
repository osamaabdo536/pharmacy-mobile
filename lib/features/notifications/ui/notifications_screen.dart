import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/responsive.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../data/notifications_repository.dart';
import 'widgets/notification_card.dart';

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
          backgroundColor: AppColors.surfaceVariant,
          appBar: _NotificationsAppBar(onBack: () => context.pop()),
          body: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.isLoading && state.notifications.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.notifications.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  ..._buildSections(context, state, cubit),
                SliverToBoxAdapter(child: SizedBox(height: context.scale(24))),
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
    NotificationsCubit cubit,
  ) {
    final sections = state.sections;
    final widgets = <Widget>[];

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final isFirst = i == 0;

      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.pagePadding,
              context.scale(20),
              context.pagePadding,
              context.scale(10),
            ),
            child: Row(
              children: [
                Text(
                  section.label,
                  style: TextStyle(
                    fontSize: context.scale(11),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                if (isFirst && state.hasUnread)
                  _MarkAllAsReadButton(
                    isLoading: state.isMarkingAll,
                    onPressed: cubit.markAllAsRead,
                  ),
              ],
            ),
          ),
        ),
      );

      widgets.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
          sliver: SliverList.separated(
            itemCount: section.items.length,
            separatorBuilder: (_, __) => SizedBox(height: context.scale(12)),
            itemBuilder: (context, index) {
              return NotificationCard(notification: section.items[index]);
            },
          ),
        ),
      );
    }

    return widgets;
  }
}

class _NotificationsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;

  const _NotificationsAppBar({required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: onBack,
          icon: Icon(Icons.arrow_back)
        ),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications,
            color: AppColors.primary,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.border, height: 1),
      ),
    );
  }
}

class _MarkAllAsReadButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _MarkAllAsReadButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: context.scale(16),
        height: context.scale(16),
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return GestureDetector(
      onTap: onPressed,
      child: Text(
        'Mark all as read',
        style: TextStyle(
          fontSize: context.scale(12),
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
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
