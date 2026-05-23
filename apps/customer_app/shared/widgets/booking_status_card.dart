import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/booking.dart';

class BookingStatusCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;

  const BookingStatusCard({super.key, required this.booking, this.onTap});

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
    final fmt = DateFormat('EEE, MMM d • h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_car, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.car.displayName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(booking.status), size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          booking.status.label,
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _infoRow(Icons.cleaning_services,
                  booking.serviceType == ServiceType.fullService
                      ? 'Full Interior + Exterior'
                      : 'Exterior Only'),
              const SizedBox(height: 4),
              _infoRow(Icons.location_on, booking.location.address),
              const SizedBox(height: 4),
              _infoRow(Icons.calendar_today, fmt.format(booking.scheduledAt)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}
