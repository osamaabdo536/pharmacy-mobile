import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_colors.dart';
import '../cubit/reservation_cubit.dart';
import '../cubit/reservation_state.dart';
import '../data/models/reservation_model.dart';
import '../data/models/reservation_repository.dart';

enum _ReservationFilter { all, confirmed, pending, cancelled, expired }

class ReservationsListScreen extends StatefulWidget {
  const ReservationsListScreen({super.key});

  @override
  State<ReservationsListScreen> createState() => _ReservationsListScreenState();
}

class _ReservationsListScreenState extends State<ReservationsListScreen> {
  _ReservationFilter _selectedFilter = _ReservationFilter.all;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ReservationCubit(ReservationRepository())..loadReservations(),
      child: BlocConsumer<ReservationCubit, ReservationState>(
        listenWhen: (previous, current) {
          return current is ReservationLoaded && current.actionError != null;
        },
        listener: (context, state) {
          if (state is ReservationLoaded && state.actionError != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionError!)));
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () =>
                context.read<ReservationCubit>().refreshReservations(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Reservations',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FilterTabs(
                          selected: _selectedFilter,
                          onChanged: (filter) {
                            setState(() => _selectedFilter = filter);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                ..._buildBody(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, ReservationState state) {
    if (state is ReservationLoading || state is ReservationInitial) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state is ReservationError) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _StateMessage(
            icon: Icons.error_outline,
            title: 'Could not load reservations',
            message: state.message,
            actionLabel: 'Try Again',
            onAction: () => context.read<ReservationCubit>().loadReservations(),
          ),
        ),
      ];
    }

    final loaded = state as ReservationLoaded;
    final reservations = _filteredReservations(loaded.reservations);

    if (reservations.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _StateMessage(
            icon: Icons.event_available_outlined,
            title: 'No reservations yet',
            message: 'Your medicine reservations will appear here.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        sliver: SliverList.separated(
          itemCount: reservations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final reservation = reservations[index];
            return _ReservationCard(
              reservation: reservation,
              isCancelling: loaded.cancellingId == reservation.id,
              onCancel: reservation.canCancel
                  ? () => _confirmCancel(context, reservation)
                  : null,
            );
          },
        ),
      ),
    ];
  }

  List<ReservationModel> _filteredReservations(
    List<ReservationModel> reservations,
  ) {
    if (_selectedFilter == _ReservationFilter.all) return reservations;

    return reservations.where((reservation) {
      return reservation.normalizedStatus == _selectedFilter.name;
    }).toList();
  }

  Future<void> _confirmCancel(
    BuildContext context,
    ReservationModel reservation,
  ) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel reservation?'),
          content: Text(
            'This will cancel order ${reservation.shortCode} and return the stock to the pharmacy.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Cancel Reservation'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true && context.mounted) {
      await context.read<ReservationCubit>().cancelReservation(reservation.id);
    }
  }
}

class _FilterTabs extends StatelessWidget {
  final _ReservationFilter selected;
  final ValueChanged<_ReservationFilter> onChanged;

  const _FilterTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _ReservationFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _ReservationFilter.values[index];
          final isSelected = selected == filter;
          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(_filterLabel(filter)),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            selectedColor: AppColors.primaryContainer,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppColors.primaryContainer : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onSelected: (_) => onChanged(filter),
          );
        },
      ),
    );
  }

  String _filterLabel(_ReservationFilter filter) {
    switch (filter) {
      case _ReservationFilter.all:
        return 'All Reservations';
      case _ReservationFilter.confirmed:
        return 'Confirmed';
      case _ReservationFilter.pending:
        return 'Pending';
      case _ReservationFilter.cancelled:
        return 'Cancelled';
      case _ReservationFilter.expired:
        return 'Expired';
    }
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final bool isCancelling;
  final VoidCallback? onCancel;

  const _ReservationCard({
    required this.reservation,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(reservation.normalizedStatus);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ORDER ID',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reservation.shortCode,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reservation.pharmacyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: statusStyle.label,
                icon: statusStyle.icon,
                color: statusStyle.color,
                background: statusStyle.background,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetaItem(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDate(reservation.createdAt),
                ),
              ),
              Expanded(
                child: _MetaItem(
                  icon: Icons.access_time,
                  label: _formatTime(reservation.createdAt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetaItem(
                  icon: reservation.normalizedStatus == 'pending'
                      ? Icons.local_shipping_outlined
                      : Icons.shopping_bag_outlined,
                  label: reservation.normalizedStatus == 'pending'
                      ? 'Delivery'
                      : 'Pickup',
                ),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'Total: '),
                      TextSpan(
                        text: '\$${reservation.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              _messageForStatus(reservation),
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (reservation.normalizedStatus == 'pending' &&
              reservation.expiresAt != null) ...[
            const SizedBox(height: 10),
            _ExpiryNotice(expiresAt: reservation.expiresAt!),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: onCancel == null
                    ? AppColors.textSecondary
                    : AppColors.error,
                backgroundColor: onCancel == null
                    ? const Color(0xFFE5E9F0)
                    : Colors.white,
                side: BorderSide(
                  color: onCancel == null
                      ? const Color(0xFFE5E9F0)
                      : AppColors.error,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Cancel Reservation'),
            ),
          ),
        ],
      ),
    );
  }

  String _messageForStatus(ReservationModel reservation) {
    switch (reservation.normalizedStatus) {
      case 'confirmed':
        return 'Your prescription for ${reservation.displayDrug} is ready for collection at the drive-thru window.';
      case 'pending':
        return 'The pharmacist is currently verifying your insurance coverage for this reservation.';
      case 'cancelled':
        return 'This order was cancelled. The reserved stock has been returned to the pharmacy.';
      case 'expired':
        return 'This reservation expired before pickup. The stock has been returned to the pharmacy.';
      default:
        return 'Your reservation details are available here for pharmacy pickup.';
    }
  }
}

class _ExpiryNotice extends StatelessWidget {
  final DateTime expiresAt;

  const _ExpiryNotice({required this.expiresAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.timer_outlined, size: 15, color: AppColors.warning),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Code expires at ${_formatDateTime(expiresAt)}',
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _StatusVisual {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const _StatusVisual({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });
}

_StatusVisual _statusStyle(String status) {
  switch (status) {
    case 'confirmed':
      return const _StatusVisual(
        label: 'CONFIRMED',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        background: AppColors.successBg,
      );
    case 'pending':
      return const _StatusVisual(
        label: 'PENDING',
        icon: Icons.access_time,
        color: AppColors.warning,
        background: AppColors.warningBg,
      );
    case 'cancelled':
      return const _StatusVisual(
        label: 'CANCELLED',
        icon: Icons.cancel_outlined,
        color: AppColors.error,
        background: AppColors.errorBg,
      );
    case 'expired':
      return const _StatusVisual(
        label: 'EXPIRED',
        icon: Icons.timer_off_outlined,
        color: AppColors.error,
        background: AppColors.errorBg,
      );
    default:
      return const _StatusVisual(
        label: 'RESERVED',
        icon: Icons.event_available_outlined,
        color: AppColors.info,
        background: AppColors.primaryContainer,
      );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '--';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

String _formatTime(DateTime? value) {
  if (value == null) return '--';
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _formatDateTime(DateTime value) {
  return '${_formatDate(value)} at ${_formatTime(value)}';
}
