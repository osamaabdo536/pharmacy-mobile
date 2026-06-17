import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_colors.dart';
import '../data/models/reservation_model.dart';
import '../data/models/reservation_repository.dart';

class ReservationScreen extends StatefulWidget {
  final String id;

  const ReservationScreen({super.key, required this.id});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final ReservationRepository _repository = ReservationRepository();
  late Future<ReservationModel?> _reservationFuture;
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _reservationFuture = _repository.findReservationById(widget.id);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReservationModel?>(
      future: _reservationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _StateMessage(
            icon: Icons.error_outline,
            title: 'Could not load reservation',
            message: snapshot.error.toString(),
            onRetry: _reload,
          );
        }

        final reservation = snapshot.data;
        if (reservation == null) {
          return _StateMessage(
            icon: Icons.event_busy_outlined,
            title: 'Reservation not found',
            message: 'This reservation could not be found in your account.',
            onRetry: _reload,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _DetailsTitle(status: reservation.normalizedStatus),
              const SizedBox(height: 12),
              _PickupCodeCard(shortCode: reservation.shortCode),
              const SizedBox(height: 12),
              if (reservation.normalizedStatus == 'pending')
                _ExpiryCard(expiresAt: reservation.expiresAt, now: _now)
              else
                _ReservationStatusCard(status: reservation.normalizedStatus),
              const SizedBox(height: 18),
              _PickupInformationCard(reservation: reservation),
              const SizedBox(height: 14),
              const _WhatNextCard(),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: reservation.canCancel && !_isCancelling
                      ? () => _confirmCancel(reservation)
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    disabledForegroundColor: AppColors.textHint,
                    side: BorderSide(
                      color: reservation.canCancel
                          ? AppColors.error
                          : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Cancel Reservation',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _reload() {
    setState(() {
      _reservationFuture = _repository.findReservationById(widget.id);
    });
  }

  Future<void> _confirmCancel(ReservationModel reservation) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel reservation?'),
        content: Text('Order ${reservation.shortCode} will be cancelled.'),
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
      ),
    );

    if (shouldCancel != true) return;

    setState(() => _isCancelling = true);
    try {
      await _repository.cancelReservation(reservation.id);
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }
}

class _DetailsTitle extends StatelessWidget {
  final String status;

  const _DetailsTitle({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.pop(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            _titleForStatus(status),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _titleForStatus(String status) {
    switch (status) {
      case 'confirmed':
        return 'Reservation Confirmed';
      case 'pending':
        return 'Reservation Pending';
      case 'cancelled':
        return 'Reservation Cancelled';
      case 'expired':
        return 'Reservation Expired';
      default:
        return 'Reservation Details';
    }
  }
}

class _ReservationStatusCard extends StatelessWidget {
  final String status;

  const _ReservationStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusLabel = _labelForStatus(status);
    final statusColor = _colorForStatus(status);
    final statusIcon = _iconForStatus(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(statusIcon, size: 22, color: statusColor),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  String _labelForStatus(String status) {
    switch (status) {
      case 'confirmed':
        return 'Reservation confirmed';
      case 'cancelled':
        return 'Reservation cancelled';
      case 'expired':
        return 'Reservation expired';
      default:
        return 'Reservation status: ${status.toUpperCase()}';
    }
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _iconForStatus(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'expired':
        return Icons.event_busy_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.4,
    this.gap = 5.0,
    this.dashLength = 5.0,
    this.borderRadius = 24.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    for (final pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final length = dashLength;
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + length),
          paint,
        );
        distance += length + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PickupCodeCard extends StatelessWidget {
  final String shortCode;

  const _PickupCodeCard({required this.shortCode});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: const Color(0xFF9A7BFF).withOpacity(0.4),
        borderRadius: 24,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6FF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'YOUR PICK-UP CODE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5E4BFF),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              shortCode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1E2022),
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Show this code to the pharmacist at the counter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryCard extends StatelessWidget {
  final DateTime? expiresAt;
  final DateTime now;

  const _ExpiryCard({
    required this.expiresAt,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = expiresAt?.difference(now) ?? Duration.zero;
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;
    final label = safeRemaining == Duration.zero ? 'EXPIRED' : _formatDuration(safeRemaining);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD1D1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, size: 16, color: Color(0xFFE53E3E)),
              SizedBox(width: 6),
              Text(
                'EXPIRES IN',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE53E3E),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              color: Color(0xFFE53E3E),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            expiresAt == null
                ? 'Pick up before your reservation expires to guarantee inventory.'
                : 'Pick up before ${_formatClock(expiresAt!)} to guarantee inventory.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupInformationCard extends StatelessWidget {
  final ReservationModel reservation;

  const _PickupInformationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Pickup Information',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _InfoRow(
                  icon: Icons.storefront_outlined,
                  label: 'PHARMACY',
                  title: reservation.pharmacyName,
                  subtitle: 'Pickup location',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.medication_outlined,
                  label: 'PRESCRIPTION',
                  title: reservation.displayDrug,
                  subtitle:
                      '${reservation.quantity} item${reservation.quantity == 1 ? '' : 's'} reserved',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment due at pharmacy',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            '\$${reservation.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (reservation.hasDiscount)
                            Text(
                              '\$${reservation.originalTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textHint,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (reservation.hasDiscount) ...[
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text(
                        'SAVE ${reservation.roundedDiscount}%',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final String? subtitle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WhatNextCard extends StatelessWidget {
  const _WhatNextCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF5E4BFF)),
              SizedBox(width: 8),
              Text(
                'What next?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _Bullet('Head to the pharmacy within the next 24 hours.'),
          _Bullet('Provide the Short Code to the pharmacist.'),
          _Bullet('Complete your payment and collect your medication.'),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    final List<TextSpan> spans = [];
    if (text.contains('Short Code')) {
      final parts = text.split('Short Code');
      spans.add(TextSpan(text: parts[0]));
      spans.add(const TextSpan(
        text: 'Short Code',
        style: TextStyle(color: Color(0xFF5E4BFF), fontWeight: FontWeight.bold),
      ));
      spans.add(TextSpan(text: parts[1]));
    } else {
      spans.add(TextSpan(text: text));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8, left: 4),
            width: 4.5,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.black.withOpacity(0.6),
                  fontSize: 13,
                  height: 1.3,
                ),
                children: spans,
              ),
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
  final VoidCallback onRetry;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String _formatClock(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}