import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/booking.dart';

class BookingStatusCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const BookingStatusCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onCancel,
  });

  Color _statusColor(BookingStatus s) => switch (s) {
        BookingStatus.pending => AppColors.statusPending,
        BookingStatus.confirmed => AppColors.statusConfirmed,
        BookingStatus.inProgress => AppColors.statusInProgress,
        BookingStatus.completed => AppColors.statusCompleted,
        BookingStatus.cancelled => AppColors.statusCancelled,
      };

  IconData _statusIcon(BookingStatus s) => switch (s) {
        BookingStatus.pending => Icons.hourglass_empty,
        BookingStatus.confirmed => Icons.check_circle_outline,
        BookingStatus.inProgress => Icons.local_car_wash,
        BookingStatus.completed => Icons.check_circle,
        BookingStatus.cancelled => Icons.cancel_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    final fmt = DateFormat('EEE, MMM d');
    final timeFmt = DateFormat('h:mm a');
    final l10n = context.l10n;
    final isActive = booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.confirmed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Status accent strip
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          // Service icon
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.local_car_wash,
                                color: color, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.serviceName.isNotEmpty
                                      ? booking.serviceName
                                      : l10n.serviceTypeName(booking.serviceType),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                Text(
                                  booking.car.displayName,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Status chip
                          _StatusChip(status: booking.status, color: color, l10n: l10n),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Date & time
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.calendar_today,
                            label: fmt.format(booking.scheduledAt),
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.access_time,
                            label: booking.timeSlot.isNotEmpty
                                ? booking.timeSlot
                                : timeFmt.format(booking.scheduledAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Location
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking.location.address,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Cancel button for active bookings
                      if (isActive && onCancel != null) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: onCancel,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cancel_outlined,
                                  size: 14, color: AppColors.error),
                              const SizedBox(width: 4),
                              Text(
                                l10n.yesCancel,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;
  final Color color;
  final AppLocalizations l10n;

  const _StatusChip(
      {required this.status, required this.color, required this.l10n});

  IconData get _icon => switch (status) {
        BookingStatus.pending => Icons.hourglass_empty,
        BookingStatus.confirmed => Icons.check_circle_outline,
        BookingStatus.inProgress => Icons.local_car_wash,
        BookingStatus.completed => Icons.check_circle,
        BookingStatus.cancelled => Icons.cancel_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            l10n.statusLabel(status),
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
