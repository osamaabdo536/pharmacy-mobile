import 'package:equatable/equatable.dart';

import '../data/models/notification_model.dart';

class NotificationSection extends Equatable {
  final String label;
  final List<NotificationModel> items;

  const NotificationSection({required this.label, required this.items});

  @override
  List<Object?> get props => [label, items];
}

class NotificationsState extends Equatable {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final bool isMarkingAll;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.isMarkingAll = false,
    this.error,
  });

  bool get hasUnread =>
      notifications.any((notification) => notification.isUnread);

  List<NotificationSection> get sections {
    final now = DateTime.now();
    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final earlier = <NotificationModel>[];

    for (final notification in notifications) {
      final created = notification.createdAt.toLocal();
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(created.year, created.month, created.day))
          .inDays;

      if (diff == 0) {
        today.add(notification);
      } else if (diff == 1) {
        yesterday.add(notification);
      } else {
        earlier.add(notification);
      }
    }

    final result = <NotificationSection>[];
    if (today.isNotEmpty) {
      result.add(NotificationSection(label: 'Today', items: today));
    }
    if (yesterday.isNotEmpty) {
      result.add(NotificationSection(label: 'Yesterday', items: yesterday));
    }
    if (earlier.isNotEmpty) {
      result.add(NotificationSection(label: 'Earlier this week', items: earlier));
    }
    return result;
  }

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    bool? isMarkingAll,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isMarkingAll: isMarkingAll ?? this.isMarkingAll,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        isLoading,
        isMarkingAll,
        error,
      ];
}

