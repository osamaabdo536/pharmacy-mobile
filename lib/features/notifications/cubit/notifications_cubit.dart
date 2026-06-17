import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/notification_model.dart';
import '../data/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationsRepository _repository;

  Future<void> loadNotifications() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _repository.getMyNotifications();
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
      ),
      (notifications) {
        final sorted = List<NotificationModel>.from(notifications)
          ..sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );
        emit(
          state.copyWith(
            notifications: sorted,
            isLoading: false,
          ),
        );
      },
    );
  }

  Future<void> refresh() async {
    final result = await _repository.getMyNotifications();
    result.fold(
      (failure) => emit(
        state.copyWith(
          error: failure.message,
        ),
      ),
      (notifications) {
        final sorted = List<NotificationModel>.from(notifications)
          ..sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );
        emit(
          state.copyWith(
            notifications: sorted,
            isLoading: false,
          ),
        );
      },
    );
  }

  Future<void> markAsRead(String id) async {
    final index =
        state.notifications.indexWhere((notification) => notification.id == id);
    if (index == -1) return;

    final original = state.notifications[index];
    if (original.isRead) return;

    final updatedList = List<NotificationModel>.from(state.notifications);
    updatedList[index] = NotificationModel(
      id: original.id,
      title: original.title,
      body: original.body,
      createdAt: original.createdAt,
      isRead: true,
      type: original.type,
    );

    emit(state.copyWith(notifications: updatedList, clearError: true));

    final result = await _repository.markNotificationRead(id);
    result.fold(
      (failure) {
        // Revert on failure.
        final reverted = List<NotificationModel>.from(updatedList);
        reverted[index] = original;
        emit(
          state.copyWith(
            notifications: reverted,
            error: failure.message,
          ),
        );
      },
      (_) {},
    );
  }

  Future<void> markAllAsRead() async {
    if (!state.hasUnread || state.isMarkingAll) return;

    final original = state.notifications;
    final updated = original
        .map(
          (notification) => NotificationModel(
            id: notification.id,
            title: notification.title,
            body: notification.body,
            createdAt: notification.createdAt,
            isRead: true,
            type: notification.type,
          ),
        )
        .toList();

    emit(
      state.copyWith(
        notifications: updated,
        isMarkingAll: true,
        clearError: true,
      ),
    );

    final ids = original
        .where((notification) => notification.isUnread)
        .map((notification) => notification.id)
        .toList();

    final result = await _repository.markAllRead(ids);
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            notifications: original,
            isMarkingAll: false,
            error: failure.message,
          ),
        );
      },
      (_) {
        emit(
          state.copyWith(
            isMarkingAll: false,
          ),
        );
      },
    );
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}

